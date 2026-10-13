import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spend_sync/src/core/services/supabase_service.dart';
import 'package:spend_sync/src/features/groups/data/group_repository.dart';
import 'package:spend_sync/src/features/groups/domain/group.dart';
import 'package:spend_sync/src/features/groups/presentation/providers/active_group_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockGroupRepository extends Mock implements GroupRepository {}

User _user(String id) => User.fromJson({
  'id': id,
  'app_metadata': <String, dynamic>{},
  'user_metadata': <String, dynamic>{},
  'aud': 'authenticated',
  'created_at': '2026-01-01T00:00:00Z',
})!;

const groupA = AppGroup(id: 'g-a', name: 'Chi tiêu cá nhân', isPersonal: true);
const groupB = AppGroup(id: 'g-b', name: 'Chi tiêu cá nhân', isPersonal: true);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockSupabaseClient client;
  late MockGoTrueClient auth;
  late MockGroupRepository repo;
  late ProviderContainer container;
  User? currentUser;

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    client = MockSupabaseClient();
    auth = MockGoTrueClient();
    repo = MockGroupRepository();
    currentUser = _user('uid-a');
    when(() => client.auth).thenReturn(auth);
    when(() => auth.currentUser).thenAnswer((_) => currentUser);
    container = ProviderContainer(
      overrides: [
        supabaseClientProvider.overrideWithValue(client),
        groupRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(container.dispose);
  });

  ActiveGroupNotifier notifier() =>
      container.read(activeGroupProvider.notifier);

  test('đổi tài khoản thì KHÔNG dùng lại nhóm của người trước', () async {
    // Nhóm của người A còn sót lại chính là nguyên nhân lỗi "Bạn không thuộc
    // nhóm này": máy chủ kiểm tra thành viên trên mọi RPC có p_group_id.
    when(() => repo.getUserGroups()).thenAnswer((_) async => [groupA]);
    await notifier().ensureActiveGroup();
    expect(container.read(activeGroupProvider), groupA);

    currentUser = _user('uid-b');
    when(() => repo.getUserGroups()).thenAnswer((_) async => [groupB]);
    await notifier().ensureActiveGroup();

    expect(container.read(activeGroupProvider), groupB);
  });

  test('đăng xuất giữa lúc đang khôi phục thì không gắn lại nhóm cũ', () async {
    // Đúng chuỗi thao tác gây lỗi: shell gọi ensureActiveGroup(), người dùng
    // bấm Đăng xuất khi lệnh mạng còn treo, kết quả về sau clear() và ghi đè.
    final pending = Completer<List<AppGroup>>();
    when(() => repo.getUserGroups()).thenAnswer((_) => pending.future);

    final restoring = notifier().ensureActiveGroup();
    await notifier().clear();
    pending.complete([groupA]);
    await restoring;

    expect(container.read(activeGroupProvider), isNull);
  });

  test('nhóm đang chọn lưu riêng theo tài khoản', () async {
    await notifier().setActiveGroup(groupA);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('active_group_id:uid-a'), 'g-a');
    // Khoá dùng chung thời trước không được ghi nữa.
    expect(prefs.getString('active_group_id'), isNull);
  });

  test('clear() dọn khoá của đúng tài khoản đang đăng nhập', () async {
    await notifier().setActiveGroup(groupA);
    await notifier().clear();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('active_group_id:uid-a'), isNull);
    expect(container.read(activeGroupProvider), isNull);
  });
}
