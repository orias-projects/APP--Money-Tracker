import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/oauth_config.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/result.dart';
import '../domain/app_user.dart';
import '../domain/login_methods.dart';
import '../domain/social_provider.dart';
import 'google_native_sign_in.dart';

/// Kết quả một lần bấm nút mạng xã hội.
enum SocialSignInOutcome {
  /// Đã có phiên ngay (Google native) — điều hướng luôn.
  signedIn,

  /// Đã mở trình duyệt; phiên sẽ về qua deep link `coinsort://login-callback`
  /// và phát trên [AuthRepository.onAuthStateChange] — màn hình chờ sự kiện đó.
  browserLaunched,
}

class AuthRepository {
  AuthRepository(this._client, {GoogleNativeSignIn? google})
    : _google = google ?? GoogleNativeSignInImpl();

  final SupabaseClient _client;
  final GoogleNativeSignIn _google;

  User? get currentAuthUser => _client.auth.currentUser;

  Session? get currentSession => _client.auth.currentSession;

  bool get isSignedIn => _client.auth.currentSession != null;

  /// Luồng trạng thái đăng nhập — router lắng nghe để chuyển màn khi token hết
  /// hạn hoặc người dùng đăng xuất ở thiết bị khác.
  Stream<AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;

  // ---------------------------------------------------------------------------
  // Đăng nhập / Đăng ký
  // ---------------------------------------------------------------------------

  Future<Result<AppUser>> signInWithEmail({
    required String email,
    required String password,
  }) {
    return Result.guard(() async {
      await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      return _requireProfile();
    });
  }

  /// Đăng nhập bằng email HOẶC tên đăng nhập.
  /// Không chứa '@' → tra email qua RPC get_email_for_login.
  Future<Result<AppUser>> signInWithEmailOrUsername({
    required String identifier,
    required String password,
  }) {
    return Result.guard(() async {
      final trimmed = identifier.trim();
      if (trimmed.isEmpty) {
        throw const AppException(
          'Nhập email hoặc tên đăng nhập.',
          kind: AppErrorKind.validation,
          code: AppErrorCode.loginIdentifierEmpty,
        );
      }

      var email = trimmed;
      if (!trimmed.contains('@')) {
        final res = await _client.rpc(
          'get_email_for_login',
          params: {'login_id': trimmed},
        );
        final resolved = _firstString(res);
        if (resolved == null || resolved.isEmpty) {
          throw const AppException(
            'Không tìm thấy tài khoản với tên đăng nhập này.',
            kind: AppErrorKind.notFound,
            code: AppErrorCode.usernameNotFound,
          );
        }
        email = resolved;
      }

      await _client.auth.signInWithPassword(email: email, password: password);
      return _requireProfile();
    });
  }

  /// Đăng ký chỉ với tên đăng nhập + mật khẩu.
  ///
  /// GoTrue bắt buộc có email nên dùng email TỔNG HỢP `<username>@noemail…`
  /// (xem [kSyntheticEmailDomain]); người dùng thêm email thật sau trong màn
  /// Tài khoản. Yêu cầu Dashboard tắt "Confirm email" — nếu không phiên sẽ
  /// không về và ta báo [AppErrorCode.registerConfirmEmail].
  Future<Result<AppUser>> signUpWithUsername({
    required String username,
    required String password,
  }) {
    return Result.guard(() async {
      final name = username.trim().toLowerCase();
      if (!isValidUsername(name)) {
        throw const AppException(
          'Tên đăng nhập gồm 3–30 ký tự: chữ thường, số, dấu chấm hoặc gạch dưới.',
          kind: AppErrorKind.validation,
          code: AppErrorCode.usernameInvalid,
        );
      }
      _requirePasswordLength(password);

      final email = syntheticEmailFor(name);
      try {
        await _client.auth.signUp(
          email: email,
          password: password,
          data: {'username': name},
        );
      } on AuthException catch (e) {
        // Email tổng hợp suy ra từ username → trùng email nghĩa là trùng username.
        if (e.code == 'user_already_exists' ||
            e.message.toLowerCase().contains('already registered')) {
          throw AppException(
            'Tên đăng nhập này đã có người dùng.',
            kind: AppErrorKind.validation,
            code: AppErrorCode.usernameTaken,
            cause: e,
          );
        }
        rethrow;
      }

      if (_client.auth.currentSession == null) {
        await _client.auth.signInWithPassword(email: email, password: password);
      }
      if (_client.auth.currentSession == null) {
        throw const AppException(
          'Đăng ký thành công. Kiểm tra email để xác nhận rồi đăng nhập.',
          kind: AppErrorKind.auth,
          code: AppErrorCode.registerConfirmEmail,
        );
      }
      return _requireProfile();
    });
  }

  /// Đăng nhập bằng Google / Facebook / X.
  ///
  /// Google: native (sheet hệ thống) khi có Web client ID; lỗi cấu hình thì tự
  /// rơi về trình duyệt. Facebook/X: luôn trình duyệt (GoTrue không nhận
  /// id_token của hai provider này trên Android).
  Future<Result<SocialSignInOutcome>> signInWithSocial(
    SocialProvider provider,
  ) {
    return Result.guard(() async {
      _assertProviderEnabled(provider);
      if (provider == SocialProvider.google && _google.isConfigured) {
        try {
          final tokens = await _google.authenticate();
          await _client.auth.signInWithIdToken(
            provider: OAuthProvider.google,
            idToken: tokens.idToken,
            accessToken: tokens.accessToken,
          );
          return SocialSignInOutcome.signedIn;
        } on AppException catch (e) {
          // Huỷ là ý người dùng — đừng tự mở tiếp trình duyệt.
          if (e.code == AppErrorCode.oauthCancelled) rethrow;
          // Mọi lỗi native còn lại đều còn đường trình duyệt: thiếu Android
          // OAuth client cho SHA-1 của bản dựng (Credential Manager trả
          // `noCredential`, plugin đổi thành `unknownError` — KHÔNG phải
          // `clientConfigurationError`), máy thiếu Play Services, chưa có tài
          // khoản Google nào trên máy… Native chỉ là đường tắt; hỏng thì đi
          // đường vòng chứ đừng chặn người dùng lại.
        }
      }
      await _launchOAuth(provider);
      return SocialSignInOutcome.browserLaunched;
    });
  }

  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (_) {
      // Đăng xuất cục bộ vẫn coi như thành công dù server không phản hồi.
    }
    await _google.signOut();
  }

  // ---------------------------------------------------------------------------
  // Liên kết tài khoản ngoài
  // ---------------------------------------------------------------------------

  /// Mở trình duyệt để liên kết thêm một provider vào tài khoản hiện tại.
  /// Kết quả về qua deep link; gọi [getLoginMethods] sau sự kiện `userUpdated`.
  /// Cần bật "Enable manual linking" trong Supabase Dashboard.
  Future<Result<void>> linkProvider(SocialProvider provider) {
    return Result.guard(() {
      _assertProviderEnabled(provider);
      return _launchOAuth(provider, link: true);
    });
  }

  /// Chặn mọi lối vào của provider đang tắt.
  ///
  /// UI đã ẩn nút, nhưng nguồn sự thật là [SocialProvider.enabled] — giữ chốt ở
  /// đây thì một màn hình quên kiểm tra cũng không mở được luồng OAuth tới
  /// provider chưa cấu hình (người dùng sẽ chỉ nhận lỗi khó hiểu của GoTrue).
  static void _assertProviderEnabled(SocialProvider provider) {
    if (provider.isEnabled) return;
    throw const AppException(
      'Cách đăng nhập này đang tạm ngưng.',
      kind: AppErrorKind.auth,
      code: AppErrorCode.providerDisabled,
    );
  }

  Future<Result<void>> unlinkProvider(LinkedIdentity identity) {
    return Result.guard(() async {
      final identities = await _client.auth.getUserIdentities();
      UserIdentity? target;
      for (final i in identities) {
        if (i.identityId == identity.identityId) {
          target = i;
          break;
        }
      }
      if (target == null) {
        throw const AppException(
          'Liên kết này không còn tồn tại.',
          kind: AppErrorKind.notFound,
          code: AppErrorCode.notFound,
        );
      }
      await _client.auth.unlinkIdentity(target);
      await refreshUser();
    });
  }

  Future<void> _launchOAuth(
    SocialProvider provider, {
    bool link = false,
  }) async {
    final oauth = _oauthProviderOf(provider);
    final scopes = _scopesFor(provider);
    final launched = link
        ? await _client.auth.linkIdentity(
            oauth,
            redirectTo: kAuthRedirectUrl,
            scopes: scopes,
            authScreenLaunchMode: LaunchMode.externalApplication,
          )
        : await _client.auth.signInWithOAuth(
            oauth,
            redirectTo: kAuthRedirectUrl,
            scopes: scopes,
            authScreenLaunchMode: LaunchMode.externalApplication,
          );
    if (!launched) {
      throw const AppException(
        'Không mở được trình duyệt để đăng nhập.',
        kind: AppErrorKind.unknown,
        code: AppErrorCode.oauthFailed,
      );
    }
  }

  static OAuthProvider _oauthProviderOf(SocialProvider p) => switch (p) {
    SocialProvider.google => OAuthProvider.google,
    SocialProvider.facebook => OAuthProvider.facebook,
    // GoTrue chưa có hằng cho provider OAuth2 mới của X.
    SocialProvider.twitter => const OAuthProvider('x'),
  };

  /// Facebook: xin thêm `user_friends` để gợi ý bạn bè (Graph API chỉ trả
  /// bạn cũng dùng app). Provider khác dùng scope mặc định của Supabase.
  static String? _scopesFor(SocialProvider p) => switch (p) {
    SocialProvider.facebook => 'email,public_profile,user_friends',
    _ => null,
  };

  // ---------------------------------------------------------------------------
  // Cách đăng nhập / email / mật khẩu / username
  // ---------------------------------------------------------------------------

  /// Tải lại user từ máy chủ (identities, email, email đang chờ). Không ném lỗi
  /// — thất bại thì giữ bản đang cache.
  Future<void> refreshUser() async {
    try {
      await _client.auth.getUser();
    } catch (_) {}
  }

  Future<LoginMethods> getLoginMethods() async {
    try {
      User? user;
      try {
        user = (await _client.auth.getUser()).user;
      } catch (_) {
        user = _client.auth.currentUser;
      }
      final res = await _client.rpc('get_my_login_methods');
      final map = res is Map
          ? Map<String, dynamic>.from(res)
          : <String, dynamic>{};

      final identities = <LinkedIdentity>[];
      for (final i in user?.identities ?? const <UserIdentity>[]) {
        final linked = LinkedIdentity.fromIdentityMap(
          provider: i.provider,
          identityId: i.identityId,
          data: i.identityData,
        );
        if (linked != null) identities.add(linked);
      }
      return LoginMethods.fromJson(map, identities: identities);
    } catch (e, st) {
      throw mapError(e, st);
    }
  }

  /// Thêm/đổi email. GoTrue gửi link xác minh tới địa chỉ MỚI (Dashboard phải
  /// tắt "Secure email change" vì email tổng hợp cũ không nhận được thư).
  Future<Result<void>> updateEmail(String newEmail) {
    return Result.guard(() async {
      final email = newEmail.trim().toLowerCase();
      if (email.isEmpty || !email.contains('@') || isSyntheticEmail(email)) {
        throw const AppException(
          'Email không hợp lệ.',
          kind: AppErrorKind.validation,
          code: AppErrorCode.invalidData,
        );
      }
      await _client.auth.updateUser(
        UserAttributes(email: email),
        emailRedirectTo: kAuthRedirectUrl,
      );
    });
  }

  Future<Result<void>> resendEmailChange(String pendingEmail) {
    return Result.guard(() async {
      await _client.auth.resend(
        type: OtpType.emailChange,
        email: pendingEmail.trim(),
        emailRedirectTo: kAuthRedirectUrl,
      );
    });
  }

  /// Đổi mật khẩu (đã có) hoặc đặt mật khẩu lần đầu (tài khoản OAuth).
  ///
  /// Đã có mật khẩu → bắt buộc [currentPassword], kiểm chứng bằng cách đăng
  /// nhập lại. Chưa có → phải có username hoặc email thật, nếu không mật khẩu
  /// vô dụng vì không có gì để đăng nhập kèm.
  Future<Result<void>> changePassword({
    required String newPassword,
    String? currentPassword,
  }) {
    return Result.guard(() async {
      _requirePasswordLength(newPassword);
      final methods = await getLoginMethods();

      if (methods.hasPassword) {
        final authEmail = _client.auth.currentUser?.email;
        if (authEmail == null || authEmail.isEmpty) {
          throw const AppException(
            'Chưa đăng nhập.',
            kind: AppErrorKind.auth,
            code: AppErrorCode.notLoggedIn,
          );
        }
        if (currentPassword == null || currentPassword.isEmpty) {
          throw _wrongCurrentPassword();
        }
        try {
          await _client.auth.signInWithPassword(
            email: authEmail,
            password: currentPassword,
          );
        } on AuthException catch (e) {
          throw _wrongCurrentPassword(e);
        }
      } else {
        final profile = await getProfile();
        final hasUsername = (profile?.username ?? '').trim().isNotEmpty;
        if (!hasUsername && !methods.hasEmail) {
          throw const AppException(
            'Hãy đặt tên đăng nhập hoặc thêm email trước để có thể đăng nhập bằng mật khẩu.',
            kind: AppErrorKind.validation,
            code: AppErrorCode.usernameRequiredForPassword,
          );
        }
      }

      await _client.auth.updateUser(UserAttributes(password: newPassword));
    });
  }

  Future<Result<void>> updateUsername(String username) {
    return Result.guard(() async {
      final name = username.trim().toLowerCase();
      if (!isValidUsername(name)) {
        throw const AppException(
          'Tên đăng nhập gồm 3–30 ký tự: chữ thường, số, dấu chấm hoặc gạch dưới.',
          kind: AppErrorKind.validation,
          code: AppErrorCode.usernameInvalid,
        );
      }
      await _client.rpc('update_my_username', params: {'p_username': name});
    });
  }

  // ---------------------------------------------------------------------------
  // Khôi phục mật khẩu
  // ---------------------------------------------------------------------------

  Future<Result<void>> requestPasswordReset(String email) {
    return Result.guard(() async {
      await _client.auth.resetPasswordForEmail(email.trim());
    });
  }

  Future<Result<void>> verifyRecoveryOtp({
    required String email,
    required String token,
  }) {
    return Result.guard(() async {
      await _client.auth.verifyOTP(
        type: OtpType.recovery,
        token: token.trim(),
        email: email.trim(),
      );
    });
  }

  Future<Result<void>> updatePassword(String newPassword) {
    return Result.guard(() async {
      _requirePasswordLength(newPassword);
      await _client.auth.updateUser(UserAttributes(password: newPassword));
    });
  }

  // ---------------------------------------------------------------------------
  // Hồ sơ
  // ---------------------------------------------------------------------------

  Future<AppUser?> getProfile() async {
    final authUser = _client.auth.currentUser;
    if (authUser == null) return null;
    try {
      final res = await _client
          .from('users')
          .select()
          .eq('id', authUser.id)
          .maybeSingle();
      if (res != null) return AppUser.fromMap(res);
    } catch (_) {
      // Hàng users chưa kịp tạo (trigger chạy sau) — dùng metadata tạm.
    }
    return _appUserFromAuthUser(authUser);
  }

  Future<Result<void>> updateProfile({String? fullName}) {
    return Result.guard(() async {
      final uid = _client.auth.currentUser?.id;
      if (uid == null) {
        throw const AppException(
          'Chưa đăng nhập.',
          kind: AppErrorKind.auth,
          code: AppErrorCode.notLoggedIn,
        );
      }
      await _client
          .from('users')
          .update({'full_name': fullName?.trim()})
          .eq('id', uid);
    });
  }

  Future<Result<void>> updateAvatar(String? url) {
    return Result.guard(() async {
      final res = await _client.rpc('update_my_avatar', params: {'p_url': url});
      final msg = res?.toString().trim() ?? '';
      if (msg.isNotEmpty) {
        throw AppException(msg, kind: AppErrorKind.validation);
      }
    });
  }

  /// Người dùng tự xoá tài khoản — bắt buộc phải có theo yêu cầu của
  /// Google Play và App Store.
  Future<Result<void>> deleteAccount(String confirmPhrase) {
    return Result.guard(() async {
      final res = await _client.rpc(
        'delete_my_account',
        params: {'p_confirm': confirmPhrase},
      );
      final msg = res?.toString().trim() ?? '';
      if (msg.isNotEmpty) {
        throw AppException(msg, kind: AppErrorKind.validation);
      }
    });
  }

  // ---------------------------------------------------------------------------

  Future<AppUser> _requireProfile() async {
    final profile = await getProfile();
    if (profile != null) return profile;
    throw const AppException(
      'Đăng nhập thành công nhưng không lấy được hồ sơ. Thử lại sau ít phút.',
      kind: AppErrorKind.unknown,
      code: AppErrorCode.profileLoadFailed,
    );
  }

  static void _requirePasswordLength(String password) {
    if (password.length < 6) {
      throw const AppException(
        'Mật khẩu cần ít nhất 6 ký tự.',
        kind: AppErrorKind.validation,
        code: AppErrorCode.passwordTooShort,
      );
    }
  }

  static AppException _wrongCurrentPassword([Object? cause]) => AppException(
    'Mật khẩu hiện tại không đúng.',
    kind: AppErrorKind.auth,
    code: AppErrorCode.currentPasswordWrong,
    cause: cause,
  );

  static String? _firstString(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is List && value.isNotEmpty) return value.first?.toString();
    return value.toString();
  }

  static AppUser _appUserFromAuthUser(User u) {
    final meta = u.userMetadata ?? const {};
    final email = u.email;
    // Email tổng hợp không phải thông tin người dùng — không dùng làm tên.
    final fallbackName = isSyntheticEmail(email) ? null : email;
    return AppUser(
      id: u.id,
      username: meta['username'] as String?,
      fullName:
          meta['full_name'] as String? ??
          meta['name'] as String? ??
          fallbackName,
      avatarUrl: meta['avatar_url'] as String? ?? meta['picture'] as String?,
    );
  }
}
