import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/supabase_service.dart';
import '../../../shared/presentation/providers/filter_provider.dart';
import '../../../transactions/presentation/providers/transactions_provider.dart';
import '../../data/analytics_repository.dart';

final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  return AnalyticsRepository(ref.watch(supabaseClientProvider));
});

class ChartsParams {
  const ChartsParams({
    required this.groupId,
    required this.from,
    required this.to,
    this.accountIds = const [],
  });

  final String groupId;
  final DateTime from;
  final DateTime to;
  final List<String> accountIds;

  /// Cùng bộ lọc + nhóm luôn ra cùng params (ngày đã chuẩn hoá về đầu/cuối ngày),
  /// để `family` không sinh instance mới mỗi lần build.
  static ChartsParams fromFilter(FilterState filterState, String groupId) {
    final from = filterState.startDate ?? DateTime(2000, 1, 1);
    final to = filterState.endDate ?? DateTime.now();
    return ChartsParams(
      groupId: groupId,
      from: DateTime(from.year, from.month, from.day),
      to: DateTime(to.year, to.month, to.day, 23, 59, 59, 999),
      accountIds: filterState.selectedAccountIds,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChartsParams &&
          groupId == other.groupId &&
          from == other.from &&
          to == other.to &&
          _sameIds(accountIds, other.accountIds);

  @override
  int get hashCode =>
      Object.hash(groupId, from, to, Object.hashAll(accountIds));

  static bool _sameIds(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// MỘT lượt gọi mạng cho toàn bộ màn Biểu đồ.
///
/// Trước đây có bốn provider, mỗi cái tự tải lại toàn bộ giao dịch trong kỳ.
final analyticsProvider = FutureProvider.autoDispose
    .family<AnalyticsSnapshot, ChartsParams>((ref, params) async {
      ref.watch(transactionVersionProvider);
      if (params.groupId.isEmpty) return AnalyticsSnapshot.empty;

      // Giữ kết quả một lúc sau khi rời màn, tránh tải lại khi chuyển tab qua
      // lại. Timer bị huỷ khi có người nghe trở lại (onResume) — thiếu bước đó,
      // quay lại màn trong vòng 2 phút vẫn bị thả cache.
      final link = ref.keepAlive();
      Timer? closeTimer;
      ref.onCancel(() {
        closeTimer = Timer(const Duration(minutes: 2), link.close);
      });
      ref.onResume(() => closeTimer?.cancel());
      ref.onDispose(() => closeTimer?.cancel());

      return ref
          .read(analyticsRepositoryProvider)
          .getAnalytics(
            groupId: params.groupId,
            from: params.from,
            to: params.to,
            accountIds: params.accountIds,
          );
    });
