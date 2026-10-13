/// Nhà cung cấp đăng nhập ngoài mà app hỗ trợ.
///
/// Tên `id` trùng với tên provider của GoTrue (`auth.identities.provider`) và
/// với cột `provider` trong bảng `social_friends` (migration 008).
enum SocialProvider {
  google('google'),
  facebook('facebook'),

  /// Supabase gọi provider OAuth2 mới của X là `x`; bản `twitter` (OAuth 1.0a)
  /// đã deprecated. Giá trị này đi vào authorize URL và auth.identities.
  twitter('x');

  const SocialProvider(this.id);

  /// Định danh phía GoTrue / DB.
  final String id;

  /// Provider đang thực sự dùng được trong bản phát hành.
  ///
  /// Nút nào không nằm trong danh sách này thì KHÔNG hiện lên UI — bấm vào một
  /// provider chưa bật bên Supabase chỉ nhận lỗi "provider is not enabled",
  /// vừa hỏng trải nghiệm vừa dễ bị người duyệt store đánh trượt.
  ///
  /// Trạng thái hiện tại:
  /// - `google` — đã bật.
  /// - `facebook` — **tắt**: quy trình đăng ký app + App Review quyền
  ///   `user_friends` bên Meta đang quá phức tạp. Provider bên Supabase vẫn bật
  ///   sẵn, bật lại ở app là dùng được ngay.
  /// - `twitter` (X) — **tắt**: provider bên Supabase chưa cấu hình
  ///   (`/auth/v1/settings` trả `twitter: false`), bật nút chỉ để người dùng
  ///   bấm vào rồi nhận lỗi. Muốn bật thì cấu hình OAuth bên X Developer Portal
  ///   + Supabase trước, rồi mới thêm vào danh sách này.
  ///
  /// Code của hai provider trên vẫn giữ nguyên — chỉ công tắc này đổi.
  /// Tài khoản đã liên kết trước đó vẫn hiện ở màn Tài khoản để gỡ liên kết —
  /// xem `account_screen.dart`.
  static const List<SocialProvider> enabled = <SocialProvider>[
    SocialProvider.google,
  ];

  /// True khi provider này đang được bật — xem [enabled].
  bool get isEnabled => enabled.contains(this);

  static SocialProvider? fromId(String? id) {
    // Identity cũ tạo qua provider Twitter deprecated vẫn nhận diện được.
    if (id == 'twitter') return SocialProvider.twitter;
    for (final p in SocialProvider.values) {
      if (p.id == id) return p;
    }
    return null;
  }
}
