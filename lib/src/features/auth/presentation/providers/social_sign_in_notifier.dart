import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/result.dart';
import '../../../profile/presentation/providers/social_sync_controller.dart';
import '../../data/auth_repository.dart';
import '../../domain/social_provider.dart';
import 'auth_provider.dart';

class SocialSignInState {
  const SocialSignInState({this.busy, this.browserWaiting = false, this.error});

  /// Provider đang xử lý (nút hiện vòng xoay).
  final SocialProvider? busy;

  /// Đã mở trình duyệt, đang chờ deep link mang phiên về.
  final bool browserWaiting;

  final AppException? error;
}

/// Luồng bấm nút mạng xã hội — dùng chung cho Đăng nhập và Đăng ký.
///
/// Google native trả phiên ngay. Facebook/X (và Google khi rơi về trình
/// duyệt) kết thúc bất đồng bộ: GoTrue phát `signedIn` khi deep link về, router
/// tự chuyển màn nhờ `refreshListenable`; ở đây chỉ cần làm mới hồ sơ và hạ
/// trạng thái chờ.
class SocialSignInNotifier extends AutoDisposeNotifier<SocialSignInState> {
  StreamSubscription<AuthState>? _sub;

  @override
  SocialSignInState build() {
    final auth = ref.watch(authRepositoryProvider);
    _sub?.cancel();
    _sub = auth.onAuthStateChange.listen(_onAuthEvent);
    ref.onDispose(() => _sub?.cancel());
    return const SocialSignInState();
  }

  Future<void> start(SocialProvider provider) async {
    if (state.busy != null) return;
    state = SocialSignInState(busy: provider);
    // Báo controller đồng bộ bạn bè biết token sắp về là của provider nào.
    ref.read(socialSyncProvider.notifier).expect(provider);

    final result = await ref
        .read(authRepositoryProvider)
        .signInWithSocial(provider);

    switch (result) {
      case Ok(:final value) when value == SocialSignInOutcome.signedIn:
        ref.invalidate(currentUserProvider);
        state = const SocialSignInState();
      case Ok():
        state = SocialSignInState(busy: provider, browserWaiting: true);
      case Err(:final error):
        // Người dùng tự đóng sheet/trình duyệt thì không phải lỗi.
        state = SocialSignInState(
          error: error.code == AppErrorCode.oauthCancelled ? null : error,
        );
    }
  }

  void _onAuthEvent(AuthState event) {
    if (event.event == AuthChangeEvent.signedIn && event.session != null) {
      ref.invalidate(currentUserProvider);
      state = const SocialSignInState();
    }
  }

  /// Người dùng quay lại mà không hoàn tất trong trình duyệt.
  void cancelWaiting() => state = const SocialSignInState();

  void clearError() => state = const SocialSignInState();
}

final socialSignInProvider =
    NotifierProvider.autoDispose<SocialSignInNotifier, SocialSignInState>(
      SocialSignInNotifier.new,
    );
