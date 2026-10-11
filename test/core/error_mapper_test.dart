import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:spend_sync/src/core/errors/app_exception.dart';
import 'package:spend_sync/src/core/errors/error_mapper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('mapError', () {
    test('AppException được giữ nguyên, không bọc thêm', () {
      const e = AppException('x', kind: AppErrorKind.validation);
      expect(mapError(e), same(e));
    });

    test('SocketException → network', () {
      expect(
        mapError(const SocketException('failed')).kind,
        AppErrorKind.network,
      );
    });

    test('TimeoutException → network', () {
      expect(mapError(TimeoutException('t')).kind, AppErrorKind.network);
    });

    test('Postgrest 42501 (RLS) → permission', () {
      final r = mapError(
        PostgrestException(message: 'permission denied', code: '42501'),
      );
      expect(r.kind, AppErrorKind.permission);
    });

    test('Postgrest PGRST116 (không có bản ghi) → notFound', () {
      final r = mapError(
        PostgrestException(message: 'no rows', code: 'PGRST116'),
      );
      expect(r.kind, AppErrorKind.notFound);
    });

    test('Postgrest 23505 (trùng khoá) → validation', () {
      final r = mapError(
        PostgrestException(message: 'duplicate key value', code: '23505'),
      );
      expect(r.kind, AppErrorKind.validation);
    });

    test('Postgrest P0001 dùng thẳng thông điệp RPC tiếng Việt', () {
      final r = mapError(
        PostgrestException(message: 'Số tiền phải lớn hơn 0', code: 'P0001'),
      );
      expect(r.kind, AppErrorKind.validation);
      expect(r.message, 'Số tiền phải lớn hơn 0');
    });

    test(
      'AuthException sai thông tin đăng nhập → auth, thông điệp thân thiện',
      () {
        final r = mapError(const AuthException('Invalid login credentials'));
        expect(r.kind, AppErrorKind.auth);
        expect(r.message, contains('không đúng'));
      },
    );

    test('chuỗi lỗi giống mạng (failed host lookup) → network', () {
      final r = mapError('ClientException: Failed host lookup: api.x');
      expect(r.kind, AppErrorKind.network);
    });

    test('lỗi không xác định → unknown', () {
      expect(mapError(Exception('weird')).kind, AppErrorKind.unknown);
    });
  });
}
