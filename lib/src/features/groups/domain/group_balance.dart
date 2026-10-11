/// Công nợ ròng của một thành viên trong nhóm.
///
/// [net] > 0 : nhóm đang nợ người này (họ đã trả hộ nhiều hơn phần mình gánh).
/// [net] < 0 : người này đang nợ nhóm.
class GroupBalance {
  const GroupBalance({
    required this.userId,
    required this.fullName,
    required this.username,
    this.avatarUrl,
    required this.paid,
    required this.owed,
    required this.settledOut,
    required this.settledIn,
    required this.net,
  });

  final String userId;
  final String? fullName;
  final String? username;
  final String? avatarUrl;

  /// Tổng tiền người này đã trả hộ nhóm.
  final double paid;

  /// Tổng phần người này phải gánh.
  final double owed;

  /// Đã chuyển trả cho người khác.
  final double settledOut;

  /// Đã nhận từ người khác.
  final double settledIn;

  final double net;

  /// Tên hiển thị, rơi về [fallback] khi hồ sơ trống cả tên lẫn username
  /// (fallback do UI truyền vào để đúng ngôn ngữ: "Thành viên"/"Member").
  String displayNameOr(String fallback) {
    final n = fullName?.trim();
    if (n != null && n.isNotEmpty) return n;
    final u = username?.trim();
    if (u != null && u.isNotEmpty) return u;
    return fallback;
  }

  bool get isCreditor => net > 0.5;
  bool get isDebtor => net < -0.5;
  bool get isSettled => !isCreditor && !isDebtor;

  factory GroupBalance.fromMap(Map<String, dynamic> map) {
    double num_(String key) =>
        (map[key] is num) ? (map[key] as num).toDouble() : 0;
    return GroupBalance(
      userId: map['user_id'] as String,
      fullName: map['full_name'] as String?,
      username: map['username'] as String?,
      avatarUrl: map['avatar_url'] as String?,
      paid: num_('paid'),
      owed: num_('owed'),
      settledOut: num_('settled_out'),
      settledIn: num_('settled_in'),
      net: num_('net'),
    );
  }
}

/// Một lần chuyển tiền được đề xuất để tất toán công nợ nhóm.
class SettlementSuggestion {
  const SettlementSuggestion({
    required this.fromUserId,
    required this.fromName,
    required this.toUserId,
    required this.toName,
    required this.amount,
  });

  final String fromUserId;
  final String fromName;
  final String toUserId;
  final String toName;
  final double amount;
}

/// Một lần quyết toán đã ghi nhận.
class Settlement {
  const Settlement({
    required this.id,
    required this.fromUser,
    required this.fromName,
    required this.toUser,
    required this.toName,
    required this.amount,
    this.note,
    required this.settledAt,
  });

  final String id;
  final String fromUser;
  final String fromName;
  final String toUser;
  final String toName;
  final double amount;
  final String? note;
  final DateTime settledAt;

  factory Settlement.fromMap(Map<String, dynamic> map) {
    final d = map['settled_at'];
    return Settlement(
      id: map['id'] as String,
      fromUser: map['from_user'] as String,
      fromName: map['from_name'] as String? ?? '',
      toUser: map['to_user'] as String,
      toName: map['to_name'] as String? ?? '',
      amount: (map['amount'] is num) ? (map['amount'] as num).toDouble() : 0,
      note: map['note'] as String?,
      settledAt: d != null
          ? (d is DateTime ? d : DateTime.parse(d.toString()))
          : DateTime.now(),
    );
  }
}

/// Tính số lần chuyển tiền TỐI THIỂU để mọi người về 0.
///
/// Thuật toán tham lam: ghép người nợ nhiều nhất với người được nợ nhiều nhất,
/// trừ đi phần nhỏ hơn, lặp lại. Với nhóm bạn bè (dưới ~15 người) cách này cho
/// kết quả tối ưu hoặc rất sát tối ưu, và luôn ra ít hơn N−1 lần chuyển.
List<SettlementSuggestion> suggestSettlements(
  List<GroupBalance> balances, {
  double epsilon = 1,
  String memberFallback = 'Thành viên',
}) {
  final debtors = <_Party>[];
  final creditors = <_Party>[];

  for (final b in balances) {
    if (b.net < -epsilon) {
      debtors.add(_Party(b.userId, b.displayNameOr(memberFallback), -b.net));
    } else if (b.net > epsilon) {
      creditors.add(_Party(b.userId, b.displayNameOr(memberFallback), b.net));
    }
  }

  debtors.sort((a, b) => b.amount.compareTo(a.amount));
  creditors.sort((a, b) => b.amount.compareTo(a.amount));

  final result = <SettlementSuggestion>[];
  var i = 0;
  var j = 0;
  while (i < debtors.length && j < creditors.length) {
    final d = debtors[i];
    final c = creditors[j];
    final amount = d.amount < c.amount ? d.amount : c.amount;

    if (amount > epsilon) {
      result.add(
        SettlementSuggestion(
          fromUserId: d.id,
          fromName: d.name,
          toUserId: c.id,
          toName: c.name,
          amount: amount,
        ),
      );
    }

    d.amount -= amount;
    c.amount -= amount;
    if (d.amount <= epsilon) i++;
    if (c.amount <= epsilon) j++;
  }
  return result;
}

class _Party {
  _Party(this.id, this.name, this.amount);
  final String id;
  final String name;
  double amount;
}
