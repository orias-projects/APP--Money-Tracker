import 'package:flutter_test/flutter_test.dart';
import 'package:spend_sync/src/features/transactions/data/transaction_repository.dart';

/// [TransactionQuery] là KHOÁ CACHE cho `provider.family`. Nếu `==`/`hashCode`
/// sai thì hai bộ lọc khác nhau dùng chung một provider (rò cache) hoặc một bộ
/// lọc tạo lại provider liên tục (miss cache). Các test này chốt hợp đồng đó.
void main() {
  // Bộ lọc "đầy đủ" để có gì đó cụ thể mà so sánh từng field.
  TransactionQuery full({
    String groupId = 'g1',
    List<String>? accountIds = const ['a1', 'a2'],
    List<String>? categoryIds = const ['c1'],
    List<String>? types = const ['expense'],
    DateTime? from,
    DateTime? to,
    String? search = 'cà phê',
    double? minAmount = 10,
    double? maxAmount = 100,
    int offset = 0,
    int limit = 50,
  }) {
    return TransactionQuery(
      groupId: groupId,
      accountIds: accountIds,
      categoryIds: categoryIds,
      types: types,
      from: from ?? DateTime(2026, 1, 1),
      to: to ?? DateTime(2026, 1, 31),
      search: search,
      minAmount: minAmount,
      maxAmount: maxAmount,
      offset: offset,
      limit: limit,
    );
  }

  group('TransactionQuery == và hashCode', () {
    test('hai query giống hệt thì bằng nhau và cùng hashCode', () {
      final a = full();
      final b = full();
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('cùng một instance thì bằng chính nó (identical short-circuit)', () {
      final a = full();
      expect(a == a, isTrue);
    });

    test('so với đối tượng khác kiểu thì không bằng', () {
      expect(full() == Object(), isFalse);
    });

    test('khác groupId → khác nhau', () {
      expect(full(groupId: 'g1'), isNot(equals(full(groupId: 'g2'))));
    });

    test('khác categoryIds → khác nhau', () {
      expect(
        full(categoryIds: const ['c1']),
        isNot(equals(full(categoryIds: const ['c2']))),
      );
    });

    test('khác types → khác nhau', () {
      expect(
        full(types: const ['expense']),
        isNot(equals(full(types: const ['income']))),
      );
    });

    test('khác from → khác nhau', () {
      expect(
        full(from: DateTime(2026, 1, 1)),
        isNot(equals(full(from: DateTime(2026, 2, 1)))),
      );
    });

    test('khác to → khác nhau', () {
      expect(
        full(to: DateTime(2026, 1, 31)),
        isNot(equals(full(to: DateTime(2026, 2, 28)))),
      );
    });

    test('khác search → khác nhau', () {
      expect(full(search: 'a'), isNot(equals(full(search: 'b'))));
    });

    test('khác minAmount → khác nhau', () {
      expect(full(minAmount: 10), isNot(equals(full(minAmount: 20))));
    });

    test('khác maxAmount → khác nhau', () {
      expect(full(maxAmount: 100), isNot(equals(full(maxAmount: 200))));
    });

    test('khác offset → khác nhau (== so cả phân trang)', () {
      expect(full(offset: 0), isNot(equals(full(offset: 50))));
    });

    test('khác limit → khác nhau (== so cả phân trang)', () {
      expect(full(limit: 50), isNot(equals(full(limit: 20))));
    });
  });

  group('So sánh danh sách (accountIds) đúng ngữ nghĩa _listEq', () {
    test('cùng phần tử cùng thứ tự → bằng nhau', () {
      expect(
        full(accountIds: const ['a', 'b']),
        equals(full(accountIds: const ['a', 'b'])),
      );
    });

    test('cùng phần tử KHÁC thứ tự → khác nhau (thứ tự có ý nghĩa)', () {
      expect(
        full(accountIds: const ['a', 'b']),
        isNot(equals(full(accountIds: const ['b', 'a']))),
      );
    });

    test('khác độ dài → khác nhau', () {
      expect(
        full(accountIds: const ['a']),
        isNot(equals(full(accountIds: const ['a', 'b']))),
      );
    });

    test('null vs null → bằng nhau', () {
      expect(full(accountIds: null), equals(full(accountIds: null)));
    });

    test('null vs list rỗng → khác nhau', () {
      expect(full(accountIds: null), isNot(equals(full(accountIds: const []))));
    });

    test('rỗng vs rỗng → bằng nhau và cùng hashCode', () {
      final a = full(accountIds: const []);
      final b = full(accountIds: const []);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });
  });

  group('filterKey — khoá cache bỏ qua phân trang', () {
    test('reset offset và limit về 0', () {
      final k = full(offset: 100, limit: 25).filterKey;
      expect(k.offset, 0);
      expect(k.limit, 0);
    });

    test('giữ nguyên mọi field lọc còn lại', () {
      final q = full(offset: 100, limit: 25);
      final k = q.filterKey;
      expect(k.groupId, q.groupId);
      expect(k.accountIds, q.accountIds);
      expect(k.categoryIds, q.categoryIds);
      expect(k.types, q.types);
      expect(k.from, q.from);
      expect(k.to, q.to);
      expect(k.search, q.search);
      expect(k.minAmount, q.minAmount);
      expect(k.maxAmount, q.maxAmount);
    });

    test('hai query chỉ khác phân trang → cùng filterKey và cùng hashCode', () {
      final page1 = full(offset: 0, limit: 50);
      final page2 = full(offset: 50, limit: 50);
      expect(page1, isNot(equals(page2))); // bản thân chúng khác nhau
      expect(page1.filterKey, equals(page2.filterKey)); // nhưng cùng khoá cache
      expect(page1.filterKey.hashCode, page2.filterKey.hashCode);
    });

    test('khác điều kiện lọc thật → filterKey khác nhau', () {
      final a = full(groupId: 'g1', offset: 0);
      final b = full(groupId: 'g2', offset: 999);
      expect(a.filterKey, isNot(equals(b.filterKey)));
    });

    test('ổn định / idempotent: filterKey của filterKey không đổi', () {
      final q = full(offset: 40, limit: 10);
      expect(q.filterKey.filterKey, equals(q.filterKey));
    });

    test('gọi filterKey hai lần cho kết quả bằng nhau', () {
      final q = full();
      expect(q.filterKey, equals(q.filterKey));
    });
  });

  group('copyWith', () {
    test('chỉ đổi offset, giữ mọi field khác', () {
      final q = full(offset: 0, limit: 50);
      final c = q.copyWith(offset: 30);
      expect(c.offset, 30);
      expect(c.limit, 50);
      expect(c.groupId, q.groupId);
      expect(c.accountIds, q.accountIds);
      expect(c.search, q.search);
    });

    test('chỉ đổi limit, giữ offset', () {
      final q = full(offset: 20, limit: 50);
      final c = q.copyWith(limit: 10);
      expect(c.limit, 10);
      expect(c.offset, 20);
    });

    test('không truyền gì → tạo bản sao bằng bản gốc', () {
      final q = full(offset: 20, limit: 10);
      expect(q.copyWith(), equals(q));
    });
  });
}
