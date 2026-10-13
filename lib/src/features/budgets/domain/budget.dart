/// Chu kỳ ngân sách.
enum BudgetPeriod {
  weekly,
  monthly,
  yearly,
  custom;

  static BudgetPeriod fromName(String? v) => BudgetPeriod.values.firstWhere(
    (p) => p.name == v,
    orElse: () => BudgetPeriod.monthly,
  );
}

/// Hạn mức chi cho một danh mục trong một kỳ, kèm số đã tiêu.
class Budget {
  const Budget({
    required this.id,
    required this.categoryId,
    required this.categoryName,
    required this.colorHex,
    required this.iconName,
    required this.amount,
    required this.spent,
    required this.period,
    required this.startDate,
    required this.endDate,
  });

  final String id;
  final String categoryId;

  /// Null = ngân sách của danh mục đã xoá / không tên; UI thay bằng
  /// `l10n.commonOther`.
  final String? categoryName;
  final String colorHex;
  final String iconName;

  /// Hạn mức.
  final double amount;

  /// Đã tiêu trong kỳ.
  final double spent;

  final BudgetPeriod period;
  final DateTime startDate;
  final DateTime endDate;

  double get remaining => amount - spent;

  /// 0.0 – 1.0+ (có thể vượt 1 khi tiêu quá hạn mức).
  double get progress => amount <= 0 ? 0 : spent / amount;

  bool get isOverBudget => spent > amount;

  /// Đã dùng quá 80% — đáng cảnh báo trước khi vượt.
  bool get isNearLimit => !isOverBudget && progress >= 0.8;

  bool get isActive {
    final now = DateTime.now();
    return !now.isBefore(startDate) && !now.isAfter(endDate);
  }

  /// Số ngày còn lại của kỳ.
  int get daysLeft {
    final diff = endDate.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }

  factory Budget.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic v) => v == null
        ? DateTime.now()
        : (v is DateTime ? v : DateTime.parse(v.toString()));

    return Budget(
      id: map['budget_id'] as String? ?? map['id'] as String,
      categoryId: map['category_id'] as String? ?? '',
      categoryName: map['category_name'] as String?,
      colorHex: map['color_hex'] as String? ?? '#A0A0A0',
      iconName: map['icon_name'] as String? ?? 'category',
      amount: (map['amount'] is num) ? (map['amount'] as num).toDouble() : 0,
      spent: (map['spent'] is num) ? (map['spent'] as num).toDouble() : 0,
      period: BudgetPeriod.fromName(map['period'] as String?),
      startDate: parseDate(map['start_date']),
      endDate: parseDate(map['end_date']),
    );
  }
}

/// Tính khoảng ngày cho một chu kỳ, bắt đầu từ [anchor].
({DateTime start, DateTime end}) periodRange(
  BudgetPeriod period,
  DateTime anchor, {
  int firstDayOfMonth = 1,
}) {
  switch (period) {
    case BudgetPeriod.weekly:
      final start = anchor.subtract(Duration(days: anchor.weekday - 1));
      return (
        start: DateTime(start.year, start.month, start.day),
        end: DateTime(start.year, start.month, start.day + 6),
      );

    case BudgetPeriod.monthly:
      final start = anchor.day >= firstDayOfMonth
          ? DateTime(anchor.year, anchor.month, firstDayOfMonth)
          : DateTime(anchor.year, anchor.month - 1, firstDayOfMonth);
      final end = DateTime(
        start.year,
        start.month + 1,
        start.day,
      ).subtract(const Duration(days: 1));
      return (start: start, end: end);

    case BudgetPeriod.yearly:
      return (
        start: DateTime(anchor.year, 1, 1),
        end: DateTime(anchor.year, 12, 31),
      );

    case BudgetPeriod.custom:
      return (
        start: DateTime(anchor.year, anchor.month, anchor.day),
        end: DateTime(anchor.year, anchor.month + 1, anchor.day),
      );
  }
}
