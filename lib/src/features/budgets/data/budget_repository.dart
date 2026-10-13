import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/result.dart';
import '../../../core/services/supabase_service.dart';
import '../domain/budget.dart';

class BudgetRepository {
  /// [client] cho phép tiêm một [SupabaseClient] giả khi unit-test; bỏ trống thì
  /// dùng client thật như cũ nên hành vi runtime không đổi.
  BudgetRepository([SupabaseClient? client])
    : _client = client ?? SupabaseService.client;

  final SupabaseClient _client;

  String? get _userId => _client.auth.currentUser?.id;

  /// Ngân sách kèm số đã tiêu — tính ở server bằng RPC get_budget_progress.
  Future<List<Budget>> getBudgets(String groupId) async {
    if (groupId.isEmpty) return const [];
    try {
      final res = await _client.rpc(
        'get_budget_progress',
        params: {'p_group_id': groupId},
      );
      if (res == null) return const [];
      return (res as List)
          .map((e) => Budget.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e, st) {
      throw mapError(e, st);
    }
  }

  Future<Result<void>> addBudget({
    required String categoryId,
    required double amount,
    required BudgetPeriod period,
    required DateTime startDate,
    required DateTime endDate,
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
      if (amount <= 0) {
        throw const AppException(
          'Hạn mức phải lớn hơn 0.',
          kind: AppErrorKind.validation,
          code: AppErrorCode.budgetAmountInvalid,
        );
      }
      await _client.from('budgets').insert({
        'user_id': uid,
        'category_id': categoryId,
        'amount': amount,
        'period': period.name,
        'start_date': _dateOnly(startDate),
        'end_date': _dateOnly(endDate),
      });
    });
  }

  Future<Result<void>> updateBudget(
    String budgetId, {
    double? amount,
    DateTime? startDate,
    DateTime? endDate,
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
      final map = <String, dynamic>{};
      if (amount != null) map['amount'] = amount;
      if (startDate != null) map['start_date'] = _dateOnly(startDate);
      if (endDate != null) map['end_date'] = _dateOnly(endDate);
      if (map.isEmpty) {
        throw const AppException(
          'Không có thay đổi nào để lưu.',
          code: AppErrorCode.nothingToSave,
        );
      }
      await _client
          .from('budgets')
          .update(map)
          .eq('id', budgetId)
          .eq('user_id', uid);
    });
  }

  Future<Result<void>> deleteBudget(String budgetId) {
    return Result.guard(() async {
      final uid = _userId;
      if (uid == null) {
        throw const AppException(
          'Chưa đăng nhập.',
          kind: AppErrorKind.auth,
          code: AppErrorCode.notLoggedIn,
        );
      }
      await _client
          .from('budgets')
          .update({'status': 'deleted'})
          .eq('id', budgetId)
          .eq('user_id', uid);
    });
  }

  static String _dateOnly(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
