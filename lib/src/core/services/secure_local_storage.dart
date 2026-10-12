import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Lưu phiên đăng nhập Supabase vào Keystore (Android) / Keychain (iOS) thay vì
/// SharedPreferences dạng thô.
///
/// Mặc định `supabase_flutter` cất access token + refresh token plaintext trong
/// SharedPreferences/NSUserDefaults — trên máy đã root/jailbreak hoặc qua bản
/// sao lưu, refresh token bị đọc ra là chiếm được phiên vĩnh viễn. Ở đây ta thay
/// bằng lớp lưu trữ được hệ điều hành mã hoá.
///
/// Dù tên phương thức là [accessToken], hợp đồng của [LocalStorage] là lưu và
/// trả lại *toàn bộ chuỗi phiên* đã persist, nên chỉ cần đọc/ghi một khoá.
class SecureLocalStorage extends LocalStorage {
  SecureLocalStorage({String key = _defaultKey}) : _key = key;

  static const String _defaultKey = 'supabase.auth.session';

  final String _key;

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  @override
  Future<void> initialize() async {}

  @override
  Future<String?> accessToken() => _storage.read(key: _key);

  @override
  Future<bool> hasAccessToken() => _storage.containsKey(key: _key);

  @override
  Future<void> persistSession(String persistSessionString) =>
      _storage.write(key: _key, value: persistSessionString);

  @override
  Future<void> removePersistedSession() => _storage.delete(key: _key);
}
