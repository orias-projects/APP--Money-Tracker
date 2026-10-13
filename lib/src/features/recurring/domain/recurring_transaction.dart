enum RecurringFrequency {
  daily,
  weekly,
  monthly,
  yearly;

  static RecurringFrequency fromName(String? v) => RecurringFrequency.values
      .firstWhere((f) => f.name == v, orElse: () => RecurringFrequency.monthly);
}

/// Giao dịch lặp lại theo chu kỳ (tiền nhà, lương, gói đăng ký…).
class RecurringTransaction {
  const RecurringTransaction({
    required this.id,
    required this.accountId,
    this.categoryId,
    required this.type,
    required this.amount,
    required this.frequency,
    required this.nextDate,
    this.note,
    this.isActive = true,
  });

  final String id;
  final String accountId;
  final String? categoryId;

  /// 'income' hoặc 'expense'.
  final String type;

  final double amount;
  final RecurringFrequency frequency;
  final DateTime nextDate;
  final String? note;
  final bool isActive;

  bool get isExpense => type == 'expense';

  /// Đã quá hạn mà chưa sinh giao dịch.
  bool get isOverdue =>
      isActive &&
      nextDate.isBefore(DateTime.now().subtract(const Duration(days: 1)));

  int get daysUntilNext {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return nextDate.difference(today).inDays;
  }

  factory RecurringTransaction.fromMap(Map<String, dynamic> map) {
    final d = map['next_date'];
    return RecurringTransaction(
      id: map['id'] as String,
      accountId: map['account_id'] as String,
      categoryId: map['category_id'] as String?,
      type: map['type'] as String? ?? 'expense',
      amount: (map['amount'] is num) ? (map['amount'] as num).toDouble() : 0,
      frequency: RecurringFrequency.fromName(map['frequency'] as String?),
      nextDate: d == null
          ? DateTime.now()
          : (d is DateTime ? d : DateTime.parse(d.toString())),
      note: map['note'] as String?,
      isActive: map['is_active'] as bool? ?? true,
    );
  }
}
