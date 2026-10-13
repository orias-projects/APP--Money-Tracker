import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/result.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../auth/domain/social_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../groups/presentation/providers/friend_suggestions_provider.dart';
import '../../data/social_friends_service.dart';

final socialFriendsServiceProvider = Provider<SocialFriendsService>(
  (ref) => SocialFriendsService(ref.watch(supabaseClientProvider)),
);

class SocialSyncState {
  const SocialSyncState({
    this.syncing = false,
    this.lastSyncedCount,
    this.error,
    this.pending,
  });

  final bool syncing;

  /// Số bạn Facebook lưu được ở lần đồng bộ gần nhất trong phiên này.
  final int? lastSyncedCount;
  final AppException? error;

  /// Provider mà người dùng vừa bấm — chỉ đồng bộ khi token về đúng provider
  /// đó (tránh gửi token Google lên Graph API).
  final SocialProvider? pending;

  SocialSyncState copyWith({
    bool? syncing,
    int? lastSyncedCount,
    AppException? error,
    SocialProvider? pending,
    bool clearError = false,
    bool clearPending = false,
  }) {
    return SocialSyncState(
      syncing: syncing ?? this.syncing,
      lastSyncedCount: lastSyncedCount ?? this.lastSyncedCount,
      error: clearError ? null : (error ?? this.error),
      pending: clearPending ? null : (pending ?? this.pending),
    );
  }
}

/// Điều phối đồng bộ bạn bè Facebook.
///
/// Luồng OAuth qua trình duyệt kết thúc bất đồng bộ (deep link) nên không có
/// chỗ nào "await" được token: màn Đăng nhập / Tài khoản gọi [expect] khi bấm
/// nút Facebook, controller nghe `onAuthStateChange`, gặp phiên có
/// `providerToken` thì đồng bộ ngay — GoTrue không giữ token này qua refresh.
class SocialSyncController extends Notifier<SocialSyncState> {
  StreamSubscription<AuthState>? _sub;

  @override
  SocialSyncState build() {
    final auth = ref.watch(authRepositoryProvider);
    _sub?.cancel();
    _sub = auth.onAuthStateChange.listen(_onAuthEvent);
    ref.onDispose(() => _sub?.cancel());
    return const SocialSyncState();
  }

  /// Gọi ngay trước khi mở luồng đăng nhập/liên kết của [provider].
  void expect(SocialProvider provider) {
    state = state.copyWith(pending: provider, clearError: true);
  }

  void _onAuthEvent(AuthState event) {
    if (state.pending != SocialProvider.facebook) return;
    final token = event.session?.providerToken;
    if (token == null || token.isEmpty) return;
    switch (event.event) {
      case AuthChangeEvent.signedIn:
      case AuthChangeEvent.userUpdated:
      case AuthChangeEvent.initialSession:
        state = state.copyWith(clearPending: true);
        unawaited(syncFacebook(token));
      default:
        break;
    }
  }

  /// Đồng bộ thủ công (nút trong màn Bạn bè). Không có token trong phiên hiện
  /// tại → lỗi `providerTokenMissing`, UI đề nghị kết nối lại Facebook.
  Future<void> syncFacebook([String? token]) async {
    final t =
        token ?? ref.read(authRepositoryProvider).currentSession?.providerToken;
    if (t == null || t.isEmpty) {
      state = state.copyWith(
        error: const AppException(
          'Kết nối lại Facebook để đồng bộ bạn bè.',
          kind: AppErrorKind.auth,
          code: AppErrorCode.providerTokenMissing,
        ),
      );
      return;
    }
    state = state.copyWith(syncing: true, clearError: true);
    final res = await ref
        .read(socialFriendsServiceProvider)
        .syncFacebookFriends(t);
    state = switch (res) {
      Ok(:final value) => state.copyWith(
        syncing: false,
        lastSyncedCount: value,
      ),
      Err(:final error) => state.copyWith(syncing: false, error: error),
    };
    ref.invalidate(friendSuggestionsProvider);
  }

  void clearError() => state = state.copyWith(clearError: true);
}

final socialSyncProvider =
    NotifierProvider<SocialSyncController, SocialSyncState>(
      SocialSyncController.new,
    );
