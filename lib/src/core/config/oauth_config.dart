/// Cấu hình đăng nhập mạng xã hội đọc từ `.env` lúc khởi động.
///
/// Chỉ Google native cần client ID phía app (Credential Manager phải biết
/// *Web* client ID để phát id_token cho Supabase). Facebook và X đi qua trình
/// duyệt nên mọi khoá nằm ở Supabase Dashboard, app không giữ gì.
abstract final class OAuthConfig {
  static String? _googleWebClientId;

  /// Web OAuth client ID (Google Cloud Console → Credentials → Web application).
  /// Trống → nút Google tự rơi về luồng trình duyệt.
  static String? get googleWebClientId => _googleWebClientId;

  static bool get hasGoogleNative =>
      _googleWebClientId != null && _googleWebClientId!.isNotEmpty;

  static void configure({String? googleWebClientId}) {
    final v = googleWebClientId?.trim();
    _googleWebClientId = (v == null || v.isEmpty) ? null : v;
  }
}

/// Deep link nhận kết quả OAuth / link xác minh email. Phải khớp intent-filter
/// trong AndroidManifest, CFBundleURLSchemes trên iOS và mục Redirect URLs
/// trong Supabase Dashboard → Authentication → URL Configuration.
const kAuthRedirectUrl = 'coinsort://login-callback/';

/// Schema Postgres chứa toàn bộ bảng/RPC của app (thay cho `public`).
///
/// Phải khớp header `Assets/SQL/000_schema_setup.sql` và được thêm vào
/// Supabase Dashboard → Settings → API → "Exposed schemas", nếu không PostgREST
/// trả 406/404 cho mọi truy vấn.
const kSupabaseSchema = 'coinsort';
