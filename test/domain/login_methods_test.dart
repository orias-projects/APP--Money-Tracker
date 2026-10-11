import 'package:flutter_test/flutter_test.dart';
import 'package:spend_sync/src/features/auth/domain/login_methods.dart';
import 'package:spend_sync/src/features/auth/domain/social_provider.dart';

void main() {
  group('Email tổng hợp cho đăng ký username-only', () {
    test('sinh từ username, luôn lowercase, đúng domain', () {
      expect(
        syntheticEmailFor('  An.Nguyen_9 '),
        'an.nguyen_9@$kSyntheticEmailDomain',
      );
    });

    test('nhận diện email tổng hợp không phân biệt hoa/thường', () {
      expect(isSyntheticEmail('abc@noemail.coinsort.app'), isTrue);
      expect(isSyntheticEmail('ABC@NOEMAIL.COINSORT.APP'), isTrue);
      expect(isSyntheticEmail('abc@gmail.com'), isFalse);
      expect(isSyntheticEmail(null), isFalse);
    });
  });

  group('isValidUsername (khớp regex của RPC update_my_username)', () {
    test('chấp nhận chữ thường, số, chấm, gạch dưới, 3–30 ký tự', () {
      expect(isValidUsername('abc'), isTrue);
      expect(isValidUsername('an.nguyen_9'), isTrue);
      expect(isValidUsername('a' * 30), isTrue);
    });

    test('từ chối quá ngắn, quá dài, hoa, khoảng trắng, ký tự lạ', () {
      expect(isValidUsername('ab'), isFalse);
      expect(isValidUsername('a' * 31), isFalse);
      expect(isValidUsername('Abc'), isFalse);
      expect(isValidUsername('an nguyen'), isFalse);
      expect(isValidUsername('an@nguyen'), isFalse);
      expect(isValidUsername(''), isFalse);
    });
  });

  group('LinkedIdentity.fromIdentityMap', () {
    test('Google: tên từ full_name, phụ là email', () {
      final li = LinkedIdentity.fromIdentityMap(
        provider: 'google',
        identityId: 'i1',
        data: {'full_name': 'An Nguyen', 'email': 'an@gmail.com'},
      );
      expect(li, isNotNull);
      expect(li!.provider, SocialProvider.google);
      expect(li.displayName, 'An Nguyen');
      expect(li.secondary, 'an@gmail.com');
    });

    test('Facebook: rơi về khoá name khi thiếu full_name', () {
      final li = LinkedIdentity.fromIdentityMap(
        provider: 'facebook',
        identityId: 'i2',
        data: {'name': 'An FB'},
      );
      expect(li!.displayName, 'An FB');
      expect(li.secondary, isNull);
    });

    test(
      'X: phụ là @handle thay cho email (id mới "x" và id cũ "twitter")',
      () {
        expect(
          LinkedIdentity.fromIdentityMap(
            provider: 'twitter',
            identityId: 'l',
          )!.provider,
          SocialProvider.twitter,
        );
        final li = LinkedIdentity.fromIdentityMap(
          provider: 'x',
          identityId: 'i3',
          data: {'full_name': 'An X', 'user_name': 'an_x', 'email': 'x@x.com'},
        );
        expect(li!.provider, SocialProvider.twitter);
        expect(li.secondary, '@an_x');
      },
    );

    test('provider không hỗ trợ (email, apple) → null', () {
      expect(
        LinkedIdentity.fromIdentityMap(provider: 'email', identityId: 'i'),
        isNull,
      );
      expect(
        LinkedIdentity.fromIdentityMap(provider: 'apple', identityId: 'i'),
        isNull,
      );
    });
  });

  group('LoginMethods.fromJson', () {
    test('email tổng hợp bị coi là chưa có email và chưa xác minh', () {
      final m = LoginMethods.fromJson({
        'has_password': true,
        'email': 'abc@noemail.coinsort.app',
        'email_confirmed': true,
        'pending_email': null,
        'is_synthetic_email': false, // RPC cũ chưa gắn cờ vẫn phải nhận ra
      }, identities: const []);
      expect(m.hasEmail, isFalse);
      expect(m.email, isNull);
      expect(m.emailConfirmed, isFalse);
      expect(m.hasPassword, isTrue);
    });

    test('email thật giữ nguyên trạng thái xác minh + email chờ', () {
      final m = LoginMethods.fromJson({
        'has_password': false,
        'email': 'an@gmail.com',
        'email_confirmed': true,
        'pending_email': 'moi@gmail.com',
      }, identities: const []);
      expect(m.hasEmail, isTrue);
      expect(m.emailConfirmed, isTrue);
      expect(m.pendingEmail, 'moi@gmail.com');
    });

    test('thiếu trường → mặc định an toàn (false/null)', () {
      final m = LoginMethods.fromJson(const {}, identities: const []);
      expect(m.hasPassword, isFalse);
      expect(m.hasEmail, isFalse);
      expect(m.emailConfirmed, isFalse);
      expect(m.pendingEmail, isNull);
    });
  });

  group('LoginMethods.canUnlink', () {
    const google = LinkedIdentity(
      provider: SocialProvider.google,
      identityId: 'g',
    );
    const facebook = LinkedIdentity(
      provider: SocialProvider.facebook,
      identityId: 'f',
    );

    test('không mật khẩu + một identity duy nhất → KHÔNG gỡ được', () {
      const m = LoginMethods(
        hasPassword: false,
        email: null,
        emailConfirmed: false,
        pendingEmail: null,
        identities: [google],
      );
      expect(m.canUnlink(google), isFalse);
    });

    test('có mật khẩu → gỡ được identity cuối', () {
      const m = LoginMethods(
        hasPassword: true,
        email: null,
        emailConfirmed: false,
        pendingEmail: null,
        identities: [google],
      );
      expect(m.canUnlink(google), isTrue);
    });

    test('hai identity → gỡ một cái được', () {
      const m = LoginMethods(
        hasPassword: false,
        email: null,
        emailConfirmed: false,
        pendingEmail: null,
        identities: [google, facebook],
      );
      expect(m.canUnlink(google), isTrue);
      expect(m.identityFor(SocialProvider.facebook), same(facebook));
      expect(m.identityFor(SocialProvider.twitter), isNull);
    });
  });
}
