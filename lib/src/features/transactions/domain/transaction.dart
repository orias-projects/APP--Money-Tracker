/// Cách chia một khoản chi trong nhóm.
enum SplitMode {
  /// Không chia — chi tiêu cá nhân, không tính vào công nợ nhóm.
  none,

  /// Chia đều cho những người được chọn.
  equal,

  /// Mỗi người một số tiền cụ thể.
  exact,

  /// Mỗi người một tỉ lệ phần trăm.
  percent,

  /// Chia theo số phần (1 phần, 2 phần…).
  shares;

  static SplitMode fromName(String? value) {
    return SplitMode.values.firstWhere(
      (m) => m.name == value,
      orElse: () => SplitMode.none,
    );
  }

  bool get isSplit => this != SplitMode.none;
}

/// Phần một người phải gánh trong một khoản chi.
class TransactionSplit {
  const TransactionSplit({
    required this.userId,
    required this.shareAmount,
    this.displayName,
  });

  final String userId;
  final double shareAmount;
  final String? displayName;

  factory TransactionSplit.fromMap(Map<String, dynamic> map) {
    return TransactionSplit(
      userId: map['user_id'] as String,
      shareAmount: (map['share_amount'] is num)
          ? (map['share_amount'] as num).toDouble()
          : 0,
      displayName: map['display_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'share_amount': shareAmount,
  };

  TransactionSplit copyWith({double? shareAmount}) => TransactionSplit(
    userId: userId,
    shareAmount: shareAmount ?? this.shareAmount,
    displayName: displayName,
  );
}

class Transaction {
  const Transaction({
    required this.id,
    required this.groupId,
    required this.accountId,
    this.toAccountId,
    this.categoryId,
    required this.type,
    required this.amount,
    this.feeAmount = 0,
    required this.transactionDate,
    this.note,
    this.payee,
    this.imageUrl,
    required this.createdBy,
    required this.paidBy,
    this.splitMode = SplitMode.none,
    this.splits = const [],
    this.createdByUserName,
    this.paidByUserName,
    this.createdByAvatarUrl,
    this.paidByAvatarUrl,
  });

  final String id;
  final String groupId;
  final String accountId;
  final String? toAccountId;
  final String? categoryId;
  final String type;
  final double amount;
  final double feeAmount;
  final DateTime transactionDate;
  final String? note;
  final String? payee;
  final String? imageUrl;
  final String createdBy;
  final String paidBy;
  final SplitMode splitMode;
  final List<TransactionSplit> splits;
  final String? createdByUserName;
  final String? paidByUserName;
  final String? createdByAvatarUrl;
  final String? paidByAvatarUrl;

  bool get isIncome => type == 'income';
  bool get isExpense => type == 'expense';
  bool get isTransfer => type == 'transfer';

  /// Phần mà [userId] phải gánh trong khoản chi này.
  double shareOf(String userId) {
    if (!splitMode.isSplit) return 0;
    for (final s in splits) {
      if (s.userId == userId) return s.shareAmount;
    }
    return 0;
  }

  Transaction copyWith({List<TransactionSplit>? splits}) => Transaction(
    id: id,
    groupId: groupId,
    accountId: accountId,
    toAccountId: toAccountId,
    categoryId: categoryId,
    type: type,
    amount: amount,
    feeAmount: feeAmount,
    transactionDate: transactionDate,
    note: note,
    payee: payee,
    imageUrl: imageUrl,
    createdBy: createdBy,
    paidBy: paidBy,
    splitMode: splitMode,
    splits: splits ?? this.splits,
    createdByUserName: createdByUserName,
    paidByUserName: paidByUserName,
    createdByAvatarUrl: createdByAvatarUrl,
    paidByAvatarUrl: paidByAvatarUrl,
  );

  factory Transaction.fromMap(Map<String, dynamic> map) {
    final d = map['transaction_date'];
    final createdByUser = map['created_by_user'] as Map<String, dynamic>?;
    final paidByUser = map['paid_by_user'] as Map<String, dynamic>?;
    final rawSplits = map['transaction_splits'];
    return Transaction(
      id: map['id'] as String,
      groupId: map['group_id'] as String,
      accountId: map['account_id'] as String,
      toAccountId: map['to_account_id'] as String?,
      categoryId: map['category_id'] as String?,
      type: map['type'] as String,
      amount: (map['amount'] is num) ? (map['amount'] as num).toDouble() : 0,
      feeAmount: (map['fee_amount'] is num)
          ? (map['fee_amount'] as num).toDouble()
          : 0,
      transactionDate: d != null
          ? (d is DateTime ? d : DateTime.parse(d.toString()))
          : DateTime.now(),
      note: map['note'] as String?,
      payee: map['payee'] as String?,
      imageUrl: map['image_url'] as String?,
      createdBy: map['created_by'] as String,
      paidBy: map['paid_by'] as String,
      splitMode: SplitMode.fromName(map['split_mode'] as String?),
      splits: rawSplits is List
          ? rawSplits
                .whereType<Map>()
                .map(
                  (e) => TransactionSplit.fromMap(Map<String, dynamic>.from(e)),
                )
                .toList()
          : const [],
      createdByUserName:
          createdByUser?['full_name'] as String? ??
          createdByUser?['username'] as String?,
      paidByUserName:
          paidByUser?['full_name'] as String? ??
          paidByUser?['username'] as String?,
      createdByAvatarUrl: createdByUser?['avatar_url'] as String?,
      paidByAvatarUrl: paidByUser?['avatar_url'] as String?,
    );
  }
}

/// Tổng thu/chi trong một kỳ, tính ở server thay vì tải hết giao dịch về.
class PeriodSummary {
  const PeriodSummary({
    required this.income,
    required this.expense,
    required this.count,
  });

  final double income;
  final double expense;
  final int count;

  double get balance => income - expense;

  static const empty = PeriodSummary(income: 0, expense: 0, count: 0);

  factory PeriodSummary.fromMap(Map<String, dynamic> map) {
    return PeriodSummary(
      income: (map['income'] is num) ? (map['income'] as num).toDouble() : 0,
      expense: (map['expense'] is num) ? (map['expense'] as num).toDouble() : 0,
      count: (map['tx_count'] is num) ? (map['tx_count'] as num).toInt() : 0,
    );
  }
}
