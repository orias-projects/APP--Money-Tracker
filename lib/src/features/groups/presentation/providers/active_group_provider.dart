import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/services/supabase_service.dart';
import '../../../transactions/presentation/providers/transactions_provider.dart';
import '../../data/group_repository.dart';
import '../../domain/group.dart';
import '../../domain/group_balance.dart';
import '../../domain/group_invitation.dart';
import '../../domain/group_member.dart';

final groupRepositoryProvider = Provider<GroupRepository>((ref) {
  return GroupRepository(ref.watch(supabaseClientProvider));
});

/// Tăng sau mỗi thay đổi về nhóm (tạo, đổi tên, mời, kick, quyết toán…).
final groupVersionProvider = StateProvider<int>((ref) => 0);

/// Khoá cũ: dùng CHUNG cho mọi tài khoản nên nhóm của người này rò sang người
/// kia khi đổi tài khoản trên cùng máy. Chỉ còn giữ tên để dọn đi.
const _kLegacyActiveGroupKey = 'active_group_id';

/// Nhóm đang chọn lưu riêng theo tài khoản.
String _activeGroupKey(String uid) => 'active_group_id:$uid';

final activeGroupProvider =
    StateNotifierProvider<ActiveGroupNotifier, AppGroup?>((ref) {
      return ActiveGroupNotifier(ref);
    });

class ActiveGroupNotifier extends StateNotifier<AppGroup?> {
  ActiveGroupNotifier(this._ref) : super(null);

  final Ref _ref;
  bool _restoring = false;

  /// Tài khoản mà [state] thuộc về.
  ///
  /// Notifier này sống suốt vòng đời app, kể cả khi đăng xuất rồi đăng nhập
  /// tài khoản khác. Nhóm của người trước mà còn sót lại thì mọi RPC đều gãy
  /// với "Bạn không thuộc nhóm này" — `_assert_group_member` chặn ở máy chủ.
  String? _ownerUid;

  /// Tăng mỗi lần [clear]. Một lần khôi phục đang `await` dở không được phép
  /// ghi đè kết quả của nó lên trạng thái đã bị xoá sau đó: đăng xuất giữa
  /// chừng `ensureActiveGroup()` từng gắn lại đúng nhóm của tài khoản cũ.
  int _generation = 0;

  String? get _currentUid =>
      _ref.read(supabaseClientProvider).auth.currentUser?.id;

  Future<void> setActiveGroup(AppGroup? group) async {
    final uid = _currentUid;
    state = group;
    _ownerUid = group == null ? null : uid;
    if (uid == null) return;
    final prefs = await SharedPreferences.getInstance();
    if (group == null) {
      await prefs.remove(_activeGroupKey(uid));
    } else {
      await prefs.setString(_activeGroupKey(uid), group.id);
    }
  }

  /// Khôi phục nhóm đang chọn từ lần mở app trước; nếu không có thì dùng nhóm
  /// cá nhân. Gọi sau khi đăng nhập xong.
  Future<void> ensureActiveGroup() async {
    final uid = _currentUid;
    if (uid == null) return;

    // Đổi tài khoản trên cùng máy: bỏ nhóm của người trước rồi chọn lại.
    if (_ownerUid != null && _ownerUid != uid) {
      state = null;
      _ownerUid = null;
    }
    if (state != null || _restoring) return;

    _restoring = true;
    final generation = _generation;
    try {
      final groups = await _ref.read(groupRepositoryProvider).getUserGroups();
      if (groups.isEmpty) return;

      final prefs = await SharedPreferences.getInstance();
      // Dọn khoá dùng chung thời trước, tránh rò nhóm giữa các tài khoản.
      await prefs.remove(_kLegacyActiveGroupKey);
      final savedId = prefs.getString(_activeGroupKey(uid));

      AppGroup? chosen;
      if (savedId != null) {
        for (final g in groups) {
          if (g.id == savedId) {
            chosen = g;
            break;
          }
        }
      }
      chosen ??= groups.firstWhere(
        (g) => g.isPersonal,
        orElse: () => groups.first,
      );
      // Trong lúc chờ mạng, người dùng có thể đã đăng xuất hoặc đổi tài khoản.
      if (!mounted || generation != _generation || _currentUid != uid) return;
      state = chosen;
      _ownerUid = uid;
    } catch (_) {
      // Không chặn app khởi động vì lỗi mạng; màn hình sẽ tự thử lại.
    } finally {
      _restoring = false;
    }
  }

  /// Xoá nhóm đang chọn khi đăng xuất. Gọi TRƯỚC `signOut()` để còn biết khoá
  /// của tài khoản nào cần dọn.
  Future<void> clear() async {
    _generation++;
    final uid = _currentUid;
    state = null;
    _ownerUid = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kLegacyActiveGroupKey);
    if (uid != null) await prefs.remove(_activeGroupKey(uid));
  }
}

final userGroupsListProvider = FutureProvider<List<AppGroup>>((ref) async {
  ref.watch(groupVersionProvider);
  return ref.read(groupRepositoryProvider).getUserGroups();
});

final groupMembersProvider = FutureProvider.family<List<GroupMember>, String>((
  ref,
  groupId,
) async {
  ref.watch(groupVersionProvider);
  if (groupId.isEmpty) return const [];
  return ref.read(groupRepositoryProvider).getGroupMembers(groupId);
});

final myInvitationsProvider = FutureProvider<List<GroupInvitation>>((
  ref,
) async {
  ref.watch(groupVersionProvider);
  return ref.read(groupRepositoryProvider).getMyInvitations();
});

/// Công nợ ròng của từng thành viên trong nhóm.
final groupBalancesProvider = FutureProvider.family<List<GroupBalance>, String>(
  (ref, groupId) async {
    ref.watch(groupVersionProvider);
    ref.watch(settlementVersionProvider);
    // Công nợ phụ thuộc vào phần chia của từng giao dịch.
    ref.watch(transactionVersionProvider);
    if (groupId.isEmpty) return const [];
    return ref.read(groupRepositoryProvider).getGroupBalances(groupId);
  },
);

final settlementsProvider = FutureProvider.family<List<Settlement>, String>((
  ref,
  groupId,
) async {
  ref.watch(settlementVersionProvider);
  if (groupId.isEmpty) return const [];
  return ref.read(groupRepositoryProvider).getSettlements(groupId);
});

/// Tăng sau mỗi lần ghi nhận quyết toán.
final settlementVersionProvider = StateProvider<int>((ref) => 0);
