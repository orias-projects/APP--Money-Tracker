import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/result.dart';

/// Lấy danh sách bạn bè từ mạng xã hội và đồng bộ lên `social_friends`
/// (migration 008) để `get_friend_suggestions` khớp ra người dùng Coinsort.
///
/// Hiện chỉ Facebook có API khả dụng: `/me/friends` trả về **những bạn cũng
/// dùng app này** (Graph API v2+ không trả toàn bộ danh bạ) — đúng tập cần cho
/// việc mời vào nhóm. X đọc following cần gói API trả phí, Google không có
/// khái niệm bạn bè, nên hai provider đó không đồng bộ.
class SocialFriendsService {
  SocialFriendsService(this._client, {http.Client? httpClient})
    : _http = httpClient ?? http.Client();

  final SupabaseClient _client;
  final http.Client _http;

  static const graphBase = 'https://graph.facebook.com/v19.0';
  static const _pageSize = 200;
  static const _maxFriends = 2000;
  static const _timeout = Duration(seconds: 20);

  /// [providerToken] là `Session.providerToken` ngay sau khi đăng nhập/liên kết
  /// Facebook — GoTrue không lưu lại token này qua các lần refresh, nên phải
  /// đồng bộ ngay lúc có. Trả về số bạn đã lưu.
  Future<Result<int>> syncFacebookFriends(String providerToken) {
    return Result.guard(() async {
      final friends = await _fetchFacebookFriends(providerToken);
      final res = await _client.rpc(
        'sync_social_friends',
        params: {'p_provider': 'facebook', 'p_friends': friends},
      );
      return res is num ? res.toInt() : friends.length;
    });
  }

  Future<List<Map<String, String>>> _fetchFacebookFriends(String token) async {
    final out = <Map<String, String>>[];
    Uri? next = Uri.parse('$graphBase/me/friends').replace(
      queryParameters: {
        'fields': 'id,name',
        'limit': '$_pageSize',
        'access_token': token,
      },
    );

    while (next != null && out.length < _maxFriends) {
      final resp = await _http.get(next).timeout(_timeout);
      if (resp.statusCode == 400 ||
          resp.statusCode == 401 ||
          resp.statusCode == 403) {
        // Token hết hạn / bị thu hồi / thiếu quyền user_friends.
        throw const AppException(
          'Kết nối lại Facebook để đồng bộ bạn bè.',
          kind: AppErrorKind.auth,
          code: AppErrorCode.providerTokenMissing,
        );
      }
      if (resp.statusCode != 200) {
        throw AppException(
          'Facebook trả về lỗi ${resp.statusCode}.',
          kind: AppErrorKind.unknown,
          code: AppErrorCode.oauthFailed,
        );
      }

      final body = jsonDecode(resp.body);
      if (body is! Map<String, dynamic>) break;
      for (final item in (body['data'] as List? ?? const [])) {
        if (item is! Map) continue;
        final id = item['id']?.toString();
        if (id == null || id.isEmpty) continue;
        out.add({'id': id, 'name': item['name']?.toString() ?? ''});
      }
      final nextUrl = (body['paging'] as Map?)?['next']?.toString();
      next = (nextUrl == null || nextUrl.isEmpty) ? null : Uri.parse(nextUrl);
    }
    return out;
  }
}
