import '../l10n/l10n.dart';
import '../result.dart';
import 'app_exception.dart';
import 'error_mapper.dart';

/// Tra bản dịch cho [AppException] theo [AppErrorCode].
///
/// Lỗi không có code (thông điệp tự do từ RPC P0001, lỗi máy chủ có nội dung)
/// rơi về `message` — chuỗi do máy chủ soạn, client không dịch được.
extension AppExceptionL10n on AppException {
  String localizedMessage(AppLocalizations l10n) {
    return switch (code) {
      null => message,
      AppErrorCode.network => l10n.errNetwork,
      AppErrorCode.unknown => l10n.errUnknown,
      AppErrorCode.serverError => l10n.errServerError,
      AppErrorCode.serverNotSetup => l10n.errServerNotSetup,
      AppErrorCode.sessionExpired => l10n.errSessionExpired,
      AppErrorCode.permissionDenied => l10n.errPermissionDenied,
      AppErrorCode.notFound => l10n.errNotFound,
      AppErrorCode.duplicate => l10n.errDuplicate,
      AppErrorCode.invalidReference => l10n.errInvalidReference,
      AppErrorCode.invalidData => l10n.errInvalidData,
      AppErrorCode.invalidCredentials => l10n.errInvalidCredentials,
      AppErrorCode.emailNotConfirmed => l10n.errEmailNotConfirmed,
      AppErrorCode.emailAlreadyRegistered => l10n.errEmailAlreadyRegistered,
      AppErrorCode.codeExpired => l10n.errCodeExpired,
      AppErrorCode.rateLimited => l10n.errRateLimited,
      AppErrorCode.passwordTooShort => l10n.errPasswordTooShort,
      AppErrorCode.notLoggedIn => l10n.errNotLoggedIn,
      AppErrorCode.imageTooLarge => l10n.errImageTooLarge,
      AppErrorCode.groupNameEmpty => l10n.errGroupNameEmpty,
      AppErrorCode.groupCreateFailed => l10n.errGroupCreateFailed,
      AppErrorCode.categoryNameEmpty => l10n.errCategoryNameEmpty,
      AppErrorCode.nothingToSave => l10n.errNothingToSave,
      AppErrorCode.balanceUnchanged => l10n.errBalanceUnchanged,
      AppErrorCode.budgetAmountInvalid => l10n.errBudgetAmountInvalid,
      AppErrorCode.amountInvalid => l10n.errAmountInvalid,
      AppErrorCode.loginIdentifierEmpty => l10n.errLoginIdentifierEmpty,
      AppErrorCode.usernameNotFound => l10n.errUsernameNotFound,
      AppErrorCode.registerConfirmEmail => l10n.errRegisterConfirmEmail,
      AppErrorCode.profileLoadFailed => l10n.errProfileLoadFailed,
      AppErrorCode.deleteTransactionDenied => l10n.errDeleteTransactionDenied,
      AppErrorCode.transactionNotReturned => l10n.errTransactionNotReturned,
      AppErrorCode.shareUnsupported => l10n.errShareUnsupported,
      AppErrorCode.usernameTaken => l10n.errUsernameTaken,
      AppErrorCode.usernameInvalid => l10n.errUsernameInvalid,
      AppErrorCode.identityAlreadyLinked => l10n.errIdentityAlreadyLinked,
      AppErrorCode.lastLoginMethod => l10n.errLastLoginMethod,
      AppErrorCode.manualLinkingDisabled => l10n.errManualLinkingDisabled,
      AppErrorCode.emailExists => l10n.errEmailExists,
      AppErrorCode.oauthCancelled => l10n.errOauthCancelled,
      AppErrorCode.googleNotConfigured => l10n.errGoogleNotConfigured,
      AppErrorCode.oauthFailed => l10n.errOauthFailed,
      AppErrorCode.currentPasswordWrong => l10n.errCurrentPasswordWrong,
      AppErrorCode.providerTokenMissing => l10n.errProviderTokenMissing,
      AppErrorCode.providerDisabled => l10n.errProviderDisabled,
      AppErrorCode.usernameRequiredForPassword =>
        l10n.errUsernameRequiredForPassword,
    };
  }
}

/// Chuẩn hoá lỗi bất kỳ (kể cả lỗi thô chưa map) về chuỗi hiển thị đã dịch.
String localizedError(AppLocalizations l10n, Object error) {
  final e = error is AppException ? error : mapError(error);
  return e.localizedMessage(l10n);
}

/// Bản dịch của thông điệp lỗi trong [Result], null nếu thành công.
extension ResultL10n<T> on Result<T> {
  String? localizedErrorOrNull(AppLocalizations l10n) =>
      exceptionOrNull?.localizedMessage(l10n);
}
