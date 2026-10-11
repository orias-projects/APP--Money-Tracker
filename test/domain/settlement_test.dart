import 'package:flutter_test/flutter_test.dart';
import 'package:spend_sync/src/features/groups/domain/group_balance.dart';

GroupBalance balance(String id, double net) => GroupBalance(
  userId: id,
  fullName: id.toUpperCase(),
  username: id,
  paid: net > 0 ? net : 0,
  owed: net < 0 ? -net : 0,
  settledOut: 0,
  settledIn: 0,
  net: net,
);

void main() {
  group('suggestSettlements', () {
    test('không ai nợ ai thì không đề xuất gì', () {
      final result = suggestSettlements([balance('a', 0), balance('b', 0)]);
      expect(result, isEmpty);
    });

    test('hai người: một lần chuyển là xong', () {
      final result = suggestSettlements([
        balance('a', -100000), // a nợ
        balance('b', 100000), // b được nhận
      ]);

      expect(result.length, 1);
      expect(result.first.fromUserId, 'a');
      expect(result.first.toUserId, 'b');
      expect(result.first.amount, 100000);
    });

    test('ba người: số lần chuyển không vượt quá N-1', () {
      final result = suggestSettlements([
        balance('a', -60000),
        balance('b', -40000),
        balance('c', 100000),
      ]);

      expect(result.length, lessThanOrEqualTo(2));
      final total = result.fold<double>(0, (s, x) => s + x.amount);
      expect(total, 100000);
    });

    test('mọi khoản nợ đều được tất toán hết', () {
      final balances = [
        balance('a', -150000),
        balance('b', -50000),
        balance('c', 120000),
        balance('d', 80000),
      ];
      final result = suggestSettlements(balances);

      // Cộng dồn kết quả rồi kiểm tra mọi người về 0.
      final net = {for (final b in balances) b.userId: b.net};
      for (final s in result) {
        net[s.fromUserId] = net[s.fromUserId]! + s.amount;
        net[s.toUserId] = net[s.toUserId]! - s.amount;
      }
      for (final entry in net.entries) {
        expect(
          entry.value.abs(),
          lessThanOrEqualTo(1),
          reason: '${entry.key} phải về 0 sau khi quyết toán',
        );
      }
    });

    test('bỏ qua chênh lệch nhỏ hơn ngưỡng làm tròn', () {
      final result = suggestSettlements([
        balance('a', -0.4),
        balance('b', 0.4),
      ]);
      expect(result, isEmpty);
    });

    test('ghép người nợ nhiều nhất với người được nợ nhiều nhất trước', () {
      final result = suggestSettlements([
        balance('small', -10000),
        balance('big', -90000),
        balance('creditor', 100000),
      ]);
      expect(result.first.fromUserId, 'big');
      expect(result.first.amount, 90000);
    });
  });

  group('GroupBalance', () {
    test('phân loại đúng chủ nợ / con nợ / đã cân', () {
      expect(balance('a', 5000).isCreditor, isTrue);
      expect(balance('a', -5000).isDebtor, isTrue);
      expect(balance('a', 0).isSettled, isTrue);
      // Chênh dưới nửa đơn vị coi như đã cân.
      expect(balance('a', 0.3).isSettled, isTrue);
    });

    test('displayName ưu tiên tên đầy đủ rồi tới username', () {
      const withFull = GroupBalance(
        userId: 'x',
        fullName: 'Nguyễn Văn A',
        username: 'nva',
        paid: 0,
        owed: 0,
        settledOut: 0,
        settledIn: 0,
        net: 0,
      );
      expect(withFull.displayNameOr('fallback'), 'Nguyễn Văn A');

      const onlyUsername = GroupBalance(
        userId: 'x',
        fullName: '  ',
        username: 'nva',
        paid: 0,
        owed: 0,
        settledOut: 0,
        settledIn: 0,
        net: 0,
      );
      expect(onlyUsername.displayNameOr('fallback'), 'nva');

      const neither = GroupBalance(
        userId: 'x',
        fullName: null,
        username: null,
        paid: 0,
        owed: 0,
        settledOut: 0,
        settledIn: 0,
        net: 0,
      );
      expect(neither.displayNameOr('fallback'), 'fallback');
    });
  });
}
