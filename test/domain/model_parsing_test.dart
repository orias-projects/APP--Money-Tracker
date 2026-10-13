import 'package:flutter_test/flutter_test.dart';
import 'package:spend_sync/src/features/accounts/domain/account.dart';
import 'package:spend_sync/src/features/categories/domain/category.dart';
import 'package:spend_sync/src/features/transactions/domain/transaction.dart';
import 'package:spend_sync/src/features/budgets/domain/budget.dart';
import 'package:spend_sync/src/features/recurring/domain/recurring_transaction.dart';
import 'package:spend_sync/src/features/groups/domain/group_balance.dart';
import 'package:spend_sync/src/features/groups/domain/group.dart';
import 'package:spend_sync/src/features/groups/domain/group_member.dart';
import 'package:spend_sync/src/features/groups/domain/group_invitation.dart';

/// Kiểm thử thuần trên `fromMap` + các getter suy diễn của model domain.
/// Đây là app tài chính: parse sai một field là sai tiền, nên mỗi assert
/// kiểm một giá trị/hành vi CỤ THỂ, không dùng `isNotNull` cho có.
void main() {
  // ---------------------------------------------------------------------------
  // Account
  // ---------------------------------------------------------------------------
  group('Account.fromMap', () {
    Map<String, dynamic> base() => {
      'id': 'acc-1',
      'user_id': 'u-1',
      'name': 'Tiền mặt',
      'account_type': 'asset',
    };

    test('điền giá trị mặc định khi map chỉ có các field bắt buộc', () {
      final a = Account.fromMap(base());
      expect(a.id, 'acc-1');
      expect(a.userId, 'u-1');
      expect(a.name, 'Tiền mặt');
      expect(a.accountType, 'asset');
      expect(a.groupId, isNull);
      expect(a.balance, 0.0);
      expect(a.openingBalance, 0.0);
      expect(a.creditLimit, 0.0);
      expect(a.statementDate, isNull);
      expect(a.paymentDate, isNull);
      expect(a.currency, 'VND');
      expect(a.includeInTotal, isTrue);
      expect(a.status, 'active');
    });

    test('ép num→double: balance nhận cả int lẫn double', () {
      expect(Account.fromMap({...base(), 'balance': 100}).balance, 100.0);
      expect(
        Account.fromMap({...base(), 'balance': 100}).balance,
        isA<double>(),
      );
      expect(Account.fromMap({...base(), 'balance': 100.5}).balance, 100.5);
      expect(
        Account.fromMap({...base(), 'opening_balance': 42}).openingBalance,
        42.0,
      );
      expect(
        Account.fromMap({...base(), 'credit_limit': 5000000}).creditLimit,
        5000000.0,
      );
    });

    test('giá trị không phải số cho balance → về 0 (không ném lỗi)', () {
      expect(Account.fromMap({...base(), 'balance': 'abc'}).balance, 0.0);
      expect(Account.fromMap({...base(), 'balance': null}).balance, 0.0);
    });

    test('statement_date/payment_date ép num→int, thiếu → null', () {
      final a = Account.fromMap({
        ...base(),
        'statement_date': 15,
        'payment_date': 25.0,
      });
      expect(a.statementDate, 15);
      expect(a.paymentDate, 25);
      expect(a.paymentDate, isA<int>());
      expect(Account.fromMap(base()).statementDate, isNull);
    });

    test('cờ và chuỗi tuỳ chọn được đọc đúng khi có mặt', () {
      final a = Account.fromMap({
        ...base(),
        'group_id': 'g-9',
        'currency': 'USD',
        'include_in_total': false,
        'status': 'archived',
      });
      expect(a.groupId, 'g-9');
      expect(a.currency, 'USD');
      expect(a.includeInTotal, isFalse);
      expect(a.status, 'archived');
    });
  });

  group('Account getter suy diễn', () {
    Account of({
      String type = 'asset',
      String? groupId,
      String status = 'active',
      double balance = 0,
      double creditLimit = 0,
    }) => Account(
      id: 'a',
      userId: 'u',
      groupId: groupId,
      name: 'x',
      accountType: type,
      balance: balance,
      creditLimit: creditLimit,
      status: status,
    );

    test('isAsset / isLiability theo account_type', () {
      expect(of(type: 'asset').isAsset, isTrue);
      expect(of(type: 'asset').isLiability, isFalse);
      expect(of(type: 'liability').isLiability, isTrue);
      expect(of(type: 'liability').isAsset, isFalse);
    });

    test('isShared = có group_id', () {
      expect(of(groupId: 'g').isShared, isTrue);
      expect(of(groupId: null).isShared, isFalse);
    });

    test('isActive = status active', () {
      expect(of(status: 'active').isActive, isTrue);
      expect(of(status: 'archived').isActive, isFalse);
    });

    test('availableCredit chỉ tính cho ví nợ có hạn mức > 0', () {
      expect(
        of(type: 'liability', creditLimit: 1000, balance: 300).availableCredit,
        700.0,
      );
      // Vay quá hạn mức → âm.
      expect(
        of(type: 'liability', creditLimit: 1000, balance: 1200).availableCredit,
        -200.0,
      );
      // Hạn mức 0 → null.
      expect(of(type: 'liability', creditLimit: 0).availableCredit, isNull);
      // Ví tài sản → null bất kể hạn mức.
      expect(of(type: 'asset', creditLimit: 1000).availableCredit, isNull);
    });
  });

  group('AccountLabel.labelFor', () {
    AccountLabel of({required bool isShared, String owner = 'Minh'}) =>
        AccountLabel(
          id: 'a',
          name: 'Tiền mặt',
          accountType: 'asset',
          ownerName: owner,
          isShared: isShared,
        );

    test('ví chung → chỉ tên, không gắn chủ ví', () {
      expect(of(isShared: true).labelFor(isMine: false), 'Tiền mặt');
    });

    test('ví cá nhân của mình → chỉ tên', () {
      expect(of(isShared: false).labelFor(isMine: true), 'Tiền mặt');
    });

    test('ví cá nhân của người khác → gắn tên chủ ví', () {
      expect(of(isShared: false).labelFor(isMine: false), 'Tiền mặt · Minh');
    });

    test('không rõ chủ ví → không gắn hậu tố', () {
      expect(
        of(isShared: false, owner: '').labelFor(isMine: false),
        'Tiền mặt',
      );
    });
  });

  group('BalanceDrift.fromMap', () {
    test('drift = mới − cũ, ép num→double, tên mặc định rỗng', () {
      final d = BalanceDrift.fromMap({
        'account_id': 'a',
        'old_balance': 100,
        'new_balance': 130.5,
      });
      expect(d.accountName, '');
      expect(d.oldBalance, 100.0);
      expect(d.newBalance, 130.5);
      expect(d.drift, 30.5);
    });
  });

  // ---------------------------------------------------------------------------
  // Category
  // ---------------------------------------------------------------------------
  group('Category.fromMap', () {
    test('mặc định icon/màu khi thiếu, giữ các field khác null', () {
      final c = Category.fromMap({
        'id': 'c-1',
        'name': 'Ăn uống',
        'type': 'expense',
      });
      expect(c.id, 'c-1');
      expect(c.name, 'Ăn uống');
      expect(c.type, 'expense');
      expect(c.iconName, 'category');
      expect(c.colorHex, '#A0A0A0');
      expect(c.userId, isNull);
      expect(c.parentId, isNull);
      expect(c.orderIndex, 0);
    });

    test('đọc đúng khi đủ field', () {
      final c = Category.fromMap({
        'id': 'c-2',
        'name': 'Lương',
        'type': 'income',
        'icon_name': 'wallet',
        'color_hex': '#00FF00',
        'user_id': 'u-1',
        'parent_id': 'c-1',
        'order_index': 3,
      });
      expect(c.iconName, 'wallet');
      expect(c.colorHex, '#00FF00');
      expect(c.userId, 'u-1');
      expect(c.parentId, 'c-1');
      expect(c.orderIndex, 3);
    });

    test('isIncome / isExpense theo type', () {
      expect(
        Category.fromMap({'id': 'c', 'name': 'x', 'type': 'income'}).isIncome,
        isTrue,
      );
      expect(
        Category.fromMap({'id': 'c', 'name': 'x', 'type': 'expense'}).isExpense,
        isTrue,
      );
      expect(
        Category.fromMap({'id': 'c', 'name': 'x', 'type': 'income'}).isExpense,
        isFalse,
      );
    });

    test('order_index dạng double được ép về int', () {
      final c = Category.fromMap({
        'id': 'c',
        'name': 'x',
        'type': 'expense',
        'order_index': 2.0,
      });
      expect(c.orderIndex, 2);
    });
  });

  // ---------------------------------------------------------------------------
  // SplitMode + TransactionSplit + Transaction
  // ---------------------------------------------------------------------------
  group('SplitMode', () {
    test('fromName ánh xạ đúng tên hợp lệ', () {
      expect(SplitMode.fromName('equal'), SplitMode.equal);
      expect(SplitMode.fromName('exact'), SplitMode.exact);
      expect(SplitMode.fromName('percent'), SplitMode.percent);
      expect(SplitMode.fromName('shares'), SplitMode.shares);
      expect(SplitMode.fromName('none'), SplitMode.none);
    });

    test('fromName giá trị lạ hoặc null → none (nhánh orElse)', () {
      expect(SplitMode.fromName('khong-ton-tai'), SplitMode.none);
      expect(SplitMode.fromName(''), SplitMode.none);
      expect(SplitMode.fromName(null), SplitMode.none);
    });

    test('isSplit chỉ false với none', () {
      expect(SplitMode.none.isSplit, isFalse);
      expect(SplitMode.equal.isSplit, isTrue);
      expect(SplitMode.exact.isSplit, isTrue);
      expect(SplitMode.percent.isSplit, isTrue);
      expect(SplitMode.shares.isSplit, isTrue);
    });
  });

  group('TransactionSplit.fromMap', () {
    test('ép share_amount num→double, displayName tuỳ chọn', () {
      final s = TransactionSplit.fromMap({
        'user_id': 'u-1',
        'share_amount': 50000,
        'display_name': 'An',
      });
      expect(s.userId, 'u-1');
      expect(s.shareAmount, 50000.0);
      expect(s.displayName, 'An');
    });

    test('thiếu share_amount → 0, thiếu display_name → null', () {
      final s = TransactionSplit.fromMap({'user_id': 'u-2'});
      expect(s.shareAmount, 0.0);
      expect(s.displayName, isNull);
    });
  });

  group('Transaction.fromMap', () {
    Map<String, dynamic> base() => {
      'id': 't-1',
      'group_id': 'g-1',
      'account_id': 'a-1',
      'type': 'expense',
      'created_by': 'u-1',
      'paid_by': 'u-1',
    };

    test('mặc định hợp lý khi chỉ có field bắt buộc', () {
      final t = Transaction.fromMap(base());
      expect(t.id, 't-1');
      expect(t.groupId, 'g-1');
      expect(t.accountId, 'a-1');
      expect(t.type, 'expense');
      expect(t.amount, 0.0);
      expect(t.feeAmount, 0.0);
      expect(t.toAccountId, isNull);
      expect(t.categoryId, isNull);
      expect(t.note, isNull);
      expect(t.splitMode, SplitMode.none);
      expect(t.splits, isEmpty);
      expect(t.createdByUserName, isNull);
      expect(t.paidByUserName, isNull);
    });

    test('ép amount/fee_amount num→double (int và double)', () {
      final t = Transaction.fromMap({
        ...base(),
        'amount': 250000,
        'fee_amount': 1500.5,
      });
      expect(t.amount, 250000.0);
      expect(t.amount, isA<double>());
      expect(t.feeAmount, 1500.5);
    });

    test('transaction_date parse từ String ISO', () {
      final t = Transaction.fromMap({
        ...base(),
        'transaction_date': '2026-03-15T08:30:00.000',
      });
      expect(t.transactionDate, DateTime.parse('2026-03-15T08:30:00.000'));
    });

    test('transaction_date nhận thẳng DateTime', () {
      final dt = DateTime(2026, 1, 2, 3, 4);
      final t = Transaction.fromMap({...base(), 'transaction_date': dt});
      expect(t.transactionDate, dt);
    });

    test('thiếu transaction_date → ~now', () {
      final before = DateTime.now();
      final t = Transaction.fromMap(base());
      final after = DateTime.now();
      expect(t.transactionDate.isBefore(before), isFalse);
      expect(t.transactionDate.isAfter(after), isFalse);
    });

    test('split_mode + danh sách transaction_splits được parse', () {
      final t = Transaction.fromMap({
        ...base(),
        'split_mode': 'equal',
        'transaction_splits': [
          {'user_id': 'u-1', 'share_amount': 30000},
          {'user_id': 'u-2', 'share_amount': 20000.0},
        ],
      });
      expect(t.splitMode, SplitMode.equal);
      expect(t.splits.length, 2);
      expect(t.splits[0].userId, 'u-1');
      expect(t.splits[0].shareAmount, 30000.0);
      expect(t.splits[1].shareAmount, 20000.0);
    });

    test('split_mode lạ → none', () {
      final t = Transaction.fromMap({...base(), 'split_mode': 'weird'});
      expect(t.splitMode, SplitMode.none);
    });

    test('tên người từ full_name, fallback username', () {
      final t = Transaction.fromMap({
        ...base(),
        'created_by_user': {'full_name': 'Nguyễn A', 'username': 'na'},
        'paid_by_user': {'username': 'pb', 'avatar_url': 'http://x/y.png'},
      });
      expect(t.createdByUserName, 'Nguyễn A');
      expect(t.paidByUserName, 'pb');
      expect(t.paidByAvatarUrl, 'http://x/y.png');
      expect(t.createdByAvatarUrl, isNull);
    });

    test('isIncome / isExpense / isTransfer theo type', () {
      expect(
        Transaction.fromMap({...base(), 'type': 'income'}).isIncome,
        isTrue,
      );
      expect(
        Transaction.fromMap({...base(), 'type': 'expense'}).isExpense,
        isTrue,
      );
      expect(
        Transaction.fromMap({...base(), 'type': 'transfer'}).isTransfer,
        isTrue,
      );
    });
  });

  group('Transaction.shareOf', () {
    Transaction of(SplitMode mode, List<TransactionSplit> splits) =>
        Transaction(
          id: 't',
          groupId: 'g',
          accountId: 'a',
          type: 'expense',
          amount: 100000,
          transactionDate: DateTime(2026),
          createdBy: 'u1',
          paidBy: 'u1',
          splitMode: mode,
          splits: splits,
        );

    test('không chia → luôn 0 dù có splits', () {
      final t = of(SplitMode.none, const [
        TransactionSplit(userId: 'u2', shareAmount: 50000),
      ]);
      expect(t.shareOf('u2'), 0);
    });

    test('có chia → trả đúng phần của người dùng, người ngoài → 0', () {
      final t = of(SplitMode.equal, const [
        TransactionSplit(userId: 'u1', shareAmount: 40000),
        TransactionSplit(userId: 'u2', shareAmount: 60000),
      ]);
      expect(t.shareOf('u1'), 40000);
      expect(t.shareOf('u2'), 60000);
      expect(t.shareOf('nguoi-la'), 0);
    });
  });

  group('PeriodSummary.fromMap', () {
    test('ép num→double/int, balance = income − expense', () {
      final s = PeriodSummary.fromMap({
        'income': 1000000,
        'expense': 400000.0,
        'tx_count': 12,
      });
      expect(s.income, 1000000.0);
      expect(s.expense, 400000.0);
      expect(s.count, 12);
      expect(s.balance, 600000.0);
    });

    test('map rỗng → 0 hết', () {
      final s = PeriodSummary.fromMap({});
      expect(s.income, 0.0);
      expect(s.expense, 0.0);
      expect(s.count, 0);
    });
  });

  // ---------------------------------------------------------------------------
  // Budget
  // ---------------------------------------------------------------------------
  group('BudgetPeriod.fromName', () {
    test('tên hợp lệ', () {
      expect(BudgetPeriod.fromName('weekly'), BudgetPeriod.weekly);
      expect(BudgetPeriod.fromName('monthly'), BudgetPeriod.monthly);
      expect(BudgetPeriod.fromName('yearly'), BudgetPeriod.yearly);
      expect(BudgetPeriod.fromName('custom'), BudgetPeriod.custom);
    });

    test('giá trị lạ hoặc null → monthly (orElse)', () {
      expect(BudgetPeriod.fromName('lung-tung'), BudgetPeriod.monthly);
      expect(BudgetPeriod.fromName(null), BudgetPeriod.monthly);
    });
  });

  group('Budget.fromMap', () {
    test('id ưu tiên budget_id, fallback id', () {
      expect(Budget.fromMap({'budget_id': 'b-1', 'id': 'x'}).id, 'b-1');
      expect(Budget.fromMap({'id': 'x'}).id, 'x');
    });

    test('mặc định khi thiếu field', () {
      final b = Budget.fromMap({'id': 'b'});
      expect(b.categoryId, '');
      expect(b.categoryName, isNull);
      expect(b.colorHex, '#A0A0A0');
      expect(b.iconName, 'category');
      expect(b.amount, 0.0);
      expect(b.spent, 0.0);
      expect(b.period, BudgetPeriod.monthly);
    });

    test('ép amount/spent num→double và parse ngày từ String', () {
      final b = Budget.fromMap({
        'id': 'b',
        'amount': 2000000,
        'spent': 1500000.5,
        'period': 'weekly',
        'start_date': '2026-03-01',
        'end_date': '2026-03-07',
      });
      expect(b.amount, 2000000.0);
      expect(b.spent, 1500000.5);
      expect(b.period, BudgetPeriod.weekly);
      expect(b.startDate, DateTime.parse('2026-03-01'));
      expect(b.endDate, DateTime.parse('2026-03-07'));
    });

    test('start_date/end_date nhận DateTime trực tiếp, thiếu → ~now', () {
      final start = DateTime(2026, 5, 1);
      final b = Budget.fromMap({'id': 'b', 'start_date': start});
      expect(b.startDate, start);
      // end_date thiếu → gần now
      final now = DateTime.now();
      expect((b.endDate.difference(now)).inSeconds.abs() < 5, isTrue);
    });
  });

  group('Budget getter suy diễn', () {
    Budget of({
      double amount = 100,
      double spent = 0,
      DateTime? start,
      DateTime? end,
    }) => Budget(
      id: 'b',
      categoryId: 'c',
      categoryName: 'x',
      colorHex: '#fff',
      iconName: 'i',
      amount: amount,
      spent: spent,
      period: BudgetPeriod.monthly,
      startDate: start ?? DateTime(2026, 1, 1),
      endDate: end ?? DateTime(2026, 1, 31),
    );

    test('remaining / progress / isOverBudget mức bình thường', () {
      final b = of(amount: 100, spent: 50);
      expect(b.remaining, 50);
      expect(b.progress, 0.5);
      expect(b.isOverBudget, isFalse);
      expect(b.isNearLimit, isFalse);
    });

    test('đạt 80% → isNearLimit, chưa vượt', () {
      final b = of(amount: 100, spent: 80);
      expect(b.progress, 0.8);
      expect(b.isNearLimit, isTrue);
      expect(b.isOverBudget, isFalse);
    });

    test('vượt hạn mức → isOverBudget, remaining âm, KHÔNG nearLimit', () {
      final b = of(amount: 100, spent: 120);
      expect(b.remaining, -20);
      expect(b.progress, 1.2);
      expect(b.isOverBudget, isTrue);
      expect(b.isNearLimit, isFalse);
    });

    test(
      'amount ≤ 0: progress = 0 (chống chia 0), nhưng spent>0 vẫn là vượt',
      () {
        final b = of(amount: 0, spent: 50);
        expect(b.progress, 0);
        expect(b.remaining, -50);
        expect(b.isOverBudget, isTrue);
        expect(b.isNearLimit, isFalse);
      },
    );

    test('amount 0 và spent 0 → không vượt, progress 0', () {
      final b = of(amount: 0, spent: 0);
      expect(b.progress, 0);
      expect(b.isOverBudget, isFalse);
    });

    test('isActive: now nằm trong [start, end]', () {
      final now = DateTime.now();
      expect(
        of(
          start: now.subtract(const Duration(days: 1)),
          end: now.add(const Duration(days: 1)),
        ).isActive,
        isTrue,
      );
      // Kỳ trong tương lai.
      expect(
        of(
          start: now.add(const Duration(days: 1)),
          end: now.add(const Duration(days: 2)),
        ).isActive,
        isFalse,
      );
      // Kỳ đã qua.
      expect(
        of(
          start: now.subtract(const Duration(days: 5)),
          end: now.subtract(const Duration(days: 1)),
        ).isActive,
        isFalse,
      );
    });

    test('daysLeft: âm → 0, tương lai → số ngày còn lại', () {
      final now = DateTime.now();
      expect(of(end: now.subtract(const Duration(days: 3))).daysLeft, 0);
      expect(
        of(end: now.add(const Duration(days: 10, hours: 12))).daysLeft,
        10,
      );
    });
  });

  group('periodRange', () {
    test(
      'weekly: bắt đầu thứ Hai, kết thúc Chủ nhật, trọn 6 ngày, chứa anchor',
      () {
        final anchor = DateTime(2026, 3, 18);
        final r = periodRange(BudgetPeriod.weekly, anchor);
        expect(r.start.weekday, DateTime.monday);
        expect(r.end.weekday, DateTime.sunday);
        expect(r.end.difference(r.start).inDays, 6);
        expect(r.start.isAfter(anchor), isFalse);
        expect(r.end.isBefore(anchor), isFalse);
      },
    );

    test('weekly: tuần vắt sang tháng trước vẫn bắt đầu thứ Hai', () {
      final anchor = DateTime(2026, 3, 1);
      final r = periodRange(BudgetPeriod.weekly, anchor);
      expect(r.start.weekday, DateTime.monday);
      expect(r.end.difference(r.start).inDays, 6);
      expect(r.start.isAfter(anchor), isFalse);
    });

    test(
      'monthly mặc định (mốc ngày 1): phủ trọn tháng, biên cuối tháng đúng',
      () {
        final jan = periodRange(BudgetPeriod.monthly, DateTime(2026, 1, 15));
        expect(jan.start, DateTime(2026, 1, 1));
        expect(jan.end, DateTime(2026, 1, 31));

        // Tháng 2 năm thường → 28 ngày.
        final feb = periodRange(BudgetPeriod.monthly, DateTime(2026, 2, 10));
        expect(feb.start, DateTime(2026, 2, 1));
        expect(feb.end, DateTime(2026, 2, 28));

        // Tháng 12 → biên năm sang tháng 1 năm sau.
        final dec = periodRange(BudgetPeriod.monthly, DateTime(2026, 12, 5));
        expect(dec.start, DateTime(2026, 12, 1));
        expect(dec.end, DateTime(2026, 12, 31));
      },
    );

    test(
      'monthly: mốc giữa tháng, anchor SAU mốc → kỳ trong tháng hiện tại',
      () {
        final r = periodRange(
          BudgetPeriod.monthly,
          DateTime(2026, 3, 20),
          firstDayOfMonth: 15,
        );
        expect(r.start, DateTime(2026, 3, 15));
        expect(r.end, DateTime(2026, 4, 14));
      },
    );

    test(
      'monthly: mốc giữa tháng, anchor TRƯỚC mốc trong tháng 1 → lùi qua năm',
      () {
        // Biên tháng 1: DateTime(year, month-1=0, day) chuẩn hoá về tháng 12 năm trước.
        final r = periodRange(
          BudgetPeriod.monthly,
          DateTime(2026, 1, 10),
          firstDayOfMonth: 15,
        );
        expect(r.start, DateTime(2025, 12, 15));
        expect(r.end, DateTime(2026, 1, 14));
      },
    );

    test('yearly: 1/1 tới 31/12 của năm anchor', () {
      final r = periodRange(BudgetPeriod.yearly, DateTime(2026, 6, 15));
      expect(r.start, DateTime(2026, 1, 1));
      expect(r.end, DateTime(2026, 12, 31));
    });

    test('custom: đúng một tháng kể từ ngày anchor', () {
      final r = periodRange(BudgetPeriod.custom, DateTime(2026, 3, 10));
      expect(r.start, DateTime(2026, 3, 10));
      expect(r.end, DateTime(2026, 4, 10));
    });

    test('custom: anchor tháng 12 → end vắt sang năm sau', () {
      final r = periodRange(BudgetPeriod.custom, DateTime(2026, 12, 15));
      expect(r.start, DateTime(2026, 12, 15));
      expect(r.end, DateTime(2027, 1, 15));
    });

    test(
      'custom: anchor 31/1 → end tràn sang tháng 3 (quirk chuẩn hoá ngày)',
      () {
        // DateTime(2026, 2, 31) không tồn tại → Dart chuẩn hoá thành 3/3.
        // Ghi chú: đây là hành vi bất ngờ tiềm ẩn (xem báo cáo).
        final r = periodRange(BudgetPeriod.custom, DateTime(2026, 1, 31));
        expect(r.start, DateTime(2026, 1, 31));
        expect(r.end, DateTime(2026, 3, 3));
      },
    );
  });

  // ---------------------------------------------------------------------------
  // RecurringTransaction
  // ---------------------------------------------------------------------------
  group('RecurringFrequency.fromName', () {
    test('tên hợp lệ', () {
      expect(RecurringFrequency.fromName('daily'), RecurringFrequency.daily);
      expect(RecurringFrequency.fromName('weekly'), RecurringFrequency.weekly);
      expect(
        RecurringFrequency.fromName('monthly'),
        RecurringFrequency.monthly,
      );
      expect(RecurringFrequency.fromName('yearly'), RecurringFrequency.yearly);
    });

    test('giá trị lạ hoặc null → monthly (orElse)', () {
      expect(
        RecurringFrequency.fromName('hang-gio'),
        RecurringFrequency.monthly,
      );
      expect(RecurringFrequency.fromName(null), RecurringFrequency.monthly);
    });
  });

  group('RecurringTransaction.fromMap', () {
    Map<String, dynamic> base() => {'id': 'r-1', 'account_id': 'a-1'};

    test('mặc định: type=expense, amount=0, monthly, isActive=true', () {
      final r = RecurringTransaction.fromMap(base());
      expect(r.id, 'r-1');
      expect(r.accountId, 'a-1');
      expect(r.categoryId, isNull);
      expect(r.type, 'expense');
      expect(r.amount, 0.0);
      expect(r.frequency, RecurringFrequency.monthly);
      expect(r.note, isNull);
      expect(r.isActive, isTrue);
    });

    test('ép amount num→double và đọc các field', () {
      final r = RecurringTransaction.fromMap({
        ...base(),
        'category_id': 'c-1',
        'type': 'income',
        'amount': 7000000,
        'frequency': 'weekly',
        'note': 'Lương',
        'is_active': false,
      });
      expect(r.categoryId, 'c-1');
      expect(r.type, 'income');
      expect(r.amount, 7000000.0);
      expect(r.frequency, RecurringFrequency.weekly);
      expect(r.note, 'Lương');
      expect(r.isActive, isFalse);
    });

    test('next_date parse String / DateTime / thiếu → ~now', () {
      expect(
        RecurringTransaction.fromMap({
          ...base(),
          'next_date': '2026-04-01',
        }).nextDate,
        DateTime.parse('2026-04-01'),
      );
      final dt = DateTime(2026, 4, 2);
      expect(
        RecurringTransaction.fromMap({...base(), 'next_date': dt}).nextDate,
        dt,
      );
      final now = DateTime.now();
      expect(
        (RecurringTransaction.fromMap(
              base(),
            ).nextDate.difference(now)).inSeconds.abs() <
            5,
        isTrue,
      );
    });
  });

  group('RecurringTransaction getter suy diễn', () {
    RecurringTransaction of({
      required DateTime nextDate,
      bool isActive = true,
      String type = 'expense',
    }) => RecurringTransaction(
      id: 'r',
      accountId: 'a',
      type: type,
      amount: 1000,
      frequency: RecurringFrequency.monthly,
      nextDate: nextDate,
      isActive: isActive,
    );

    test('isExpense theo type', () {
      expect(of(nextDate: DateTime(2026), type: 'expense').isExpense, isTrue);
      expect(of(nextDate: DateTime(2026), type: 'income').isExpense, isFalse);
    });

    test('isOverdue: active + đã quá hạn hơn 1 ngày', () {
      final now = DateTime.now();
      expect(
        of(nextDate: now.subtract(const Duration(days: 5))).isOverdue,
        isTrue,
      );
      // Tương lai → không quá hạn.
      expect(of(nextDate: now.add(const Duration(days: 5))).isOverdue, isFalse);
      // Ngưng hoạt động → không tính là quá hạn.
      expect(
        of(
          nextDate: now.subtract(const Duration(days: 5)),
          isActive: false,
        ).isOverdue,
        isFalse,
      );
    });

    test('daysUntilNext đếm theo ngày lịch từ hôm nay', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      expect(of(nextDate: today.add(const Duration(days: 3))).daysUntilNext, 3);
      expect(of(nextDate: today).daysUntilNext, 0);
      expect(
        of(nextDate: today.subtract(const Duration(days: 2))).daysUntilNext,
        -2,
      );
    });
  });

  // ---------------------------------------------------------------------------
  // GroupBalance.fromMap + Settlement.fromMap
  // ---------------------------------------------------------------------------
  group('GroupBalance.fromMap', () {
    test('ép mọi field num→double, các tên tuỳ chọn null khi thiếu', () {
      final b = GroupBalance.fromMap({
        'user_id': 'u-1',
        'paid': 100000,
        'owed': 60000.0,
        'settled_out': 10000,
        'settled_in': 5000,
        'net': 40000,
      });
      expect(b.userId, 'u-1');
      expect(b.fullName, isNull);
      expect(b.username, isNull);
      expect(b.avatarUrl, isNull);
      expect(b.paid, 100000.0);
      expect(b.owed, 60000.0);
      expect(b.settledOut, 10000.0);
      expect(b.settledIn, 5000.0);
      expect(b.net, 40000.0);
    });

    test('thiếu số → 0', () {
      final b = GroupBalance.fromMap({'user_id': 'u'});
      expect(b.paid, 0.0);
      expect(b.owed, 0.0);
      expect(b.settledOut, 0.0);
      expect(b.settledIn, 0.0);
      expect(b.net, 0.0);
    });

    test('displayName sau parse: full_name → username → "Thành viên"', () {
      expect(
        GroupBalance.fromMap({
          'user_id': 'u',
          'full_name': 'Trần B',
          'username': 'tb',
        }).displayNameOr('fallback'),
        'Trần B',
      );
      expect(
        GroupBalance.fromMap({
          'user_id': 'u',
          'full_name': '   ',
          'username': 'tb',
        }).displayNameOr('fallback'),
        'tb',
      );
      expect(
        GroupBalance.fromMap({'user_id': 'u'}).displayNameOr('fallback'),
        'fallback',
      );
    });

    test('isCreditor / isDebtor / isSettled sau parse net', () {
      expect(
        GroupBalance.fromMap({'user_id': 'u', 'net': 1}).isCreditor,
        isTrue,
      );
      expect(
        GroupBalance.fromMap({'user_id': 'u', 'net': -1}).isDebtor,
        isTrue,
      );
      // |net| ≤ 0.5 coi như đã cân.
      expect(
        GroupBalance.fromMap({'user_id': 'u', 'net': 0.3}).isSettled,
        isTrue,
      );
      expect(
        GroupBalance.fromMap({'user_id': 'u', 'net': 0.3}).isCreditor,
        isFalse,
      );
    });
  });

  group('Settlement.fromMap', () {
    Map<String, dynamic> base() => {
      'id': 's-1',
      'from_user': 'u-1',
      'to_user': 'u-2',
    };

    test('tên mặc định rỗng, note null, amount 0, settled_at ~now', () {
      final s = Settlement.fromMap(base());
      expect(s.id, 's-1');
      expect(s.fromUser, 'u-1');
      expect(s.toUser, 'u-2');
      expect(s.fromName, '');
      expect(s.toName, '');
      expect(s.amount, 0.0);
      expect(s.note, isNull);
      final now = DateTime.now();
      expect((s.settledAt.difference(now)).inSeconds.abs() < 5, isTrue);
    });

    test('đọc đủ field, ép amount, parse settled_at từ String', () {
      final s = Settlement.fromMap({
        ...base(),
        'from_name': 'A',
        'to_name': 'B',
        'amount': 250000,
        'note': 'trả nợ',
        'settled_at': '2026-02-14T10:00:00.000',
      });
      expect(s.fromName, 'A');
      expect(s.toName, 'B');
      expect(s.amount, 250000.0);
      expect(s.note, 'trả nợ');
      expect(s.settledAt, DateTime.parse('2026-02-14T10:00:00.000'));
    });
  });

  // ---------------------------------------------------------------------------
  // AppGroup / GroupMember / GroupInvitation
  // ---------------------------------------------------------------------------
  group('AppGroup.fromMap', () {
    test(
      'mặc định: name rỗng, isPersonal=true, status active, createdAt null',
      () {
        final g = AppGroup.fromMap({'id': 'g-1'});
        expect(g.id, 'g-1');
        expect(g.name, '');
        expect(g.isPersonal, isTrue);
        expect(g.inviteCode, isNull);
        expect(g.status, 'active');
        expect(g.createdAt, isNull);
        expect(g.isShared, isFalse);
      },
    );

    test('nhóm chung: isShared = !isPersonal, parse created_at', () {
      final g = AppGroup.fromMap({
        'id': 'g-2',
        'name': 'Đi Đà Lạt',
        'is_personal': false,
        'invite_code': 'ABCD1234',
        'status': 'active',
        'created_at': '2026-01-01T00:00:00.000',
      });
      expect(g.name, 'Đi Đà Lạt');
      expect(g.isPersonal, isFalse);
      expect(g.isShared, isTrue);
      expect(g.inviteCode, 'ABCD1234');
      expect(g.createdAt, DateTime.parse('2026-01-01T00:00:00.000'));
    });

    test('created_at nhận DateTime trực tiếp', () {
      final dt = DateTime(2026, 5, 5);
      expect(AppGroup.fromMap({'id': 'g', 'created_at': dt}).createdAt, dt);
    });
  });

  group('GroupMember.fromMap', () {
    test('mặc định role=member, status=active, user/group null khi thiếu', () {
      final m = GroupMember.fromMap({
        'id': 'm-1',
        'group_id': 'g-1',
        'user_id': 'u-1',
      });
      expect(m.id, 'm-1');
      expect(m.groupId, 'g-1');
      expect(m.userId, 'u-1');
      expect(m.role, 'member');
      expect(m.status, 'active');
      expect(m.joinedAt, isNull);
      expect(m.user, isNull);
      expect(m.group, isNull);
      expect(m.isAdmin, isFalse);
    });

    test('isAdmin khi role=admin, và parse user/group lồng nhau', () {
      final m = GroupMember.fromMap({
        'id': 'm-2',
        'group_id': 'g-1',
        'user_id': 'u-1',
        'role': 'admin',
        'joined_at': '2026-03-03',
        'user': {'id': 'u-1', 'full_name': 'Lê C', 'username': 'lc'},
        'group': {'id': 'g-1', 'name': 'Nhà', 'is_personal': false},
      });
      expect(m.isAdmin, isTrue);
      expect(m.joinedAt, DateTime.parse('2026-03-03'));
      expect(m.user, isNotNull);
      expect(m.user!.fullName, 'Lê C');
      expect(m.group, isNotNull);
      expect(m.group!.name, 'Nhà');
      expect(m.group!.isShared, isTrue);
    });
  });

  group('GroupInvitation.fromMap', () {
    test('mặc định tên rỗng, createdAt null khi thiếu', () {
      final inv = GroupInvitation.fromMap({
        'id': 'i-1',
        'group_id': 'g-1',
        'invited_by': 'u-1',
      });
      expect(inv.id, 'i-1');
      expect(inv.groupId, 'g-1');
      expect(inv.invitedBy, 'u-1');
      expect(inv.groupName, '');
      expect(inv.inviterName, '');
      expect(inv.createdAt, isNull);
    });

    test('đọc đủ field và parse created_at', () {
      final inv = GroupInvitation.fromMap({
        'id': 'i-2',
        'group_id': 'g-1',
        'group_name': 'Nhóm A',
        'invited_by': 'u-1',
        'inviter_name': 'Phạm D',
        'created_at': '2026-06-06',
      });
      expect(inv.groupName, 'Nhóm A');
      expect(inv.inviterName, 'Phạm D');
      expect(inv.createdAt, DateTime.parse('2026-06-06'));
    });

    test('created_at chuỗi hỏng → null (dùng tryParse, không ném lỗi)', () {
      // Ghi chú: khác các model khác dùng DateTime.parse (sẽ ném lỗi).
      final inv = GroupInvitation.fromMap({
        'id': 'i-3',
        'group_id': 'g-1',
        'invited_by': 'u-1',
        'created_at': 'khong-phai-ngay',
      });
      expect(inv.createdAt, isNull);
    });
  });
}
