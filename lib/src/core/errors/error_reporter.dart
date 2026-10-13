import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Điểm thu gom lỗi ngoài luồng của app.
///
/// Mọi lỗi framework (build/layout/paint), lỗi async không bắt được, và lỗi
/// khởi tạo đều đi qua đây. Nếu có `SENTRY_DSN` trong `.env` thì gửi lên Sentry;
/// nếu không, ở debug chỉ in ra console, ở release im lặng (không crash thêm).
///
/// Tách thành một facade để phần còn lại của app không phụ thuộc trực tiếp vào
/// Sentry — sau này đổi nhà cung cấp chỉ sửa một chỗ.
class ErrorReporter {
  ErrorReporter._();

  static final ErrorReporter instance = ErrorReporter._();

  bool _sentryEnabled = false;

  /// Gọi khi Sentry đã init thành công (xem `main.dart`).
  void markSentryEnabled() => _sentryEnabled = true;

  bool get isSentryEnabled => _sentryEnabled;

  Future<void> report(
    Object error,
    StackTrace? stack, {
    bool fatal = false,
    String? hint,
  }) async {
    if (_sentryEnabled) {
      await Sentry.captureException(
        error,
        stackTrace: stack,
        withScope: (scope) {
          if (fatal) scope.level = SentryLevel.fatal;
          if (hint != null) {
            scope.setContexts('nơi_lỗi', {'where': hint});
          }
        },
      );
      return;
    }

    // Không có Sentry: chỉ hữu ích khi dev đang chạy. Release không làm gì.
    if (kDebugMode) {
      debugPrint('[ErrorReporter]${hint != null ? ' ($hint)' : ''} $error');
      if (stack != null) debugPrint('$stack');
    }
  }
}
