import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spend_sync/src/core/result.dart';
import 'package:spend_sync/src/features/accounts/data/account_repository.dart';
import 'package:spend_sync/src/features/accounts/data/account_service.dart';
import 'package:spend_sync/src/features/accounts/domain/account.dart';
import 'package:spend_sync/src/features/transactions/data/transaction_repository.dart';
import 'package:spend_sync/src/features/transactions/domain/transaction.dart';

class MockAccountRepository extends Mock implements AccountRepository {}

class MockTransactionRepository extends Mock implements TransactionRepository {}

Account _acc(String type, double balance) => Account(
  id: 'a1',
  userId: 'u1',
  name: 'Ví',
  accountType: type,
  balance: balance,
);

final _fakeTx = Transaction(
  id: 't1',
  groupId: 'g1',
  accountId: 'a1',
  type: 'expense',
  amount: 0,
  transactionDate: DateTime(2026, 1, 1),
  createdBy: 'u1',
  paidBy: 'u1',
);

void main() {
  setUpAll(() {
    registerFallbackValue(DateTime(2020));
    registerFallbackValue(SplitMode.none);
  });

  late MockTransactionRepository txRepo;
  late MockAccountRepository accRepo;
  late AccountService service;
  String? capturedType;
  double? capturedAmount;

  setUp(() {
    txRepo = MockTransactionRepository();
    accRepo = MockAccountRepository();
    service = AccountService(
      accountRepository: accRepo,
      transactionRepository: txRepo,
    );
    capturedType = null;
    capturedAmount = null;

    when(
      () => txRepo.createTransaction(
        groupId: any(named: 'groupId'),
        accountId: any(named: 'accountId'),
        type: any(named: 'type'),
        amount: any(named: 'amount'),
        transactionDate: any(named: 'transactionDate'),
        note: any(named: 'note'),
        splitMode: any(named: 'splitMode'),
      ),
    ).thenAnswer((inv) async {
      capturedType = inv.namedArguments[#type] as String;
      capturedAmount = inv.namedArguments[#amount] as double;
      return Ok<Transaction>(_fakeTx);
    });
  });

  group('adjustBalance — dấu của giao dịch điều chỉnh', () {
    test('ví tài sản, tăng số dư → ghi THU đúng chênh lệch', () async {
      final r = await service.adjustBalance(
        account: _acc('asset', 100),
        targetBalance: 150,
        groupId: 'g1',
      );
      expect(r.isOk, isTrue);
      expect(capturedType, 'income');
      expect(capturedAmount, 50);
    });

    test('ví tài sản, giảm số dư → ghi CHI đúng chênh lệch', () async {
      final r = await service.adjustBalance(
        account: _acc('asset', 100),
        targetBalance: 40,
        groupId: 'g1',
      );
      expect(r.isOk, isTrue);
      expect(capturedType, 'expense');
      expect(capturedAmount, 60);
    });

    test('ví nợ, nợ TĂNG → ghi CHI (tiền ra)', () async {
      final r = await service.adjustBalance(
        account: _acc('liability', 100),
        targetBalance: 150,
        groupId: 'g1',
      );
      expect(r.isOk, isTrue);
      expect(capturedType, 'expense');
      expect(capturedAmount, 50);
    });

    test('ví nợ, nợ GIẢM → ghi THU (trả bớt nợ)', () async {
      final r = await service.adjustBalance(
        account: _acc('liability', 100),
        targetBalance: 40,
        groupId: 'g1',
      );
      expect(r.isOk, isTrue);
      expect(capturedType, 'income');
      expect(capturedAmount, 60);
    });

    test(
      'số dư mới trùng số dư cũ → Result.err, KHÔNG ghi giao dịch',
      () async {
        final r = await service.adjustBalance(
          account: _acc('asset', 100),
          targetBalance: 100,
          groupId: 'g1',
        );
        expect(r.isErr, isTrue);
        verifyNever(
          () => txRepo.createTransaction(
            groupId: any(named: 'groupId'),
            accountId: any(named: 'accountId'),
            type: any(named: 'type'),
            amount: any(named: 'amount'),
            transactionDate: any(named: 'transactionDate'),
            note: any(named: 'note'),
            splitMode: any(named: 'splitMode'),
          ),
        );
      },
    );
  });
}
