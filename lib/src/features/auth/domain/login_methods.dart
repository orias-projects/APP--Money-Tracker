import 'social_provider.dart';

/// Email tổng hợp gán cho tài khoản đăng ký chỉ bằng username.
///
/// GoTrue bắt buộc phải có email; địa chỉ này KHÔNG bao giờ được gửi thư và
/// được coi là "chưa có email" ở mọi nơi trong UI (RPC `get_my_login_methods`
/// cũng lọc theo hậu tố này).
const kSyntheticEmailDomain = 'noemail.coinsort.app';

String syntheticEmailFor(String username) =>
    '${username.trim().toLowerCase()}@$kSyntheticEmailDomain';

bool isSyntheticEmail(String? email) =>
    email != null && email.toLowerCase().endsWith('@$kSyntheticEmailDomain');

/// Quy tắc username dùng chung client/server (`update_my_username`).
final kUsernamePattern = RegExp(r'^[a-z0-9_.]{3,30}$');

bool isValidUsername(String value) => kUsernamePattern.hasMatch(value);

/// Một tài khoản ngoài (Google/Facebook/X) đã liên kết với người dùng.
class LinkedIdentity {
  const LinkedIdentity({
    required this.provider,
    required this.identityId,
    this.displayName,
    this.secondary,
  });

  final SocialProvider provider;

  /// `auth.identities.id` — cần khi gỡ liên kết.
  final String identityId;

  /// Tên hiển thị ở provider (Google name, Facebook name, X name).
  final String? displayName;

  /// Thông tin phụ: email (Google/Facebook) hoặc @handle (X).
  final String? secondary;

  /// Dựng từ `identity_data` GoTrue trả về. Mỗi provider đặt tên khoá khác
  /// nhau nên dò theo thứ tự ưu tiên.
  static LinkedIdentity? fromIdentityMap({
    required String provider,
    required String identityId,
    Map<String, dynamic>? data,
  }) {
    final p = SocialProvider.fromId(provider);
    if (p == null) return null;
    final d = data ?? const <String, dynamic>{};
    String? pick(List<String> keys) {
      for (final k in keys) {
        final v = d[k];
        if (v is String && v.trim().isNotEmpty) return v.trim();
      }
      return null;
    }

    final name = pick(['full_name', 'name', 'user_name', 'preferred_username']);
    final handle = pick(['user_name', 'preferred_username']);
    final email = pick(['email']);
    return LinkedIdentity(
      provider: p,
      identityId: identityId,
      displayName: name,
      secondary: p == SocialProvider.twitter && handle != null
          ? '@$handle'
          : email,
    );
  }
}

/// Toàn bộ cách đăng nhập hiện có của người dùng — nguồn dữ liệu cho màn
/// Tài khoản. Ghép từ RPC `get_my_login_methods` và `auth.identities`.
class LoginMethods {
  const LoginMethods({
    required this.hasPassword,
    required this.email,
    required this.emailConfirmed,
    required this.pendingEmail,
    required this.identities,
  });

  /// Đã đặt mật khẩu (đăng ký thường hoặc tự đặt sau khi vào bằng OAuth).
  final bool hasPassword;

  /// Email thật (null nếu chưa có hoặc chỉ có email tổng hợp).
  final String? email;
  final bool emailConfirmed;

  /// Email mới đang chờ bấm link xác minh.
  final String? pendingEmail;

  final List<LinkedIdentity> identities;

  bool get hasEmail => email != null && email!.isNotEmpty;

  LinkedIdentity? identityFor(SocialProvider provider) {
    for (final i in identities) {
      if (i.provider == provider) return i;
    }
    return null;
  }

  /// Gỡ liên kết chỉ an toàn khi còn ít nhất một cách đăng nhập khác;
  /// GoTrue cũng từ chối (`single_identity_not_deletable`) nhưng chặn sớm ở
  /// UI cho rõ ràng.
  bool canUnlink(LinkedIdentity identity) =>
      hasPassword || identities.where((i) => i != identity).isNotEmpty;

  factory LoginMethods.fromJson(
    Map<String, dynamic> json, {
    required List<LinkedIdentity> identities,
  }) {
    final rawEmail = json['email'] as String?;
    final synthetic =
        (json['is_synthetic_email'] as bool? ?? false) ||
        isSyntheticEmail(rawEmail);
    return LoginMethods(
      hasPassword: json['has_password'] as bool? ?? false,
      email: synthetic ? null : rawEmail,
      emailConfirmed: !synthetic && (json['email_confirmed'] as bool? ?? false),
      pendingEmail: json['pending_email'] as String?,
      identities: identities,
    );
  }

  static const empty = LoginMethods(
    hasPassword: false,
    email: null,
    emailConfirmed: false,
    pendingEmail: null,
    identities: [],
  );
}
