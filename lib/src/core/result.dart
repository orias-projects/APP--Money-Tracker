import 'errors/app_exception.dart';
import 'errors/error_mapper.dart';

/// Kết quả của một thao tác GHI (thêm/sửa/xoá).
///
/// Đường ĐỌC không dùng kiểu này — ở đó cứ để exception bay lên, Riverpod
/// `AsyncValue.error` sẽ bắt và màn hình hiển thị qua nhánh `error:`.
/// Đường GHI cần biết thành công hay thất bại ngay tại chỗ gọi để hiện SnackBar,
/// nên dùng [Result].
sealed class Result<T> {
  const Result();

  /// Chạy [action], trả [Ok] nếu xong, [Err] với thông điệp tiếng Việt nếu lỗi.
  static Future<Result<T>> guard<T>(Future<T> Function() action) async {
    try {
      return Ok(await action());
    } catch (e, st) {
      return Err(mapError(e, st));
    }
  }

  bool get isOk => this is Ok<T>;
  bool get isErr => this is Err<T>;

  /// Giá trị nếu thành công, null nếu lỗi.
  T? get valueOrNull => switch (this) {
    Ok<T>(:final value) => value,
    Err<T>() => null,
  };

  /// Thông điệp lỗi nếu thất bại, null nếu thành công.
  ///
  /// Là chuỗi fallback tiếng Việt — nơi có l10n dùng
  /// `localizedErrorOrNull(l10n)` (extension trong `error_l10n.dart`).
  String? get errorOrNull => switch (this) {
    Ok<T>() => null,
    Err<T>(:final error) => error.message,
  };

  /// Lỗi gốc nếu thất bại, null nếu thành công.
  AppException? get exceptionOrNull => switch (this) {
    Ok<T>() => null,
    Err<T>(:final error) => error,
  };

  R when<R>({
    required R Function(T value) ok,
    required R Function(AppException error) err,
  }) => switch (this) {
    Ok<T>(:final value) => ok(value),
    Err<T>(:final error) => err(error),
  };
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);
  final T value;
}

final class Err<T> extends Result<T> {
  const Err(this.error);
  final AppException error;

  /// Tiện cho việc đổi kiểu khi truyền lỗi lên trên.
  Err<R> cast<R>() => Err<R>(error);
}
