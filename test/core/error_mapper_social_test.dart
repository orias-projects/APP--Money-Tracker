import 'package:flutter_test/flutter_test.dart';
import 'package:spend_sync/src/core/errors/app_exception.dart';
import 'package:spend_sync/src/core/errors/error_mapper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Mã lỗi thêm ở migration 008 (đăng nhập mạng xã hội, màn Tài khoản).
void main() {
  group('mapError — mã lỗi chuẩn GoTrue (AuthException.code)', () {
    AppException map(String code) =>
        mapError(AuthException('any message', code: code, statusCode: '400'));

    test('identity_already_exists → identityAlreadyLinked', () {
      expect(
        map('identity_already_exists').code,
        AppErrorCode.identityAlreadyLinked,
      );
    });

    test('single_identity_not_deletable → lastLoginMethod', () {
      expect(
        map('single_identity_not_deletable').code,
        AppErrorCode.lastLoginMethod,
      );
    });

    test('manual_linking_disabled → manualLinkingDisabled', () {
      expect(
        map('manual_linking_disabled').code,
        AppErrorCode.manualLinkingDisabled,
      );
    });

    test(
      'email_exists → emailExists; user_already_exists giữ emailAlreadyRegistered',
      () {
        expect(map('email_exists').code, AppErrorCode.emailExists);
        expect(
          map('user_already_exists').code,
          AppErrorCode.emailAlreadyRegistered,
        );
      },
    );

    test('mã chuẩn thắng message: invalid_credentials dù message lạ', () {
      final r = mapError(
        AuthException('something unrelated', code: 'invalid_credentials'),
      );
      expect(r.code, AppErrorCode.invalidCredentials);
      expect(r.kind, AppErrorKind.auth);
    });

    test('không có code → vẫn rơi về nhận diện theo message như cũ', () {
      final r = mapError(const AuthException('Invalid login credentials'));
      expect(r.code, AppErrorCode.invalidCredentials);
    });
  });

  group('mapError — RPC ném mã ngắn qua P0001', () {
    AppException map(String msg) =>
        mapError(PostgrestException(message: msg, code: 'P0001'));

    test('USERNAME_TAKEN → usernameTaken (validation)', () {
      final r = map('USERNAME_TAKEN');
      expect(r.code, AppErrorCode.usernameTaken);
      expect(r.kind, AppErrorKind.validation);
    });

    test('USERNAME_INVALID → usernameInvalid', () {
      expect(map('USERNAME_INVALID').code, AppErrorCode.usernameInvalid);
    });

    test('NOT_LOGGED_IN → notLoggedIn với kind auth', () {
      final r = map('NOT_LOGGED_IN');
      expect(r.code, AppErrorCode.notLoggedIn);
      expect(r.kind, AppErrorKind.auth);
    });

    test('thông điệp tự do vẫn giữ nguyên, không có code', () {
      final r = map('Số dư không đủ để quyết toán.');
      expect(r.code, isNull);
      expect(r.message, 'Số dư không đủ để quyết toán.');
    });
  });
}
