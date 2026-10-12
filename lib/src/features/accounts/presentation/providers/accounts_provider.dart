import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/supabase_service.dart';
import '../../../groups/presentation/providers/active_group_provider.dart';
import '../../../transactions/presentation/providers/transactions_provider.dart';
import '../../data/account_repository.dart';
import '../../domain/account.dart';

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  return AccountRepository(ref.watch(supabaseClientProvider));
});

/// Tăng sau mỗi thao tác ghi lên ví.
final accountVersionProvider = StateProvider<int>((ref) => 0);

/// Ví cá nhân của user hiện tại (dùng cho màn Báo cáo / Tài sản ròng).
final accountsListProvider = FutureProvider<List<Account>>((ref) async {
  ref.watch(accountVersionProvider);
  return ref.read(accountRepositoryProvider).getAccounts();
});

/// Kể cả ví đã lưu trữ — dùng trong màn Quản lý ví.
final allAccountsProvider = FutureProvider<List<Account>>((ref) async {
  ref.watch(accountVersionProvider);
  return ref.read(accountRepositoryProvider).getAccounts(includeArchived: true);
});

/// Ví CHỌN ĐƯỢC khi ghi giao dịch trong nhóm đang hoạt động:
/// ví chung của nhóm + ví cá nhân của tôi.
final selectableAccountsProvider = FutureProvider<List<Account>>((ref) async {
  ref.watch(accountVersionProvider);
  final group = ref.watch(activeGroupProvider);
  final repo = ref.read(accountRepositoryProvider);
  if (group == null || group.isPersonal) {
    return repo.getAccounts();
  }
  return repo.getAccountsForGroup(group.id);
});

/// Tra cứu nhanh ví theo id khi render danh sách giao dịch — memo hoá một lần
/// mỗi lần danh sách ví đổi, thay vì dựng Map mới trong từng build.
final accountMapProvider = Provider<Map<String, Account>>((ref) {
  final list = ref.watch(accountsListProvider).valueOrNull ?? const <Account>[];
  return {for (final a in list) a.id: a};
});

/// Tên ví của MỌI giao dịch trong nhóm — kể cả ví cá nhân của thành viên khác.
/// Sửa lỗi tên ví bị trống khi xem giao dịch của người khác trong nhóm chung.
final accountLabelsProvider =
    FutureProvider.family<Map<String, AccountLabel>, String>((
      ref,
      groupId,
    ) async {
      ref.watch(accountVersionProvider);
      ref.watch(transactionVersionProvider);
      if (groupId.isEmpty) return const {};
      final labels = await ref
          .read(accountRepositoryProvider)
          .getAccountLabels(groupId);
      return {for (final l in labels) l.id: l};
    });
