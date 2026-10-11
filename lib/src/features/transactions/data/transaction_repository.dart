import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/result.dart';
import '../domain/transaction.dart';

/// Bộ lọc cho danh sách giao dịch. Dùng chung cho Records, Charts và Tìm kiếm.
class TransactionQuery {
  const TransactionQuery({
    required this.groupId,
    this.accountIds,
    this.categoryIds,
    this.types,
    this.from,
    this.to,
    this.search,
    this.minAmount,
    this.maxAmount,
    this.offset = 0,
    this.limit = 50,
  });

  final String groupId;
  final List<String>? accountIds;
  final List<String>? categoryIds;
  final List<String>? types;
  final DateTime? from;
  final DateTime? to;
  final String? search;
  final double? minAmount;
  final double? maxAmount;
  final int offset;
  final int limit;

  TransactionQuery copyWith({int? offset, int? limit}) => TransactionQuery(
    groupId: groupId,
    accountIds: accountIds,
    categoryIds: categoryIds,
    types: types,
    from: from,
    to: to,
    search: search,
    minAmount: minAmount,
    maxAmount: maxAmount,
    offset: offset ?? this.offset,
    limit: limit ?? this.limit,
  );

  /// Bằng nhau về ĐIỀU KIỆN LỌC, bỏ qua offset/limit — dùng làm khoá cache cho
  /// provider.family để cuộn thêm trang không tạo ra một provider mới.
  TransactionQuery get filterKey => copyWith(offset: 0, limit: 0);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionQuery &&
          groupId == other.groupId &&
          _listEq(accountIds, other.accountIds) &&
          _listEq(categoryIds, other.categoryIds) &&
          _listEq(types, other.types) &&
          from == other.from &&
          to == other.to &&
          search == other.search &&
          minAmount == other.minAmount &&
          maxAmount == other.maxAmount &&
          offset == other.offset &&
          limit == other.limit;

  @override
  int get hashCode => Object.hash(
    groupId,
    accountIds == null ? null : Object.hashAll(accountIds!),
    categoryIds == null ? null : Object.hashAll(categoryIds!),
    types == null ? null : Object.hashAll(types!),
    from,
    to,
    search,
    minAmount,
    maxAmount,
    offset,
    limit,
  );

  static bool _listEq(List<String>? a, List<String>? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return a == b;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

class TransactionRepository {
  TransactionRepository(this._client);

  final SupabaseClient _client;

  static const _selectColumns =
      '*, transaction_splits(user_id, share_amount), '
      'created_by_user:users!transactions_created_by_fkey(full_name, username, avatar_url), '
      'paid_by_user:users!transactions_paid_by_fkey(full_name, username, avatar_url)';

  // ---------------------------------------------------------------------------
  // ĐỌC — để exception bay lên, Riverpod hiển thị qua AsyncValue.error
  // ---------------------------------------------------------------------------

  /// Một trang giao dịch. Ném [AppException] nếu lỗi — KHÔNG trả list rỗng
  /// để che lỗi mạng.
  Future<List<Transaction>> getTransactions(TransactionQuery q) async {
    if (q.groupId.isEmpty) return const [];
    try {
      var query = _client
          .from('transactions')
          .select(_selectColumns)
          .eq('group_id', q.groupId)
          .or('row_status.is.null,row_status.eq.active');

      if (q.accountIds != null && q.accountIds!.isNotEmpty) {
        query = query.inFilter('account_id', q.accountIds!);
      }
      if (q.categoryIds != null && q.categoryIds!.isNotEmpty) {
        query = query.inFilter('category_id', q.categoryIds!);
      }
      if (q.types != null && q.types!.isNotEmpty) {
        query = query.inFilter('type', q.types!);
      }
      if (q.from != null) {
        query = query.gte('transaction_date', q.from!.toIso8601String());
      }
      if (q.to != null) {
        query = query.lte('transaction_date', q.to!.toIso8601String());
      }
      if (q.minAmount != null) query = query.gte('amount', q.minAmount!);
      if (q.maxAmount != null) query = query.lte('amount', q.maxAmount!);

      final search = q.search?.trim();
      if (search != null && search.isNotEmpty) {
        final escaped = search.replaceAll(',', ' ').replaceAll('%', '');
        query = query.or('note.ilike.%$escaped%,payee.ilike.%$escaped%');
      }

      final res = await query
          .order('transaction_date', ascending: false)
          .order('created_at', ascending: false)
          .range(q.offset, q.offset + q.limit - 1);

      return (res as List)
          .map((e) => Transaction.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      throw mapError(e, st);
    }
  }

  /// Tổng thu/chi trong kỳ, tính ở server (không tải danh sách về).
  Future<PeriodSummary> getPeriodSummary(TransactionQuery q) async {
    if (q.groupId.isEmpty) return PeriodSummary.empty;
    try {
      final res = await _client.rpc(
        'get_period_summary',
        params: {
          'p_group_id': q.groupId,
          'p_from': q.from?.toIso8601String(),
          'p_to': q.to?.toIso8601String(),
          'p_account_ids': (q.accountIds != null && q.accountIds!.isNotEmpty)
              ? q.accountIds
              : null,
        },
      );
      if (res is List && res.isNotEmpty) {
        return PeriodSummary.fromMap(
          Map<String, dynamic>.from(res.first as Map),
        );
      }
      if (res is Map) {
        return PeriodSummary.fromMap(Map<String, dynamic>.from(res));
      }
      return PeriodSummary.empty;
    } catch (e, st) {
      throw mapError(e, st);
    }
  }

  Future<Transaction?> getById(String transactionId) async {
    try {
      final res = await _client
          .from('transactions')
          .select(_selectColumns)
          .eq('id', transactionId)
          .maybeSingle();
      if (res == null) return null;
      return Transaction.fromMap(res);
    } catch (e, st) {
      throw mapError(e, st);
    }
  }

  // ---------------------------------------------------------------------------
  // GHI — trả Result để nơi gọi hiện SnackBar với lý do thật
  // ---------------------------------------------------------------------------

  /// Thêm giao dịch qua RPC: giao dịch + phần chia + số dư ví đổi trong CÙNG
  /// một transaction DB, không thể có trạng thái ghi dở.
  Future<Result<Transaction>> createTransaction({
    required String groupId,
    required String accountId,
    required String type,
    required double amount,
    required DateTime transactionDate,
    String? toAccountId,
    String? categoryId,
    double feeAmount = 0,
    String? note,
    String? payee,
    String? imageUrl,
    String? paidBy,
    SplitMode splitMode = SplitMode.none,
    List<TransactionSplit> splits = const [],
  }) {
    return Result.guard(() async {
      final res = await _client.rpc(
        'create_transaction',
        params: {
          'p_group_id': groupId,
          'p_account_id': accountId,
          'p_type': type,
          'p_amount': amount,
          'p_transaction_date': transactionDate.toIso8601String(),
          'p_to_account_id': toAccountId,
          'p_category_id': categoryId,
          'p_fee_amount': feeAmount,
          'p_note': note,
          'p_payee': payee,
          'p_image_url': imageUrl,
          'p_paid_by': paidBy,
          'p_split_mode': splitMode.name,
          'p_splits': splitMode.isSplit
              ? splits.map((s) => s.toJson()).toList()
              : null,
        },
      );
      return _singleTransaction(res);
    });
  }

  Future<Result<Transaction>> updateTransaction({
    required String transactionId,
    String? accountId,
    String? toAccountId,
    String? categoryId,
    double? amount,
    DateTime? transactionDate,
    double? feeAmount,
    String? note,
    String? payee,
    String? imageUrl,
    String? paidBy,
    SplitMode? splitMode,
    List<TransactionSplit>? splits,
  }) {
    return Result.guard(() async {
      final res = await _client.rpc(
        'update_transaction',
        params: {
          'p_transaction_id': transactionId,
          'p_account_id': accountId,
          'p_to_account_id': toAccountId,
          'p_category_id': categoryId,
          'p_amount': amount,
          'p_transaction_date': transactionDate?.toIso8601String(),
          'p_fee_amount': feeAmount,
          'p_note': note,
          'p_payee': payee,
          'p_image_url': imageUrl,
          'p_paid_by': paidBy,
          'p_split_mode': splitMode?.name,
          'p_splits': (splitMode != null && splitMode.isSplit && splits != null)
              ? splits.map((s) => s.toJson()).toList()
              : null,
        },
      );
      return _singleTransaction(res);
    });
  }

  /// Xoá mềm. Trigger hợp nhất ở DB sẽ hoàn tiền về ví.
  Future<Result<void>> softDeleteTransaction(
    String transactionId,
    String groupId,
  ) {
    return Result.guard(() async {
      final res = await _client.rpc(
        'soft_delete_transaction',
        params: {'p_transaction_id': transactionId, 'p_group_id': groupId},
      );
      if (res != true) {
        throw const AppException(
          'Không xoá được giao dịch. Có thể bạn không còn ở trong nhóm này.',
          kind: AppErrorKind.permission,
          code: AppErrorCode.deleteTransactionDenied,
        );
      }
    });
  }

  Transaction _singleTransaction(dynamic res) {
    if (res is Map) {
      return Transaction.fromMap(Map<String, dynamic>.from(res));
    }
    if (res is List && res.isNotEmpty) {
      return Transaction.fromMap(Map<String, dynamic>.from(res.first as Map));
    }
    throw const AppException(
      'Máy chủ không trả về giao dịch vừa ghi.',
      code: AppErrorCode.transactionNotReturned,
    );
  }
}
