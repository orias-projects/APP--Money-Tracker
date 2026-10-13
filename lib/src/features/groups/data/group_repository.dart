import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/result.dart';
import '../../auth/domain/app_user.dart';
import '../domain/friend_suggestion.dart';
import '../domain/group.dart';
import '../domain/group_balance.dart';
import '../domain/group_invitation.dart';
import '../domain/group_member.dart';

class GroupRepository {
  GroupRepository(this._client);

  final SupabaseClient _client;

  String? get _userId => _client.auth.currentUser?.id;

  // ---------------------------------------------------------------------------
  // ĐỌC
  // ---------------------------------------------------------------------------

  Future<List<AppGroup>> getUserGroups() async {
    if (_userId == null) return const [];
    try {
      final res = await _client.rpc('get_user_groups');
      return _asMapList(res).map(AppGroup.fromMap).toList();
    } catch (e, st) {
      throw mapError(e, st);
    }
  }

  Future<AppGroup?> getPersonalGroup() async {
    final list = await getUserGroups();
    for (final g in list) {
      if (g.isPersonal) return g;
    }
    return null;
  }

  Future<List<GroupMember>> getGroupMembers(String groupId) async {
    if (groupId.isEmpty) return const [];
    try {
      final res = await _client.rpc(
        'get_group_members',
        params: {'p_group_id': groupId},
      );
      return _asMapList(res).map(GroupMember.fromMap).toList();
    } catch (e, st) {
      throw mapError(e, st);
    }
  }

  Future<List<GroupInvitation>> getMyInvitations() async {
    if (_userId == null) return const [];
    try {
      final res = await _client.rpc('get_my_invitations');
      return _asMapList(res).map(GroupInvitation.fromMap).toList();
    } catch (e, st) {
      throw mapError(e, st);
    }
  }

  /// Công nợ ròng của từng thành viên trong nhóm.
  Future<List<GroupBalance>> getGroupBalances(String groupId) async {
    if (groupId.isEmpty) return const [];
    try {
      final res = await _client.rpc(
        'get_group_balances',
        params: {'p_group_id': groupId},
      );
      return _asMapList(res).map(GroupBalance.fromMap).toList();
    } catch (e, st) {
      throw mapError(e, st);
    }
  }

  Future<List<Settlement>> getSettlements(String groupId) async {
    if (groupId.isEmpty) return const [];
    try {
      final res = await _client.rpc(
        'get_group_settlements',
        params: {'p_group_id': groupId},
      );
      return _asMapList(res).map(Settlement.fromMap).toList();
    } catch (e, st) {
      throw mapError(e, st);
    }
  }

  Future<List<AppUser>> searchUsers(String query) async {
    if (_userId == null) {
      throw const AppException(
        'Chưa đăng nhập.',
        kind: AppErrorKind.auth,
        code: AppErrorCode.notLoggedIn,
      );
    }
    if (query.trim().length < 3) return const [];
    try {
      final res = await _client.rpc(
        'search_users',
        params: {'p_query': query.trim()},
      );
      return _asMapList(
        res,
      ).where((m) => m['id'] != null).map(AppUser.fromMap).toList();
    } catch (e, st) {
      throw mapError(e, st);
    }
  }

  // ---------------------------------------------------------------------------
  // GHI
  // ---------------------------------------------------------------------------

  /// Người nên mời vào nhóm: bạn Facebook cũng dùng app + người cùng nhóm
  /// chung (RPC get_friend_suggestions, migration 008).
  Future<List<FriendSuggestion>> getFriendSuggestions() async {
    if (_userId == null) return const [];
    try {
      final res = await _client.rpc('get_friend_suggestions');
      return _asMapList(
        res,
      ).where((m) => m['id'] != null).map(FriendSuggestion.fromMap).toList();
    } catch (e, st) {
      throw mapError(e, st);
    }
  }

  Future<Result<AppGroup>> createGroup(String name) {
    return Result.guard(() async {
      if (name.trim().isEmpty) {
        throw const AppException(
          'Tên nhóm không được để trống.',
          kind: AppErrorKind.validation,
          code: AppErrorCode.groupNameEmpty,
        );
      }
      final res = await _client.rpc(
        'create_group',
        params: {'p_name': name.trim()},
      );
      final list = _asMapList(res);
      if (list.isEmpty) {
        throw const AppException(
          'Không tạo được nhóm.',
          code: AppErrorCode.groupCreateFailed,
        );
      }
      return AppGroup.fromMap(list.first);
    });
  }

  Future<Result<AppGroup>> renameGroup(String groupId, String name) {
    return Result.guard(() async {
      if (name.trim().isEmpty) {
        throw const AppException(
          'Tên nhóm không được để trống.',
          kind: AppErrorKind.validation,
          code: AppErrorCode.groupNameEmpty,
        );
      }
      final res = await _client
          .from('groups')
          .update({'name': name.trim()})
          .eq('id', groupId)
          .select()
          .single();
      return AppGroup.fromMap(res);
    });
  }

  /// Xoá mềm nhóm. RPC trả thông điệp lỗi thật thay vì im lặng thành công.
  Future<Result<void>> deleteGroup(String groupId) =>
      _rpcVoid('delete_group', {'p_group_id': groupId});

  /// Tham gia nhóm bằng mã mời 8 ký tự.
  Future<Result<void>> joinGroupByCode(String code) =>
      _rpcVoid('join_group_by_code', {'p_code': code.trim().toUpperCase()});

  /// Đổi mã mời (chỉ quản trị viên). Trả về mã mới.
  Future<Result<String>> rotateInviteCode(String groupId) {
    return Result.guard(() async {
      final res = await _client.rpc(
        'rotate_invite_code',
        params: {'p_group_id': groupId},
      );
      return res?.toString() ?? '';
    });
  }

  Future<Result<void>> inviteUser(String groupId, String userId) =>
      _rpcVoid('invite_to_group', {'p_group_id': groupId, 'p_user_id': userId});

  Future<Result<void>> acceptInvitation(String invitationId) =>
      _rpcVoid('accept_invitation', {'p_invitation_id': invitationId});

  Future<Result<void>> declineInvitation(String invitationId) =>
      _rpcVoid('decline_invitation', {'p_invitation_id': invitationId});

  Future<Result<void>> leaveGroup(String groupId) =>
      _rpcVoid('leave_group', {'p_group_id': groupId});

  Future<Result<void>> kickMember(String groupId, String userId) =>
      _rpcVoid('kick_member', {'p_group_id': groupId, 'p_user_id': userId});

  Future<Result<void>> transferAdmin(String groupId, String userId) =>
      _rpcVoid('transfer_admin', {'p_group_id': groupId, 'p_user_id': userId});

  /// Ghi nhận đã trả tiền cho một thành viên khác.
  Future<Result<void>> settleUp({
    required String groupId,
    required String toUserId,
    required double amount,
    String? note,
  }) => _rpcVoid('settle_up', {
    'p_group_id': groupId,
    'p_to_user': toUserId,
    'p_amount': amount,
    'p_note': note,
  });

  // ---------------------------------------------------------------------------
  // Tiện ích
  // ---------------------------------------------------------------------------

  /// Các RPC nhóm trả về chuỗi rỗng khi thành công, thông điệp tiếng Việt khi lỗi.
  Future<Result<void>> _rpcVoid(String fn, Map<String, dynamic> params) {
    return Result.guard(() async {
      if (_userId == null) {
        throw const AppException(
          'Chưa đăng nhập.',
          kind: AppErrorKind.auth,
          code: AppErrorCode.notLoggedIn,
        );
      }
      final res = await _client.rpc(fn, params: params);
      final msg = res?.toString().trim() ?? '';
      if (msg.isNotEmpty) {
        throw AppException(msg, kind: AppErrorKind.validation);
      }
    });
  }

  /// Postgrest trả json_agg khi 1 phần tử đôi khi ra Map thay vì List.
  static List<Map<String, dynamic>> _asMapList(dynamic res) {
    if (res == null) return const [];
    if (res is List) {
      return res
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    if (res is Map) return [Map<String, dynamic>.from(res)];
    return const [];
  }
}
