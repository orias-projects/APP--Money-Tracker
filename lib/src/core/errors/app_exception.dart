/// Lỗi đã được dịch sang thông điệp người dùng đọc được.
///
/// Mọi lỗi từ tầng data đều được gói lại thành [AppException] trước khi ném lên
/// UI, để màn hình chỉ việc hiển thị [message] mà không phải đoán nghĩa của
/// chuỗi lỗi thô từ Postgrest.
class AppException implements Exception {
  const AppException(
    this.message, {
    this.kind = AppErrorKind.unknown,
    this.code,
    this.cause,
  });

  /// Thông điệp tiếng Việt — CHỈ là fallback khi [code] null (thông điệp do
  /// máy chủ sinh ra, không dịch được phía client). UI hiển thị bản dịch qua
  /// `AppExceptionL10n.localizedMessage` trong `error_l10n.dart`.
  final String message;

  final AppErrorKind kind;

  /// Mã lỗi để tầng hiển thị tra chuỗi dịch tương ứng (vi/en).
  final AppErrorCode? code;

  /// Lỗi gốc, giữ lại để log/Sentry. Không hiển thị.
  final Object? cause;

  bool get isNetwork => kind == AppErrorKind.network;
  bool get isAuth => kind == AppErrorKind.auth;
  bool get isPermission => kind == AppErrorKind.permission;

  @override
  String toString() => message;
}

enum AppErrorKind {
  /// Mất mạng, DNS hỏng, server không phản hồi.
  network,

  /// Chưa đăng nhập, token hết hạn, sai mật khẩu.
  auth,

  /// RLS chặn, không đủ quyền (403).
  permission,

  /// Dữ liệu không hợp lệ (ràng buộc DB, check constraint).
  validation,

  /// Không tìm thấy bản ghi.
  notFound,

  /// Chưa phân loại.
  unknown,
}

/// Mã lỗi có bản dịch trong ARB (key = `err` + tên viết hoa chữ đầu).
///
/// Chỉ thêm code cho lỗi SINH RA Ở CLIENT hoặc nhận diện được từ mã lỗi
/// Postgrest/Auth. Thông điệp tự do từ RPC (P0001) giữ nguyên qua `message`.
enum AppErrorCode {
  network,
  unknown,
  serverError,
  serverNotSetup,
  sessionExpired,
  permissionDenied,
  notFound,
  duplicate,
  invalidReference,
  invalidData,
  invalidCredentials,
  emailNotConfirmed,
  emailAlreadyRegistered,
  codeExpired,
  rateLimited,
  passwordTooShort,
  notLoggedIn,
  imageTooLarge,
  groupNameEmpty,
  groupCreateFailed,
  categoryNameEmpty,
  nothingToSave,
  balanceUnchanged,
  budgetAmountInvalid,
  amountInvalid,
  loginIdentifierEmpty,
  usernameNotFound,
  registerConfirmEmail,
  profileLoadFailed,
  deleteTransactionDenied,
  transactionNotReturned,
  shareUnsupported,

  // --- Đăng nhập mạng xã hội / màn Tài khoản (migration 008) ---
  usernameTaken,
  usernameInvalid,
  identityAlreadyLinked,
  lastLoginMethod,
  manualLinkingDisabled,
  emailExists,
  oauthCancelled,
  googleNotConfigured,
  oauthFailed,
  currentPasswordWrong,
  providerTokenMissing,

  /// Provider bị tắt trong bản phát hành — xem `SocialProvider.enabled`.
  providerDisabled,
  usernameRequiredForPassword,
}
