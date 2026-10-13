import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/result.dart';
import '../../../core/services/supabase_service.dart';
import '../domain/recurring_transaction.dart';

class RecurringRepository {
  /// [client] cho phép tiêm một [SupabaseClient] giả khi unit-test; bỏ trống thì
  /// dùng client thật như cũ nên hành vi runtime không đổi.
  RecurringRepository([SupabaseClient? client])
    : _client = client ?? SupabaseService.client;

  final SupabaseClient _client;

  String? get _userId => _client.auth.currentUser?.id;

  Future<List<RecurringTransaction>> getAll() async {
    final uid = _userId;
    if (uid == null) return const [];
    try {
      final res = await _client
          .from('recurring_transactions')
          .select()
          .eq('user_id', uid)
          .or('status.is.null,status.eq.active')
          .order('next_date');
      return (res as List)
          .map((e) => RecurringTransaction.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      throw mapError(e, st);
    }
  }

  Future<Result<void>> add({
    required String accountId,
    required String? categoryId,
    required String type,
    required double amount,
    required RecurringFrequency frequency,
    required DateTime nextDate,
    String? note,
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
          'Số tiền phải lớn hơn 0.',
          kind: AppErrorKind.validation,
          code: AppErrorCode.amountInvalid,
        );
      }
      await _client.from('recurring_transactions').insert({
        'user_id': uid,
        'account_id': accountId,
        'category_id': categoryId,
        'type': type,
        'amount': amount,
        'frequency': frequency.name,
        'next_date': _dateOnly(nextDate),
        'note': note,
        'is_active': true,
      });
    });
  }

  Future<Result<void>> setActive(String id, bool active) {
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
          .from('recurring_transactions')
          .update({'is_active': active})
          .eq('id', id)
          .eq('user_id', uid);
    });
  }

  Future<Result<void>> delete(String id) {
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
          .from('recurring_transactions')
          .update({'status': 'deleted', 'is_active': false})
          .eq('id', id)
          .eq('user_id', uid);
    });
  }

  /// Sinh các giao dịch định kỳ đã tới hạn. Trả về số giao dịch vừa tạo.
  ///
  /// Chạy khi mở app để không phụ thuộc vào việc bật `pg_cron`; nếu đã đặt
  /// lịch pg_cron thì hàm này chỉ đơn giản trả về 0.
  Future<Result<int>> runDue(String groupId) {
    return Result.guard(() async {
      if (groupId.isEmpty) return 0;
      final res = await _client.rpc(
        'run_due_recurring',
        params: {'p_group_id': groupId},
      );
      return (res is num) ? res.toInt() : 0;
    });
  }

  static String _dateOnly(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
