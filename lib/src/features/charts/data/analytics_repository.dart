import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/error_mapper.dart';

/// Số liệu thống kê cho màn Biểu đồ.
///
/// Trước đây màn này gọi bốn hàm, mỗi hàm tự tải TOÀN BỘ giao dịch trong kỳ rồi
/// tính lại phía client — bốn lượt mạng cho cùng một tập dữ liệu. Giờ toàn bộ
/// phép cộng chạy trong Postgres và trả về một lần.
class AnalyticsRepository {
  AnalyticsRepository(this._client);

  final SupabaseClient _client;

  Future<AnalyticsSnapshot> getAnalytics({
    required String groupId,
    DateTime? from,
    DateTime? to,
    List<String>? accountIds,
    int topLimit = 5,
  }) async {
    if (groupId.isEmpty) return AnalyticsSnapshot.empty;
    try {
      final res = await _client.rpc(
        'get_analytics',
        params: {
          'p_group_id': groupId,
          'p_from': from?.toIso8601String(),
          'p_to': to?.toIso8601String(),
          'p_account_ids': (accountIds != null && accountIds.isNotEmpty)
              ? accountIds
              : null,
          'p_top_limit': topLimit,
        },
      );
      if (res is Map) {
        return AnalyticsSnapshot.fromMap(Map<String, dynamic>.from(res));
      }
      return AnalyticsSnapshot.empty;
    } catch (e, st) {
      throw mapError(e, st);
    }
  }
}

class AnalyticsSnapshot {
  const AnalyticsSnapshot({
    required this.expenseTotal,
    required this.incomeTotal,
    required this.expenseByCategory,
    required this.incomeByCategory,
    required this.topExpense,
    required this.topIncome,
  });

  final double expenseTotal;
  final double incomeTotal;
  final List<CategoryAmount> expenseByCategory;
  final List<CategoryAmount> incomeByCategory;
  final List<TopTransaction> topExpense;
  final List<TopTransaction> topIncome;

  static const empty = AnalyticsSnapshot(
    expenseTotal: 0,
    incomeTotal: 0,
    expenseByCategory: [],
    incomeByCategory: [],
    topExpense: [],
    topIncome: [],
  );

  factory AnalyticsSnapshot.fromMap(Map<String, dynamic> map) {
    double num_(String key) =>
        (map[key] is num) ? (map[key] as num).toDouble() : 0;

    List<T> list<T>(String key, T Function(Map<String, dynamic>) parse) {
      final raw = map[key];
      if (raw is! List) return const [];
      return raw
          .whereType<Map>()
          .map((e) => parse(Map<String, dynamic>.from(e)))
          .toList();
    }

    return AnalyticsSnapshot(
      expenseTotal: num_('expense_total'),
      incomeTotal: num_('income_total'),
      expenseByCategory: list('expense_by_category', CategoryAmount.fromMap),
      incomeByCategory: list('income_by_category', CategoryAmount.fromMap),
      topExpense: list('top_expense', TopTransaction.fromMap),
      topIncome: list('top_income', TopTransaction.fromMap),
    );
  }
}

class CategoryAmount {
  const CategoryAmount({
    required this.name,
    required this.amount,
    required this.colorHex,
    this.iconName = 'category',
  });

  /// Null = giao dịch chưa phân loại; UI tự thay nhãn theo ngôn ngữ
  /// (`l10n.commonOther`) thay vì gắn cứng tiếng Việt ở tầng data.
  final String? name;
  final double amount;
  final String colorHex;
  final String iconName;

  factory CategoryAmount.fromMap(Map<String, dynamic> map) {
    return CategoryAmount(
      name: map['name'] as String?,
      amount: (map['amount'] is num) ? (map['amount'] as num).toDouble() : 0,
      colorHex: map['color_hex'] as String? ?? '#A0A0A0',
      iconName: map['icon_name'] as String? ?? 'category',
    );
  }
}

/// Một dòng trong danh sách Top 5 — đã kèm sẵn tên danh mục nên không phải
/// tra ngược bảng categories ở phía client.
class TopTransaction {
  const TopTransaction({
    required this.id,
    required this.amount,
    required this.transactionDate,
    required this.categoryName,
    required this.colorHex,
    this.note,
  });

  final String id;
  final double amount;
  final DateTime transactionDate;

  /// Null = chưa phân loại; UI thay bằng `l10n.commonOther`.
  final String? categoryName;
  final String colorHex;
  final String? note;

  factory TopTransaction.fromMap(Map<String, dynamic> map) {
    final d = map['transaction_date'];
    return TopTransaction(
      id: map['id'] as String,
      amount: (map['amount'] is num) ? (map['amount'] as num).toDouble() : 0,
      transactionDate: d != null
          ? (d is DateTime ? d : DateTime.parse(d.toString()))
          : DateTime.now(),
      categoryName: map['category_name'] as String?,
      colorHex: map['color_hex'] as String? ?? '#A0A0A0',
      note: map['note'] as String?,
    );
  }
}
