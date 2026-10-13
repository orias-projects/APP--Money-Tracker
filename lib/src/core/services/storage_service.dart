import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../errors/app_exception.dart';
import '../result.dart';
import 'supabase_service.dart';

/// Tải ảnh lên Supabase Storage.
///
/// Cần tạo sẵn hai bucket trong Supabase Dashboard → Storage:
///   - `receipts` (private) — ảnh hoá đơn
///   - `avatars`  (public)  — ảnh đại diện
/// Xem assets/SQL/README.md.
class StorageService {
  StorageService() : _client = SupabaseService.client;

  final SupabaseClient _client;

  static const receiptsBucket = 'receipts';
  static const avatarsBucket = 'avatars';

  /// Giới hạn 5MB — ảnh chụp hoá đơn không cần lớn hơn.
  static const maxBytes = 5 * 1024 * 1024;

  final _picker = ImagePicker();

  /// Chọn ảnh từ máy ảnh hoặc thư viện. Trả null nếu người dùng huỷ.
  Future<XFile?> pickImage({required bool fromCamera}) {
    return _picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 80,
    );
  }

  /// Tải ảnh hoá đơn lên, trả về đường dẫn lưu vào `transactions.image_url`.
  Future<Result<String>> uploadReceipt(XFile file) {
    return Result.guard(() async {
      final uid = _client.auth.currentUser?.id;
      if (uid == null) {
        throw const AppException(
          'Chưa đăng nhập.',
          kind: AppErrorKind.auth,
          code: AppErrorCode.notLoggedIn,
        );
      }

      final bytes = await file.readAsBytes();
      if (bytes.lengthInBytes > maxBytes) {
        throw const AppException(
          'Ảnh lớn hơn 5MB. Hãy chụp lại ở chất lượng thấp hơn.',
          kind: AppErrorKind.validation,
          code: AppErrorCode.imageTooLarge,
        );
      }

      final ext = _extensionOf(file.name);
      final path = '$uid/${DateTime.now().microsecondsSinceEpoch}.$ext';

      await _client.storage
          .from(receiptsBucket)
          .uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(
              contentType: _contentTypeOf(ext),
              upsert: false,
            ),
          );
      return path;
    });
  }

  /// Link xem ảnh hoá đơn, có hạn (bucket private).
  Future<Result<String>> signedReceiptUrl(String path) {
    return Result.guard(() async {
      return _client.storage
          .from(receiptsBucket)
          .createSignedUrl(path, 60 * 60);
    });
  }

  Future<Result<void>> deleteReceipt(String path) {
    return Result.guard(() async {
      await _client.storage.from(receiptsBucket).remove([path]);
    });
  }

  /// Tải ảnh đại diện lên bucket public, trả về URL đầy đủ.
  Future<Result<String>> uploadAvatar(XFile file) {
    return Result.guard(() async {
      final uid = _client.auth.currentUser?.id;
      if (uid == null) {
        throw const AppException(
          'Chưa đăng nhập.',
          kind: AppErrorKind.auth,
          code: AppErrorCode.notLoggedIn,
        );
      }
      final bytes = await file.readAsBytes();
      if (bytes.lengthInBytes > maxBytes) {
        throw const AppException(
          'Ảnh lớn hơn 5MB.',
          kind: AppErrorKind.validation,
          code: AppErrorCode.imageTooLarge,
        );
      }
      final ext = _extensionOf(file.name);
      final path = '$uid/avatar.$ext';

      await _client.storage
          .from(avatarsBucket)
          .uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(
              contentType: _contentTypeOf(ext),
              upsert: true,
            ),
          );
      // Thêm tham số thời gian để bỏ qua cache cũ sau khi đổi ảnh.
      final base = _client.storage.from(avatarsBucket).getPublicUrl(path);
      return '$base?v=${DateTime.now().millisecondsSinceEpoch}';
    });
  }

  static String _extensionOf(String name) {
    final i = name.lastIndexOf('.');
    if (i < 0 || i == name.length - 1) return 'jpg';
    final ext = name.substring(i + 1).toLowerCase();
    const allowed = {'jpg', 'jpeg', 'png', 'webp', 'heic'};
    return allowed.contains(ext) ? ext : 'jpg';
  }

  static String _contentTypeOf(String ext) => switch (ext) {
    'png' => 'image/png',
    'webp' => 'image/webp',
    'heic' => 'image/heic',
    _ => 'image/jpeg',
  };

  /// Máy ảnh chỉ có trên thiết bị di động.
  static bool get supportsCamera =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);
}
