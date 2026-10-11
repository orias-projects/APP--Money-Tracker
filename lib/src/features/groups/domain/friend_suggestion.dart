import '../../auth/domain/app_user.dart';

/// Nguồn gợi ý một người để mời vào nhóm (RPC `get_friend_suggestions`).
enum FriendSuggestionSource {
  facebook,
  twitter,
  google,

  /// Đang cùng ít nhất một nhóm chung.
  sharedGroup;

  static FriendSuggestionSource fromId(String? id) {
    return switch (id) {
      'facebook' => FriendSuggestionSource.facebook,
      'twitter' || 'x' => FriendSuggestionSource.twitter,
      'google' => FriendSuggestionSource.google,
      _ => FriendSuggestionSource.sharedGroup,
    };
  }
}

class FriendSuggestion {
  const FriendSuggestion({required this.user, required this.source});

  final AppUser user;
  final FriendSuggestionSource source;

  factory FriendSuggestion.fromMap(Map<String, dynamic> map) {
    return FriendSuggestion(
      user: AppUser.fromMap(map),
      source: FriendSuggestionSource.fromId(map['source'] as String?),
    );
  }
}
