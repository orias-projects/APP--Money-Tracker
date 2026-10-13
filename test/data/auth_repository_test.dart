import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spend_sync/src/core/errors/app_exception.dart';
import 'package:spend_sync/src/core/result.dart';
import 'package:spend_sync/src/features/auth/data/auth_repository.dart';
import 'package:spend_sync/src/features/auth/data/google_native_sign_in.dart';
import 'package:spend_sync/src/features/auth/domain/login_methods.dart';
import 'package:spend_sync/src/features/auth/domain/social_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockGoogleNativeSignIn extends Mock implements GoogleNativeSignIn {}

void main() {
  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
    registerFallbackValue(OAuthProvider.google);
    registerFallbackValue(UserAttributes());
  });

  late MockSupabaseClient client;
  late MockGoTrueClient auth;
  late MockGoogleNativeSignIn google;
  late AuthRepository repo;

  final user = User.fromJson({
    'id': 'u1',
    'app_metadata': {'provider': 'email'},
    'user_metadata': {'username': 'an.nguyen'},
    'aud': 'authenticated',
    'created_at': '2026-01-01T00:00:00Z',
  })!;
  final session = Session(accessToken: 'at', tokenType: 'bearer', user: user);

  setUp(() {
    client = MockSupabaseClient();
    auth = MockGoTrueClient();
    google = MockGoogleNativeSignIn();
    when(() => client.auth).thenReturn(auth);
    // Không có bảng users trong test → getProfile rơi về metadata của auth user.
    when(() => client.from(any())).thenThrow(Exception('no db in test'));
    repo = AuthRepository(client, google: google);
  });

  group('signUpWithUsername (đăng ký chỉ username + mật khẩu)', () {
    test('username sai quy tắc → usernameInvalid, KHÔNG gọi máy chủ', () async {
      final res = await repo.signUpWithUsername(
        username: 'An Nguyen',
        password: '123456',
      );
      expect(res.isErr, isTrue);
      expect((res as Err).error.code, AppErrorCode.usernameInvalid);
      verifyNever(
        () => auth.signUp(
          email: any(named: 'email'),
          password: any(named: 'password'),
          data: any(named: 'data'),
        ),
      );
    });

    test('mật khẩu ngắn → passwordTooShort trước khi chạm mạng', () async {
      final res = await repo.signUpWithUsername(
        username: 'an.nguyen',
        password: '123',
      );
      expect((res as Err).error.code, AppErrorCode.passwordTooShort);
      verifyNever(
        () => auth.signUp(
          email: any(named: 'email'),
          password: any(named: 'password'),
          data: any(named: 'data'),
        ),
      );
    });

    test('hợp lệ → signUp với email tổng hợp lowercase + metadata username, '
        'trả hồ sơ', () async {
      when(
        () => auth.signUp(
          email: any(named: 'email'),
          password: any(named: 'password'),
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async => AuthResponse(session: session, user: user));
      when(() => auth.currentSession).thenReturn(session);
      when(() => auth.currentUser).thenReturn(user);

      final res = await repo.signUpWithUsername(
        username: '  An.Nguyen ',
        password: 'secret1',
      );

      expect(res.isOk, isTrue, reason: (res as dynamic).toString());
      expect(res.valueOrNull!.username, 'an.nguyen');
      final captured = verify(
        () => auth.signUp(
          email: captureAny(named: 'email'),
          password: 'secret1',
          data: captureAny(named: 'data'),
        ),
      ).captured;
      expect(captured[0], 'an.nguyen@$kSyntheticEmailDomain');
      expect(captured[1], {'username': 'an.nguyen'});
    });

    test(
      'GoTrue báo user_already_exists → usernameTaken (không nói "email")',
      () async {
        when(
          () => auth.signUp(
            email: any(named: 'email'),
            password: any(named: 'password'),
            data: any(named: 'data'),
          ),
        ).thenThrow(
          const AuthException(
            'User already registered',
            code: 'user_already_exists',
          ),
        );

        final res = await repo.signUpWithUsername(
          username: 'an.nguyen',
          password: 'secret1',
        );
        expect((res as Err).error.code, AppErrorCode.usernameTaken);
      },
    );
  });

  group('signInWithSocial(google) — native', () {
    test('có token → signInWithIdToken(google) và trả signedIn', () async {
      when(() => google.isConfigured).thenReturn(true);
      when(() => google.authenticate()).thenAnswer(
        (_) async =>
            const GoogleNativeTokens(idToken: 'id.tok', accessToken: 'acc'),
      );
      when(
        () => auth.signInWithIdToken(
          provider: any(named: 'provider'),
          idToken: any(named: 'idToken'),
          accessToken: any(named: 'accessToken'),
        ),
      ).thenAnswer((_) async => AuthResponse(session: session, user: user));

      final res = await repo.signInWithSocial(SocialProvider.google);

      expect(res.valueOrNull, SocialSignInOutcome.signedIn);
      verify(
        () => auth.signInWithIdToken(
          provider: OAuthProvider.google,
          idToken: 'id.tok',
          accessToken: 'acc',
        ),
      ).called(1);
    });

    test('người dùng huỷ sheet → oauthCancelled, không gọi Supabase', () async {
      when(() => google.isConfigured).thenReturn(true);
      when(() => google.authenticate()).thenThrow(
        const AppException(
          'huỷ',
          kind: AppErrorKind.auth,
          code: AppErrorCode.oauthCancelled,
        ),
      );

      final res = await repo.signInWithSocial(SocialProvider.google);

      expect((res as Err).error.code, AppErrorCode.oauthCancelled);
      verifyNever(
        () => auth.signInWithIdToken(
          provider: any(named: 'provider'),
          idToken: any(named: 'idToken'),
          accessToken: any(named: 'accessToken'),
        ),
      );
      // Huỷ là ý người dùng — không được tự đẩy sang trình duyệt.
      verifyNever(
        () => auth.getOAuthSignInUrl(
          provider: any(named: 'provider'),
          redirectTo: any(named: 'redirectTo'),
          scopes: any(named: 'scopes'),
          queryParams: any(named: 'queryParams'),
        ),
      );
    });

    test(
      'native hỏng (thiếu Android OAuth client) → rơi về trình duyệt',
      () async {
        // Credential Manager trả `noCredential` khi SHA-1 của bản dựng chưa được
        // đăng ký; plugin đổi thành `unknownError` → wrapper đổi thành
        // oauthFailed. Trước đây lỗi này bị rethrow thẳng và người dùng kẹt lại.
        when(() => google.isConfigured).thenReturn(true);
        when(() => google.authenticate()).thenThrow(
          const AppException(
            'Không đăng nhập được bằng Google.',
            kind: AppErrorKind.auth,
            code: AppErrorCode.oauthFailed,
          ),
        );
        when(
          () => auth.getOAuthSignInUrl(
            provider: any(named: 'provider'),
            redirectTo: any(named: 'redirectTo'),
            scopes: any(named: 'scopes'),
            queryParams: any(named: 'queryParams'),
          ),
        ).thenThrow(Exception('đã thử mở trình duyệt'));

        await repo.signInWithSocial(SocialProvider.google);

        // Không mở được trình duyệt thật trong test; điều cần chứng minh là app
        // ĐÃ đi tiếp sang luồng đó thay vì dừng lại báo lỗi.
        verify(
          () => auth.getOAuthSignInUrl(
            provider: any(named: 'provider'),
            redirectTo: any(named: 'redirectTo'),
            scopes: any(named: 'scopes'),
            queryParams: any(named: 'queryParams'),
          ),
        ).called(1);
      },
    );
  });

  group('Provider bị tắt (SocialProvider.enabled)', () {
    // Facebook đang tạm tắt: đăng ký app bên Meta quá phức tạp. Nút đã ẩn khỏi
    // UI, chốt dưới đây bảo đảm không lối nào mở được luồng OAuth tới nó.
    test(
      'signInWithSocial(facebook) → providerDisabled, không chạm mạng',
      () async {
        when(() => google.isConfigured).thenReturn(true);

        final res = await repo.signInWithSocial(SocialProvider.facebook);

        expect((res as Err).error.code, AppErrorCode.providerDisabled);
        verifyZeroInteractions(auth);
        verifyNever(() => google.authenticate());
      },
    );

    test('linkProvider(facebook) → providerDisabled', () async {
      final res = await repo.linkProvider(SocialProvider.facebook);

      expect((res as Err).error.code, AppErrorCode.providerDisabled);
      verifyZeroInteractions(auth);
    });

    test('linkProvider(X) → providerDisabled', () async {
      final res = await repo.linkProvider(SocialProvider.twitter);

      expect((res as Err).error.code, AppErrorCode.providerDisabled);
      verifyZeroInteractions(auth);
    });

    test('chỉ Google đang bật', () async {
      expect(SocialProvider.google.isEnabled, isTrue);
      expect(SocialProvider.facebook.isEnabled, isFalse);
      expect(SocialProvider.twitter.isEnabled, isFalse);
    });
  });

  group('Màn Tài khoản — validate phía client trước khi gọi máy chủ', () {
    test('updateEmail: thiếu @ hoặc là email tổng hợp → invalidData', () async {
      final r1 = await repo.updateEmail('khong-phai-email');
      final r2 = await repo.updateEmail('abc@$kSyntheticEmailDomain');
      expect((r1 as Err).error.code, AppErrorCode.invalidData);
      expect((r2 as Err).error.code, AppErrorCode.invalidData);
      verifyNever(
        () => auth.updateUser(
          any(),
          emailRedirectTo: any(named: 'emailRedirectTo'),
        ),
      );
    });

    test(
      'updateEmail hợp lệ → updateUser(email lowercase) kèm redirect',
      () async {
        when(
          () => auth.updateUser(
            any(),
            emailRedirectTo: any(named: 'emailRedirectTo'),
          ),
        ).thenAnswer((_) async => UserResponse.fromJson({}));

        final res = await repo.updateEmail(' An@Gmail.com ');

        expect(res.isOk, isTrue);
        final attrs =
            verify(
                  () => auth.updateUser(
                    captureAny(),
                    emailRedirectTo: 'coinsort://login-callback/',
                  ),
                ).captured.single
                as UserAttributes;
        expect(attrs.email, 'an@gmail.com');
      },
    );

    test(
      'updateUsername sai quy tắc → usernameInvalid, không gọi RPC',
      () async {
        final res = await repo.updateUsername('AB');
        expect((res as Err).error.code, AppErrorCode.usernameInvalid);
        verifyNever(() => client.rpc(any(), params: any(named: 'params')));
      },
    );

    test(
      'changePassword: mật khẩu mới ngắn → passwordTooShort trước mọi RPC',
      () async {
        final res = await repo.changePassword(newPassword: '12');
        expect((res as Err).error.code, AppErrorCode.passwordTooShort);
        verifyNever(() => client.rpc(any()));
        verifyNever(() => auth.getUser());
      },
    );
  });
}
