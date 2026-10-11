import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:spend_sync/src/core/errors/app_exception.dart';
import 'package:spend_sync/src/core/result.dart';

void main() {
  group('Ok', () {
    const r = Ok<int>(42);

    test('isOk đúng, isErr sai', () {
      expect(r.isOk, isTrue);
      expect(r.isErr, isFalse);
    });

    test('valueOrNull trả giá trị, errorOrNull null', () {
      expect(r.valueOrNull, 42);
      expect(r.errorOrNull, isNull);
    });

    test('value giữ đúng giá trị đã bọc', () {
      expect(r.value, 42);
    });

    test('when đi nhánh ok', () {
      final label = r.when(ok: (v) => 'ok:$v', err: (e) => 'err:${e.message}');
      expect(label, 'ok:42');
    });
  });

  group('Err', () {
    const err = AppException('sập rồi', kind: AppErrorKind.validation);
    const r = Err<int>(err);

    test('isErr đúng, isOk sai', () {
      expect(r.isErr, isTrue);
      expect(r.isOk, isFalse);
    });

    test('valueOrNull null, errorOrNull là message của lỗi', () {
      expect(r.valueOrNull, isNull);
      expect(r.errorOrNull, 'sập rồi');
    });

    test('error giữ nguyên đối tượng AppException', () {
      expect(r.error, same(err));
      expect(r.error.kind, AppErrorKind.validation);
    });

    test('when đi nhánh err', () {
      final label = r.when(ok: (v) => 'ok:$v', err: (e) => 'err:${e.message}');
      expect(label, 'err:sập rồi');
    });

    test('cast<R> giữ nguyên lỗi, đổi kiểu', () {
      final Err<String> casted = r.cast<String>();
      expect(casted.error, same(err));
    });
  });

  group('Result.guard — nhánh thành công', () {
    test('action trả giá trị → Ok chứa giá trị đó', () async {
      final r = await Result.guard<int>(() async => 7);
      expect(r, isA<Ok<int>>());
      expect(r.isOk, isTrue);
      expect(r.valueOrNull, 7);
      expect(r.errorOrNull, isNull);
    });

    test('giá trị void vẫn thành Ok', () async {
      final r = await Result.guard<void>(() async {});
      expect(r.isOk, isTrue);
    });
  });

  group('Result.guard — nhánh ném lỗi (map qua mapError → AppException)', () {
    test('ném AppException → Err giữ nguyên lỗi đó', () async {
      const original = AppException('cụ thể', kind: AppErrorKind.permission);
      final r = await Result.guard<int>(() async => throw original);
      expect(r, isA<Err<int>>());
      final err = (r as Err<int>).error;
      expect(err, same(original));
      expect(err.kind, AppErrorKind.permission);
    });

    test('ném SocketException → Err kind network', () async {
      final r = await Result.guard<int>(
        () async => throw const SocketException('mất mạng'),
      );
      expect(r.isErr, isTrue);
      final err = (r as Err<int>).error;
      expect(err, isA<AppException>());
      expect(err.kind, AppErrorKind.network);
    });

    test('ném TimeoutException → Err kind network', () async {
      final r = await Result.guard<int>(
        () async => throw TimeoutException('quá lâu'),
      );
      expect((r as Err<int>).error.kind, AppErrorKind.network);
    });

    test(
      'ném lỗi lạ → Err kind unknown với thông điệp tiếng Việt chung',
      () async {
        final r = await Result.guard<int>(() async => throw Exception('boom'));
        expect(r.isErr, isTrue);
        final err = (r as Err<int>).error;
        expect(err.kind, AppErrorKind.unknown);
        expect(err.message, 'Đã xảy ra lỗi. Thử lại sau ít phút.');
      },
    );

    test('errorOrNull của guard-lỗi là message đã dịch', () async {
      final r = await Result.guard<int>(
        () async => throw const SocketException('x'),
      );
      expect(r.errorOrNull, isNotNull);
      expect(r.valueOrNull, isNull);
    });
  });
}
