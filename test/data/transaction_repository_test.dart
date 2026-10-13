import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spend_sync/src/core/errors/app_exception.dart';
import 'package:spend_sync/src/core/result.dart';
import 'package:spend_sync/src/features/transactions/data/transaction_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

void main() {
  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });

  late MockSupabaseClient client;
  late TransactionRepository repo;

  setUp(() {
    client = MockSupabaseClient();
    repo = TransactionRepository(client);
  });

  const q = TransactionQuery(groupId: 'g1');

  group('getTransactions (đọc — bất biến "không nuốt lỗi")', () {
    test('groupId rỗng: trả list rỗng và KHÔNG chạm tới client', () async {
      final res = await repo.getTransactions(
        const TransactionQuery(groupId: ''),
      );
      expect(res, isEmpty);
      verifyNever(() => client.from(any()));
    });

    test(
      'lỗi RLS (42501) → ném AppException kind=permission, KHÔNG trả list rỗng',
      () async {
        when(() => client.from(any())).thenThrow(
          PostgrestException(message: 'permission denied', code: '42501'),
        );

        await expectLater(
          repo.getTransactions(q),
          throwsA(
            isA<AppException>().having(
              (e) => e.kind,
              'kind',
              AppErrorKind.permission,
            ),
          ),
        );
      },
    );

    test('lỗi mạng → ném AppException kind=network', () async {
      when(
        () => client.from(any()),
      ).thenThrow(const SocketException('failed host lookup'));

      await expectLater(
        repo.getTransactions(q),
        throwsA(
          isA<AppException>().having(
            (e) => e.kind,
            'kind',
            AppErrorKind.network,
          ),
        ),
      );
    });
  });

  group('getPeriodSummary (đọc)', () {
    test('groupId rỗng: trả PeriodSummary.empty, không chạm client', () async {
      final res = await repo.getPeriodSummary(
        const TransactionQuery(groupId: ''),
      );
      expect(res.income, 0);
      expect(res.expense, 0);
      verifyNever(() => client.rpc(any()));
    });
  });

  group('createTransaction (ghi — trả Result với lý do thật)', () {
    test(
      'RPC ném lỗi nghiệp vụ (P0001) → Result.err giữ nguyên thông điệp RPC',
      () async {
        when(() => client.rpc(any(), params: any(named: 'params'))).thenThrow(
          PostgrestException(message: 'Số tiền phải lớn hơn 0', code: 'P0001'),
        );

        final result = await repo.createTransaction(
          groupId: 'g1',
          accountId: 'a1',
          type: 'expense',
          amount: 100,
          transactionDate: DateTime(2026, 1, 1),
        );

        expect(result.isErr, isTrue);
        expect(result.errorOrNull, 'Số tiền phải lớn hơn 0');
        expect((result as Err).error.kind, AppErrorKind.validation);
      },
    );

    test(
      'lỗi mạng khi ghi → Result.err kind=network (không ném ra ngoài)',
      () async {
        when(
          () => client.rpc(any(), params: any(named: 'params')),
        ).thenThrow(const SocketException('connection refused'));

        final result = await repo.createTransaction(
          groupId: 'g1',
          accountId: 'a1',
          type: 'expense',
          amount: 100,
          transactionDate: DateTime(2026, 1, 1),
        );

        expect(result.isErr, isTrue);
        expect((result as Err).error.kind, AppErrorKind.network);
      },
    );
  });
}
