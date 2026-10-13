import 'package:flutter_test/flutter_test.dart';
import 'package:spend_sync/src/features/transactions/domain/transaction.dart';
import 'package:spend_sync/src/features/transactions/presentation/widgets/split_editor.dart';

/// Chia tiền là phép tính dễ sai nhất trong app: tổng phần chia lệch quá 1 đơn
/// vị là RPC từ chối ghi. Bộ test này khoá chặt bất biến "tổng phần chia luôn
/// bằng đúng số tiền giao dịch".
void main() {
  double totalOf(List<TransactionSplit> splits) =>
      splits.fold<double>(0, (s, x) => s + x.shareAmount);

  group('SplitState.resolve — chia đều', () {
    test('chia hết: mỗi người một phần bằng nhau', () {
      const state = SplitState(
        mode: SplitMode.equal,
        participants: {'a', 'b', 'c'},
        rawValues: {},
      );
      final splits = state.resolve(300000);

      expect(splits.length, 3);
      expect(totalOf(splits), 300000);
      for (final s in splits) {
        expect(s.shareAmount, 100000);
      }
    });

    test('chia không hết: phần lẻ dồn cho người cuối, tổng vẫn khớp', () {
      const state = SplitState(
        mode: SplitMode.equal,
        participants: {'a', 'b', 'c'},
        rawValues: {},
      );
      final splits = state.resolve(100000);

      expect(totalOf(splits), 100000);
      // 100000 / 3 = 33333.33 → hai người 33333, người cuối 33334
      expect(
        splits.map((s) => s.shareAmount).toSet().length,
        lessThanOrEqualTo(2),
      );
    });

    test('một người: gánh toàn bộ', () {
      const state = SplitState(
        mode: SplitMode.equal,
        participants: {'a'},
        rawValues: {},
      );
      expect(totalOf(state.resolve(75000)), 75000);
    });

    test('số tiền lẻ bất kỳ vẫn khớp tổng', () {
      for (final amount in [1.0, 7.0, 999.0, 1000001.0, 123457.0]) {
        const state = SplitState(
          mode: SplitMode.equal,
          participants: {'a', 'b', 'c', 'd', 'e', 'f', 'g'},
          rawValues: {},
        );
        expect(
          totalOf(state.resolve(amount)),
          amount,
          reason: 'tổng phần chia phải khớp $amount',
        );
      }
    });
  });

  group('SplitState.resolve — theo phần trăm', () {
    test('60/40 chia đúng tỉ lệ', () {
      const state = SplitState(
        mode: SplitMode.percent,
        participants: {'a', 'b'},
        rawValues: {'a': 60, 'b': 40},
      );
      final splits = state.resolve(200000);
      final byUser = {for (final s in splits) s.userId: s.shareAmount};

      expect(byUser['a'], 120000);
      expect(byUser['b'], 80000);
      expect(totalOf(splits), 200000);
    });

    test('tỉ lệ lẻ vẫn khớp tổng', () {
      const state = SplitState(
        mode: SplitMode.percent,
        participants: {'a', 'b', 'c'},
        rawValues: {'a': 33.33, 'b': 33.33, 'c': 33.34},
      );
      expect(totalOf(state.resolve(100000)), 100000);
    });
  });

  group('SplitState.resolve — theo số phần', () {
    test('1:2 chia đúng', () {
      const state = SplitState(
        mode: SplitMode.shares,
        participants: {'a', 'b'},
        rawValues: {'a': 1, 'b': 2},
      );
      final byUser = {
        for (final s in state.resolve(300000)) s.userId: s.shareAmount,
      };
      expect(byUser['a'], 100000);
      expect(byUser['b'], 200000);
    });
  });

  group('SplitState.resolve — số tiền cụ thể', () {
    test('giữ nguyên số người dùng nhập', () {
      const state = SplitState(
        mode: SplitMode.exact,
        participants: {'a', 'b'},
        rawValues: {'a': 70000, 'b': 30000},
      );
      final byUser = {
        for (final s in state.resolve(100000)) s.userId: s.shareAmount,
      };
      expect(byUser['a'], 70000);
      expect(byUser['b'], 30000);
    });
  });

  group('SplitState.resolve — trường hợp biên', () {
    test('không chia thì không sinh phần nào', () {
      expect(SplitState.none.resolve(100000), isEmpty);
    });

    test('không có người tham gia thì không sinh phần nào', () {
      const state = SplitState(
        mode: SplitMode.equal,
        participants: {},
        rawValues: {},
      );
      expect(state.resolve(100000), isEmpty);
    });

    test('số tiền bằng 0 thì không sinh phần nào', () {
      const state = SplitState(
        mode: SplitMode.equal,
        participants: {'a', 'b'},
        rawValues: {},
      );
      expect(state.resolve(0), isEmpty);
    });

    test('tổng trọng số bằng 0 thì không sinh phần nào', () {
      const state = SplitState(
        mode: SplitMode.percent,
        participants: {'a', 'b'},
        rawValues: {'a': 0, 'b': 0},
      );
      expect(state.resolve(100000), isEmpty);
    });
  });

  group('SplitState.validate', () {
    test('không chia thì luôn hợp lệ', () {
      expect(SplitState.none.validate(100000), isNull);
    });

    test('chia mà không chọn ai thì báo lỗi', () {
      const state = SplitState(
        mode: SplitMode.equal,
        participants: {},
        rawValues: {},
      );
      expect(state.validate(100000), isNotNull);
    });

    test('phần trăm không đủ 100 thì báo lỗi', () {
      const state = SplitState(
        mode: SplitMode.percent,
        participants: {'a', 'b'},
        rawValues: {'a': 50, 'b': 30},
      );
      expect(state.validate(100000)?.kind, SplitIssueKind.percentTotal);
    });

    test('phần trăm đủ 100 thì hợp lệ', () {
      const state = SplitState(
        mode: SplitMode.percent,
        participants: {'a', 'b'},
        rawValues: {'a': 50, 'b': 50},
      );
      expect(state.validate(100000), isNull);
    });

    test('số tiền cụ thể thiếu thì báo còn thiếu', () {
      const state = SplitState(
        mode: SplitMode.exact,
        participants: {'a', 'b'},
        rawValues: {'a': 40000, 'b': 30000},
      );
      expect(state.validate(100000)?.kind, SplitIssueKind.shortBy);
    });

    test('số tiền cụ thể thừa thì báo thừa', () {
      const state = SplitState(
        mode: SplitMode.exact,
        participants: {'a', 'b'},
        rawValues: {'a': 70000, 'b': 50000},
      );
      expect(state.validate(100000)?.kind, SplitIssueKind.excessBy);
    });

    test('lệch 1 đơn vị do làm tròn thì chấp nhận', () {
      const state = SplitState(
        mode: SplitMode.exact,
        participants: {'a', 'b'},
        rawValues: {'a': 50000, 'b': 49999},
      );
      expect(state.validate(100000), isNull);
    });
  });
}
