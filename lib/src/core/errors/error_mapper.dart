import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_exception.dart';

/// Dịch mọi lỗi từ Supabase / mạng sang [AppException] có [AppErrorCode].
///
/// Dùng ở tầng data. Trước đây các repository nuốt lỗi bằng
/// `catch (_) { return []; }` khiến mất mạng và "không có dữ liệu" trông giống
/// hệt nhau — hàm này tồn tại để chấm dứt điều đó. `message` tiếng Việt chỉ là
/// fallback; UI tra bản dịch theo `code` (xem `error_l10n.dart`).
AppException mapError(Object error, [StackTrace? _]) {
  if (error is AppException) return error;

  if (error is SocketException ||
      error is TimeoutException ||
      error is HttpException) {
    return AppException(
      'Không kết nối được máy chủ. Kiểm tra mạng rồi thử lại.',
      kind: AppErrorKind.network,
      code: AppErrorCode.network,
      cause: error,
    );
  }

  if (error is AuthException) {
    // Ưu tiên mã lỗi chuẩn của GoTrue (error.code); message chỉ là dự phòng
    // vì nội dung có thể đổi giữa các phiên bản máy chủ.
    final resolved = _authCodeFromApi(error.code) ?? _authCode(error.message);
    return AppException(
      resolved == null ? error.message : _authFallback(resolved),
      kind: AppErrorKind.auth,
      code: resolved,
      cause: error,
    );
  }

  if (error is PostgrestException) {
    return _fromPostgrest(error);
  }

  final text = error.toString().toLowerCase();
  if (_looksLikeNetwork(text)) {
    return AppException(
      'Không kết nối được máy chủ. Kiểm tra mạng (Wi-Fi/4G) rồi thử lại.',
      kind: AppErrorKind.network,
      code: AppErrorCode.network,
      cause: error,
    );
  }

  return AppException(
    'Đã xảy ra lỗi. Thử lại sau ít phút.',
    kind: AppErrorKind.unknown,
    code: AppErrorCode.unknown,
    cause: error,
  );
}

AppException _fromPostgrest(PostgrestException e) {
  final code = e.code ?? '';
  final message = e.message;
  final lower = message.toLowerCase();

  // RLS chặn hoặc thiếu quyền
  if (code == '42501' ||
      code == '403' ||
      lower.contains('row-level security') ||
      lower.contains('permission denied') ||
      lower.contains('forbidden')) {
    return AppException(
      'Bạn không có quyền thực hiện thao tác này.',
      kind: AppErrorKind.permission,
      code: AppErrorCode.permissionDenied,
      cause: e,
    );
  }

  // JWT hết hạn
  if (code == 'PGRST301' ||
      lower.contains('jwt expired') ||
      lower.contains('invalid token')) {
    return AppException(
      'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
      kind: AppErrorKind.auth,
      code: AppErrorCode.sessionExpired,
      cause: e,
    );
  }

  // Không tìm thấy bản ghi (maybeSingle/single không có kết quả)
  if (code == 'PGRST116') {
    return AppException(
      'Không tìm thấy dữ liệu.',
      kind: AppErrorKind.notFound,
      code: AppErrorCode.notFound,
      cause: e,
    );
  }

  // Trùng khoá
  if (code == '23505' || lower.contains('duplicate key')) {
    return AppException(
      'Dữ liệu này đã tồn tại.',
      kind: AppErrorKind.validation,
      code: AppErrorCode.duplicate,
      cause: e,
    );
  }

  // Vi phạm khoá ngoại
  if (code == '23503') {
    return AppException(
      'Dữ liệu liên kết không hợp lệ hoặc đã bị xoá.',
      kind: AppErrorKind.validation,
      code: AppErrorCode.invalidReference,
      cause: e,
    );
  }

  // Ràng buộc check (amount > 0, split_mode, account_type…)
  if (code == '23514') {
    return AppException(
      'Dữ liệu không hợp lệ. Kiểm tra lại số tiền và các trường bắt buộc.',
      kind: AppErrorKind.validation,
      code: AppErrorCode.invalidData,
      cause: e,
    );
  }

  // raise exception từ RPC (P0001) — thông điệp do máy chủ soạn, dùng thẳng
  // (không có code để dịch phía client).
  if (code == 'P0001' && message.trim().isNotEmpty) {
    // RPC từ migration 008 ném mã ngắn (USERNAME_TAKEN…) để client dịch được.
    final token = _rpcTokenCode(message);
    return AppException(
      token == null ? message.trim() : _authFallback(token),
      kind: token == AppErrorCode.notLoggedIn
          ? AppErrorKind.auth
          : AppErrorKind.validation,
      code: token,
      cause: e,
    );
  }

  // RPC chưa được cài
  if (code == 'PGRST202' || lower.contains('could not find the function')) {
    return AppException(
      'Máy chủ chưa được cài đặt đầy đủ. Chạy các file trong assets/SQL theo '
      'hướng dẫn ở assets/SQL/README.md.',
      kind: AppErrorKind.unknown,
      code: AppErrorCode.serverNotSetup,
      cause: e,
    );
  }

  final trimmed = message.trim();
  return AppException(
    trimmed.isEmpty ? 'Máy chủ trả về lỗi.' : trimmed,
    kind: AppErrorKind.unknown,
    code: trimmed.isEmpty ? AppErrorCode.serverError : null,
    cause: e,
  );
}

/// Mã lỗi chuẩn GoTrue → [AppErrorCode].
/// Danh sách: supabase.com/docs/guides/auth/debugging/error-codes
AppErrorCode? _authCodeFromApi(String? apiCode) {
  return switch (apiCode) {
    'invalid_credentials' => AppErrorCode.invalidCredentials,
    'email_not_confirmed' => AppErrorCode.emailNotConfirmed,
    'user_already_exists' => AppErrorCode.emailAlreadyRegistered,
    'email_exists' => AppErrorCode.emailExists,
    'identity_already_exists' => AppErrorCode.identityAlreadyLinked,
    'single_identity_not_deletable' => AppErrorCode.lastLoginMethod,
    'manual_linking_disabled' => AppErrorCode.manualLinkingDisabled,
    'over_request_rate_limit' ||
    'over_email_send_rate_limit' ||
    'over_sms_send_rate_limit' => AppErrorCode.rateLimited,
    'weak_password' => AppErrorCode.passwordTooShort,
    'otp_expired' => AppErrorCode.codeExpired,
    'session_expired' ||
    'refresh_token_not_found' => AppErrorCode.sessionExpired,
    _ => null,
  };
}

/// RPC ném "raise exception 'USERNAME_TAKEN'" → code có bản dịch.
AppErrorCode? _rpcTokenCode(String message) {
  return switch (message.trim().toUpperCase()) {
    'USERNAME_TAKEN' => AppErrorCode.usernameTaken,
    'USERNAME_INVALID' => AppErrorCode.usernameInvalid,
    'NOT_LOGGED_IN' => AppErrorCode.notLoggedIn,
    _ => null,
  };
}

AppErrorCode? _authCode(String raw) {
  final m = raw.toLowerCase();
  if (m.contains('invalid') && m.contains('credential')) {
    return AppErrorCode.invalidCredentials;
  }
  if (m.contains('email not confirmed') || m.contains('confirm your email')) {
    return AppErrorCode.emailNotConfirmed;
  }
  if (m.contains('already registered')) {
    return AppErrorCode.emailAlreadyRegistered;
  }
  if (m.contains('token has expired') || m.contains('expired')) {
    return AppErrorCode.codeExpired;
  }
  if (m.contains('rate limit') || m.contains('too many')) {
    return AppErrorCode.rateLimited;
  }
  if (m.contains('password') && m.contains('short')) {
    return AppErrorCode.passwordTooShort;
  }
  return null;
}

/// Fallback tiếng Việt khi UI không tra được bản dịch (hiếm — chỉ khi
/// exception thoát ra ngoài cây widget có l10n).
String _authFallback(AppErrorCode code) {
  return switch (code) {
    AppErrorCode.invalidCredentials => 'Email hoặc mật khẩu không đúng.',
    AppErrorCode.emailNotConfirmed =>
      'Vui lòng xác nhận email trước khi đăng nhập. Kiểm tra hộp thư và thư mục spam.',
    AppErrorCode.emailAlreadyRegistered =>
      'Email này đã được đăng ký. Hãy đăng nhập hoặc dùng Quên mật khẩu.',
    AppErrorCode.codeExpired => 'Mã đã hết hạn. Hãy yêu cầu mã mới.',
    AppErrorCode.rateLimited =>
      'Bạn thử quá nhiều lần. Đợi một lát rồi thử lại.',
    AppErrorCode.passwordTooShort => 'Mật khẩu quá ngắn. Dùng ít nhất 6 ký tự.',
    AppErrorCode.usernameTaken => 'Tên đăng nhập này đã có người dùng.',
    AppErrorCode.usernameInvalid =>
      'Tên đăng nhập gồm 3–30 ký tự: chữ thường, số, dấu chấm hoặc gạch dưới.',
    AppErrorCode.identityAlreadyLinked =>
      'Tài khoản này đã được liên kết với một người dùng Coinsort khác.',
    AppErrorCode.lastLoginMethod =>
      'Đây là cách đăng nhập duy nhất của bạn. Hãy đặt mật khẩu hoặc liên kết '
          'tài khoản khác trước khi gỡ.',
    AppErrorCode.manualLinkingDisabled =>
      'Máy chủ chưa bật tính năng liên kết tài khoản.',
    AppErrorCode.emailExists => 'Email này đã được dùng cho tài khoản khác.',
    AppErrorCode.sessionExpired =>
      'Phiên đăng nhập đã hết hạn. Hãy đăng nhập lại.',
    AppErrorCode.notLoggedIn => 'Chưa đăng nhập.',
    _ => 'Đã xảy ra lỗi. Thử lại sau ít phút.',
  };
}

bool _looksLikeNetwork(String text) {
  const needles = [
    'failed host lookup',
    'socketexception',
    'connection refused',
    'connection closed',
    'network is unreachable',
    'no address associated with hostname',
    'clientexception',
    'timeout',
    'timed out',
  ];
  return needles.any(text.contains);
}
