import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/result.dart';
import '../domain/account.dart';

class AccountRepository {
  AccountRepository(this._client);

  final SupabaseClient _client;

  String? get _userId => _client.auth.currentUser?.id;

  // ---------------------------------------------------------------------------
  // ĐỌC
  // ---------------------------------------------------------------------------

  /// Ví cá nhân của user hiện tại.
  Future<List<Account>> getAccounts({bool includeArchived = false}) async {
    final uid = _userId;
    if (uid == null) return const [];
    try {
      var query = _client.from('accounts').select().eq('user_id', uid);
      if (!includeArchived) {
        query = query.or('status.is.null,status.eq.active');
      }
      final res = await query.order('created_at', ascending: true);
      return (res as List)
          .map((e) => Account.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      throw mapError(e, st);
    }
  }

  /// Ví dùng được trong một nhóm: ví chung của nhóm + ví cá nhân của tôi.
  Future<List<Account>> getAccountsForGroup(String groupId) async {
    if (groupId.isEmpty) return getAccounts();
    try {
      final res = await _client.rpc(
        'get_group_accounts',
        params: {'p_group_id': groupId},
      );
      if (res == null) return const [];
      return (res as List)
          .map((e) => Account.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e, st) {
      throw mapError(e, st);
    }
  }

  /// Tên ví của MỌI giao dịch trong nhóm — kể cả ví cá nhân của thành viên khác.
  /// Không trả về số dư của ví người khác.
  Future<List<AccountLabel>> getAccountLabels(String groupId) async {
    if (groupId.isEmpty) return const [];
    try {
      final res = await _client.rpc(
        'get_group_account_labels',
        params: {'p_group_id': groupId},
      );
      if (res == null) return const [];
      return (res as List)
          .map((e) => AccountLabel.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e, st) {
      throw mapError(e, st);
    }
  }

  // ---------------------------------------------------------------------------
  // GHI
  // ---------------------------------------------------------------------------

  Future<Result<Account>> addAccount({
    required String name,
    required String accountType,
    double openingBalance = 0,
    String currency = 'VND',
    String? groupId,
    double creditLimit = 0,
    int? statementDate,
    int? paymentDate,
    bool includeInTotal = true,
  }) {
    return Result.guard(() async {
      final uid = _userId;
      if (uid == null) {
        throw const AppException(
          'Chưa đăng nhập.',
          kind: AppErrorKind.auth,
          code: AppErrorCode.notLoggedIn,
        );
      }
      final res = await _client
          .from('accounts')
          .insert({
            'user_id': uid,
            'group_id': groupId,
            'name': name.trim(),
            'account_type': accountType,
            // balance và opening_balance khởi tạo bằng nhau: chưa có giao dịch nào.
            'balance': openingBalance,
            'opening_balance': openingBalance,
            'credit_limit': creditLimit,
            'statement_date': statementDate,
            'payment_date': paymentDate,
            'include_in_total': includeInTotal,
            'currency': currency,
          })
          .select()
          .single();
      return Account.fromMap(res);
    });
  }

  Future<Result<Account>> updateAccount(
    String accountId, {
    String? name,
    String? accountType,
    String? currency,
    double? creditLimit,
    int? statementDate,
    int? paymentDate,
    bool? includeInTotal,
  }) {
    return Result.guard(() async {
      final map = <String, dynamic>{};
      if (name != null) map['name'] = name.trim();
      if (accountType != null) map['account_type'] = accountType;
      if (currency != null) map['currency'] = currency;
      if (creditLimit != null) map['credit_limit'] = creditLimit;
      if (statementDate != null) map['statement_date'] = statementDate;
      if (paymentDate != null) map['payment_date'] = paymentDate;
      if (includeInTotal != null) map['include_in_total'] = includeInTotal;
      if (map.isEmpty) {
        throw const AppException(
          'Không có thay đổi nào để lưu.',
          code: AppErrorCode.nothingToSave,
        );
      }
      map['updated_at'] = DateTime.now().toUtc().toIso8601String();

      final res = await _client
          .from('accounts')
          .update(map)
          .eq('id', accountId)
          .select()
          .single();
      return Account.fromMap(res);
    });
  }

  /// Lưu trữ ví (xoá mềm). Giao dịch cũ vẫn giữ nguyên để sổ cái không thủng.
  Future<Result<void>> archiveAccount(String accountId) {
    return Result.guard(() async {
      await _client
          .from('accounts')
          .update({'status': 'deleted'})
          .eq('id', accountId);
    });
  }

  Future<Result<void>> restoreAccount(String accountId) {
    return Result.guard(() async {
      await _client
          .from('accounts')
          .update({'status': 'active'})
          .eq('id', accountId);
    });
  }

  /// Đối soát lại số dư một ví từ sổ giao dịch.
  Future<Result<double>> recalcAccount(String accountId) {
    return Result.guard(() async {
      final res = await _client.rpc(
        'recalc_account_balance',
        params: {'p_account_id': accountId},
      );
      return (res is num) ? res.toDouble() : 0.0;
    });
  }

  /// Đối soát toàn bộ ví. Trả về danh sách ví đã bị lệch và được sửa.
  Future<Result<List<BalanceDrift>>> recalcAllBalances() {
    return Result.guard(() async {
      final res = await _client.rpc('recalc_my_balances');
      if (res == null) return <BalanceDrift>[];
      return (res as List)
          .map((e) => BalanceDrift.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
    });
  }
}
