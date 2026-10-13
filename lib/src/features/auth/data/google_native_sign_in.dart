import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/config/oauth_config.dart';
import '../../../core/errors/app_exception.dart';

/// Token Google trả về sau khi người dùng chọn tài khoản trong sheet hệ thống.
class GoogleNativeTokens {
  const GoogleNativeTokens({required this.idToken, this.accessToken});

  final String idToken;

  /// Cần khi id_token có claim `at_hash` — Supabase đối chiếu hash.
  final String? accessToken;
}

/// Lớp mỏng bọc `google_sign_in` để repository test được bằng mock.
abstract class GoogleNativeSignIn {
  /// Có Web client ID trong `.env` — không có thì bỏ qua native, dùng trình duyệt.
  bool get isConfigured;

  /// Mở sheet chọn tài khoản Google (Credential Manager). Ném [AppException]
  /// với code `oauthCancelled` / `googleNotConfigured` / `oauthFailed`.
  Future<GoogleNativeTokens> authenticate();

  /// Quên tài khoản đã chọn để lần sau sheet hỏi lại — gọi khi đăng xuất.
  Future<void> signOut();
}

class GoogleNativeSignInImpl implements GoogleNativeSignIn {
  bool _initialized = false;

  static const _scopes = <String>['email', 'profile'];

  @override
  bool get isConfigured => OAuthConfig.hasGoogleNative;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await GoogleSignIn.instance.initialize(
      serverClientId: OAuthConfig.googleWebClientId,
    );
    _initialized = true;
  }

  @override
  Future<GoogleNativeTokens> authenticate() async {
    if (!isConfigured) throw _notConfigured();
    try {
      await _ensureInitialized();
      if (!GoogleSignIn.instance.supportsAuthenticate()) throw _notConfigured();

      final account = await GoogleSignIn.instance.authenticate(
        scopeHint: _scopes,
      );
      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw const AppException(
          'Google không trả về id_token.',
          kind: AppErrorKind.auth,
          code: AppErrorCode.oauthFailed,
        );
      }

      // Theo hướng dẫn Supabase cho google_sign_in 7: xin access token cho các
      // scope cơ bản để máy chủ đối chiếu at_hash. Không lấy được thì vẫn
      // thử đăng nhập chỉ với id_token.
      String? accessToken;
      try {
        final auth =
            await account.authorizationClient.authorizationForScopes(_scopes) ??
            await account.authorizationClient.authorizeScopes(_scopes);
        accessToken = auth.accessToken;
      } on GoogleSignInException {
        accessToken = null;
      }

      return GoogleNativeTokens(idToken: idToken, accessToken: accessToken);
    } on GoogleSignInException catch (e) {
      throw switch (e.code) {
        GoogleSignInExceptionCode.canceled => const AppException(
          'Bạn đã huỷ đăng nhập.',
          kind: AppErrorKind.auth,
          code: AppErrorCode.oauthCancelled,
        ),
        GoogleSignInExceptionCode.clientConfigurationError ||
        GoogleSignInExceptionCode.providerConfigurationError => _notConfigured(
          e,
        ),
        _ => AppException(
          'Không đăng nhập được bằng Google. Thử lại sau.',
          kind: AppErrorKind.auth,
          code: AppErrorCode.oauthFailed,
          cause: e,
        ),
      };
    }
  }

  @override
  Future<void> signOut() async {
    if (!_initialized) return;
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {
      // Không có gì để người dùng làm; lần sau sheet chỉ đơn giản nhớ tài khoản.
    }
  }

  static AppException _notConfigured([Object? cause]) => AppException(
    'Bản dựng này chưa được cấu hình đăng nhập Google.',
    kind: AppErrorKind.auth,
    code: AppErrorCode.googleNotConfigured,
    cause: cause,
  );
}
