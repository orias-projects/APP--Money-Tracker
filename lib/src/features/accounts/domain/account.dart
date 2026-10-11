class Account {
  const Account({
    required this.id,
    required this.userId,
    this.groupId,
    required this.name,
    required this.accountType,
    required this.balance,
    this.openingBalance = 0,
    this.creditLimit = 0,
    this.statementDate,
    this.paymentDate,
    this.currency = 'VND',
    this.includeInTotal = true,
    this.status = 'active',
  });

  final String id;
  final String userId;

  /// Null = ví cá nhân. Có giá trị = ví dùng chung của nhóm.
  final String? groupId;

  final String name;

  /// 'asset' hoặc 'liability'.
  final String accountType;

  /// Với ví `asset`: số tiền đang có.
  /// Với ví `liability`: số tiền đang NỢ (luôn dương).
  final double balance;

  /// Số dư khởi tạo, tách khỏi tác động của sổ giao dịch.
  final double openingBalance;

  final double creditLimit;
  final int? statementDate;
  final int? paymentDate;
  final String currency;
  final bool includeInTotal;
  final String status;

  bool get isAsset => accountType == 'asset';
  bool get isLiability => accountType == 'liability';
  bool get isShared => groupId != null;
  bool get isActive => status == 'active';

  /// Hạn mức còn lại của thẻ tín dụng.
  double? get availableCredit =>
      isLiability && creditLimit > 0 ? creditLimit - balance : null;

  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      groupId: map['group_id'] as String?,
      name: map['name'] as String,
      accountType: map['account_type'] as String,
      balance: (map['balance'] is num) ? (map['balance'] as num).toDouble() : 0,
      openingBalance: (map['opening_balance'] is num)
          ? (map['opening_balance'] as num).toDouble()
          : 0,
      creditLimit: (map['credit_limit'] is num)
          ? (map['credit_limit'] as num).toDouble()
          : 0,
      statementDate: (map['statement_date'] is num)
          ? (map['statement_date'] as num).toInt()
          : null,
      paymentDate: (map['payment_date'] is num)
          ? (map['payment_date'] as num).toInt()
          : null,
      currency: map['currency'] as String? ?? 'VND',
      includeInTotal: map['include_in_total'] as bool? ?? true,
      status: map['status'] as String? ?? 'active',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Account && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

/// Tên ví hiển thị được cho mọi thành viên nhóm — kể cả ví cá nhân của người
/// khác, mà không lộ số dư. Dùng để render danh sách giao dịch trong nhóm.
class AccountLabel {
  const AccountLabel({
    required this.id,
    required this.name,
    required this.accountType,
    required this.ownerName,
    required this.isShared,
  });

  final String id;
  final String name;
  final String accountType;
  final String ownerName;
  final bool isShared;

  /// 'Tiền mặt' cho ví chung, 'Tiền mặt · Minh' cho ví cá nhân của người khác.
  String labelFor({required bool isMine}) =>
      (isShared || isMine || ownerName.isEmpty) ? name : '$name · $ownerName';

  factory AccountLabel.fromMap(Map<String, dynamic> map) {
    return AccountLabel(
      id: map['id'] as String,
      name: map['name'] as String? ?? '',
      accountType: map['account_type'] as String? ?? 'asset',
      ownerName: map['owner_name'] as String? ?? '',
      isShared: map['is_shared'] as bool? ?? false,
    );
  }
}

/// Kết quả đối soát một ví.
class BalanceDrift {
  const BalanceDrift({
    required this.accountId,
    required this.accountName,
    required this.oldBalance,
    required this.newBalance,
  });

  final String accountId;
  final String accountName;
  final double oldBalance;
  final double newBalance;

  double get drift => newBalance - oldBalance;

  factory BalanceDrift.fromMap(Map<String, dynamic> map) {
    return BalanceDrift(
      accountId: map['account_id'] as String,
      accountName: map['account_name'] as String? ?? '',
      oldBalance: (map['old_balance'] is num)
          ? (map['old_balance'] as num).toDouble()
          : 0,
      newBalance: (map['new_balance'] is num)
          ? (map['new_balance'] as num).toDouble()
          : 0,
    );
  }
}
