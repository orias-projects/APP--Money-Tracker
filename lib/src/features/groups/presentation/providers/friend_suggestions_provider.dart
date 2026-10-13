import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/friend_suggestion.dart';
import 'active_group_provider.dart';

/// Gợi ý người để mời vào nhóm. `autoDispose` vì chỉ màn Bạn bè dùng; đổi
/// nhóm (groupVersion) hay đồng bộ bạn Facebook xong thì tải lại.
final friendSuggestionsProvider =
    FutureProvider.autoDispose<List<FriendSuggestion>>((ref) async {
      ref.watch(groupVersionProvider);
      return ref.read(groupRepositoryProvider).getFriendSuggestions();
    });
