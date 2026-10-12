import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spend_sync/src/core/l10n/l10n.dart';

import '../../../../core/constants/app_palette.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/error_l10n.dart';
import '../../../auth/domain/app_user.dart';
import '../../../auth/domain/social_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../groups/domain/friend_suggestion.dart';
import '../../../groups/domain/group.dart';
import '../../../groups/presentation/providers/active_group_provider.dart';
import '../../../groups/presentation/providers/friend_suggestions_provider.dart';
import '../../../shared/presentation/widgets/async_states.dart';
import '../providers/social_sync_controller.dart';

class MeFriendTab extends ConsumerStatefulWidget {
  const MeFriendTab({super.key});

  @override
  ConsumerState<MeFriendTab> createState() => _MeFriendTabState();
}

class _MeFriendTabState extends ConsumerState<MeFriendTab> {
  final _searchController = TextEditingController();
  String _query = '';
  List<AppUser> _results = [];
  bool _loading = false;
  String? _invitingUserId;
  AppGroup? _inviteTargetGroup;
  bool _reconnecting = false;

  /// RPC tìm kiếm không có limit, còn ListView shrinkWrap dựng mọi dòng cùng
  /// lúc — nên chỉ hiển thị tối đa chừng này kết quả đầu tiên.
  static const _maxVisibleResults = 20;
  static const _maxVisibleSuggestions = 10;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final q = _searchController.text.trim();
    if (q.length < 2) {
      setState(() {
        _query = q;
        _results = [];
      });
      return;
    }
    setState(() {
      _query = q;
      _loading = true;
      _results = [];
    });
    try {
      final repo = ref.read(groupRepositoryProvider);
      final list = await repo.searchUsers(q);
      if (mounted) {
        setState(() {
          _results = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        showResultSnackBar(
          context,
          message: localizedError(context.l10n, e),
          isError: true,
        );
      }
    }
  }

  Future<void> _inviteToGroup(AppUser user, AppGroup group) async {
    setState(() => _invitingUserId = user.id);
    final repo = ref.read(groupRepositoryProvider);
    final result = await repo.inviteUser(group.id, user.id);
    if (!mounted) return;
    setState(() => _invitingUserId = null);
    final name =
        user.fullName ?? user.username ?? context.l10n.profileMemberFallback;
    showResultSnackBar(
      context,
      message:
          result.localizedErrorOrNull(context.l10n) ??
          context.l10n.profileInviteSuccess(name),
      isError: result.isErr,
    );
    if (result.isOk) ref.read(groupVersionProvider.notifier).state++;
  }

  /// Token Facebook không còn (GoTrue không giữ qua refresh) → phải đi lại
  /// luồng OAuth. Đã liên kết thì đăng nhập lại chính tài khoản đó; chưa liên
  /// kết thì liên kết — KHÔNG dùng signIn khi chưa liên kết vì GoTrue sẽ mở
  /// một tài khoản Coinsort khác.
  Future<void> _reconnectFacebook() async {
    setState(() => _reconnecting = true);
    final repo = ref.read(authRepositoryProvider);
    try {
      final methods =
          ref.read(loginMethodsProvider).valueOrNull ??
          await repo.getLoginMethods();
      final linked = methods.identityFor(SocialProvider.facebook) != null;
      ref.read(socialSyncProvider.notifier).expect(SocialProvider.facebook);
      final result = linked
          ? await repo.signInWithSocial(SocialProvider.facebook)
          : await repo.linkProvider(SocialProvider.facebook);
      if (!mounted) return;
      final err = result.exceptionOrNull;
      if (err != null) {
        if (err.code != AppErrorCode.oauthCancelled) {
          showResultSnackBar(
            context,
            message: err.localizedMessage(context.l10n),
            isError: true,
          );
        }
      } else {
        showResultSnackBar(context, message: context.l10n.accountLinkBrowser);
      }
    } catch (e) {
      if (mounted) {
        showResultSnackBar(
          context,
          message: localizedError(context.l10n, e),
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _reconnecting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final groupsAsync = ref.watch(userGroupsListProvider);
    final sharedGroups =
        groupsAsync.valueOrNull?.where((g) => !g.isPersonal).toList() ?? [];
    final canInvite = _inviteTargetGroup != null;
    final suggestionsAsync = ref.watch(friendSuggestionsProvider);
    final sync = ref.watch(socialSyncProvider);

    // Báo kết quả đồng bộ Facebook (chạy nền sau khi quay về từ trình duyệt).
    ref.listen<SocialSyncState>(socialSyncProvider, (prev, next) {
      if (prev?.syncing == true && !next.syncing) {
        if (next.error == null && next.lastSyncedCount != null) {
          showResultSnackBar(
            context,
            message: l10n.profileSyncFacebookDone(next.lastSyncedCount!),
          );
        } else if (next.error != null &&
            next.error!.code != AppErrorCode.providerTokenMissing) {
          showResultSnackBar(
            context,
            message: next.error!.localizedMessage(l10n),
            isError: true,
          );
        }
      }
    });

    return SingleChildScrollView(
      // Chừa chỗ cho bàn phím để danh sách kết quả không bị che khi đang gõ.
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.profileFindFriends,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: l10n.profileSearchHint,
                    filled: true,
                    fillColor: colors.surface,
                  ),
                  style: TextStyle(color: colors.textPrimary),
                  onSubmitted: (_) => _search(),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: _loading ? null : _search,
                icon: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.search, size: 22),
                label: Text(l10n.profileSearchButton),
                style: FilledButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: colors.onPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            l10n.profileChooseGroupToInvite,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          groupsAsync.when(
            data: (_) {
              if (sharedGroups.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    l10n.profileNoSharedGroups,
                    style: TextStyle(color: colors.textSecondary, fontSize: 13),
                  ),
                );
              }
              if (_inviteTargetGroup == null && sharedGroups.isNotEmpty) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && _inviteTargetGroup == null) {
                    setState(() => _inviteTargetGroup = sharedGroups.first);
                  }
                });
              }
              final selectedGroup =
                  _inviteTargetGroup != null &&
                      sharedGroups.any((g) => g.id == _inviteTargetGroup!.id)
                  ? sharedGroups.firstWhere(
                      (g) => g.id == _inviteTargetGroup!.id,
                    )
                  : sharedGroups.first;
              return DropdownButtonHideUnderline(
                child: DropdownButton<AppGroup>(
                  value: selectedGroup,
                  isExpanded: true,
                  dropdownColor: colors.surface,
                  hint: Text(l10n.profileSelectGroup),
                  items: sharedGroups
                      .map(
                        (g) => DropdownMenuItem<AppGroup>(
                          value: g,
                          child: Text(
                            g.name,
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (g) => setState(() => _inviteTargetGroup = g),
                ),
              );
            },
            loading: () => const SizedBox(
              height: 48,
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            error: (e, _) => AsyncErrorView(
              error: e,
              compact: true,
              onRetry: () => ref.invalidate(userGroupsListProvider),
            ),
          ),

          // --- Gợi ý: bạn Facebook cũng dùng app + người cùng nhóm ---
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.profileSuggestionsTitle,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (!SocialProvider.facebook.isEnabled)
                // Đồng bộ bạn bè đi qua Graph API của Facebook — tắt đăng nhập
                // Facebook thì nút này không còn chỗ dựa.
                const SizedBox.shrink()
              else if (sync.syncing)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.profileSyncing,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                )
              else
                TextButton.icon(
                  onPressed: _reconnecting
                      ? null
                      : () => ref
                            .read(socialSyncProvider.notifier)
                            .syncFacebook(),
                  icon: const Icon(Icons.sync, size: 18),
                  label: Text(l10n.profileSyncFacebook),
                  style: TextButton.styleFrom(foregroundColor: colors.primary),
                ),
            ],
          ),
          if (SocialProvider.facebook.isEnabled &&
              sync.error?.code == AppErrorCode.providerTokenMissing)
            _ReconnectBanner(
              busy: _reconnecting,
              onReconnect: _reconnectFacebook,
            ),
          const SizedBox(height: 4),
          suggestionsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: LinearProgressIndicator(),
            ),
            error: (e, _) => AsyncErrorView(
              error: e,
              compact: true,
              onRetry: () => ref.invalidate(friendSuggestionsProvider),
            ),
            data: (list) {
              if (list.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    SocialProvider.facebook.isEnabled
                        ? l10n.profileSuggestionsEmpty
                        : l10n.profileSuggestionsEmptyNoSocial,
                    style: TextStyle(color: colors.textSecondary, fontSize: 13),
                  ),
                );
              }
              final visible = list.length > _maxVisibleSuggestions
                  ? list.sublist(0, _maxVisibleSuggestions)
                  : list;
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: visible.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final s = visible[index];
                  return _UserInviteTile(
                    user: s.user,
                    source: s.source,
                    inviting: _invitingUserId == s.user.id,
                    targetGroup: canInvite ? _inviteTargetGroup : null,
                    onInvite: () => _inviteToGroup(s.user, _inviteTargetGroup!),
                  );
                },
              );
            },
          ),

          // --- Kết quả tìm kiếm ---
          const SizedBox(height: 24),
          Text(
            l10n.profileInviteFriendsTitle,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          if (_query.isEmpty || (_query.length < 2 && _results.isEmpty))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  l10n.profileSearchPrompt,
                  style: TextStyle(color: colors.textSecondary),
                ),
              ),
            )
          else if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_results.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  l10n.profileNoResults,
                  style: TextStyle(color: colors.textSecondary),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _results.length > _maxVisibleResults
                  ? _maxVisibleResults
                  : _results.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final user = _results[index];
                return _UserInviteTile(
                  user: user,
                  inviting: _invitingUserId == user.id,
                  targetGroup: canInvite ? _inviteTargetGroup : null,
                  onInvite: () => _inviteToGroup(user, _inviteTargetGroup!),
                );
              },
            ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------

/// Một người + nút mời vào nhóm đang chọn. Dùng cho cả gợi ý và kết quả tìm.
class _UserInviteTile extends StatelessWidget {
  const _UserInviteTile({
    required this.user,
    required this.inviting,
    required this.targetGroup,
    required this.onInvite,
    this.source,
  });

  final AppUser user;
  final bool inviting;
  final AppGroup? targetGroup;
  final VoidCallback onInvite;
  final FriendSuggestionSource? source;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final initial =
        (user.fullName?.isNotEmpty == true
                ? user.fullName![0]
                : user.username?.isNotEmpty == true
                ? user.username![0]
                : '?')
            .toUpperCase();
    final sourceLabel = switch (source) {
      null => null,
      FriendSuggestionSource.facebook => l10n.profileSuggestionSourceFacebook,
      FriendSuggestionSource.twitter => l10n.profileSuggestionSourceX,
      FriendSuggestionSource.google => null,
      FriendSuggestionSource.sharedGroup => l10n.profileSuggestionSourceGroup,
    };

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: CircleAvatar(
        backgroundColor: colors.surface,
        backgroundImage: (user.avatarUrl != null && user.avatarUrl!.isNotEmpty)
            ? ResizeImage(NetworkImage(user.avatarUrl!), width: 80)
            : null,
        child: (user.avatarUrl != null && user.avatarUrl!.isNotEmpty)
            ? null
            : Text(initial, style: TextStyle(color: colors.primary)),
      ),
      title: Text(
        user.fullName?.trim().isNotEmpty == true
            ? user.fullName!
            : (user.username ?? l10n.profileMemberTitle),
        style: TextStyle(color: colors.textPrimary),
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Row(
        children: [
          if (user.username != null)
            Flexible(
              child: Text(
                '@${user.username}',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: colors.textSecondary, fontSize: 12),
              ),
            ),
          if (sourceLabel != null) ...[
            if (user.username != null) const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: colors.surfaceVariant,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                sourceLabel,
                style: TextStyle(color: colors.textSecondary, fontSize: 10),
              ),
            ),
          ],
        ],
      ),
      trailing: targetGroup != null
          ? TextButton.icon(
              onPressed: inviting ? null : onInvite,
              icon: inviting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.person_add, size: 20),
              label: Text(
                inviting
                    ? l10n.profileInviting
                    : l10n.profileInviteTo(targetGroup!.name),
              ),
              style: TextButton.styleFrom(foregroundColor: colors.primary),
            )
          : null,
    );
  }
}

class _ReconnectBanner extends StatelessWidget {
  const _ReconnectBanner({required this.busy, required this.onReconnect});

  final bool busy;
  final VoidCallback onReconnect;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      margin: const EdgeInsets.only(top: 4, bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 18, color: colors.warning),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              context.l10n.errProviderTokenMissing,
              style: TextStyle(color: colors.textPrimary, fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: busy ? null : onReconnect,
            child: Text(context.l10n.profileReconnectFacebook),
          ),
        ],
      ),
    );
  }
}
