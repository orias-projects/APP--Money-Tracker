import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spend_sync/src/core/l10n/l10n.dart';

import '../../../../core/constants/app_palette.dart';
import '../../../../shell/shell_app_bar_provider.dart';
import '../../../auth/domain/app_user.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../groups/domain/group.dart';
import '../../../groups/presentation/providers/active_group_provider.dart';
import '../../../shared/presentation/widgets/async_states.dart';
import '../widgets/editable_avatar.dart';

class MeScreen extends ConsumerWidget {
  const MeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final groupsAsync = ref.watch(userGroupsListProvider);
    final activeGroup = ref.watch(activeGroupProvider);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // const → canonical hoá: setTitle so bằng và bỏ qua, shell không rebuild.
      ref
          .read(shellAppBarTitleProvider.notifier)
          .setTitle(4, const _MeShellTitle());
    });

    return Scaffold(
      backgroundColor: context.colors.background,
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => AsyncErrorView(
          error: e,
          onRetry: () => ref.invalidate(currentUserProvider),
        ),
        data: (user) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(currentUserProvider);
            ref.read(groupVersionProvider.notifier).state++;
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              _ProfileHeader(user: user),
              const SizedBox(height: 8),

              _SectionLabel(context.l10n.profileSectionGroups),
              groupsAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => AsyncErrorView(
                  error: e,
                  compact: true,
                  onRetry: () => ref.invalidate(userGroupsListProvider),
                ),
                data: (groups) =>
                    _GroupSection(groups: groups, activeGroup: activeGroup),
              ),

              const Divider(height: 32),
              _SectionLabel(context.l10n.profileSectionTools),

              ListTile(
                leading: const Icon(Icons.search),
                title: Text(context.l10n.profileToolSearch),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/search'),
              ),
              ListTile(
                leading: const Icon(Icons.account_balance_wallet_outlined),
                title: Text(context.l10n.profileToolAccounts),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/me/accounts'),
              ),
              ListTile(
                leading: const Icon(Icons.category_outlined),
                title: Text(context.l10n.profileToolCategories),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/me/categories'),
              ),
              ListTile(
                leading: const Icon(Icons.savings_outlined),
                title: Text(context.l10n.profileToolBudgets),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/me/budgets'),
              ),
              ListTile(
                leading: const Icon(Icons.repeat),
                title: Text(context.l10n.profileToolRecurring),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/me/recurring'),
              ),
              ListTile(
                leading: const Icon(Icons.people_outline),
                title: Text(context.l10n.profileToolFriends),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/friend'),
              ),

              const Divider(height: 32),

              ListTile(
                leading: const Icon(Icons.manage_accounts_outlined),
                title: Text(context.l10n.accountTitle),
                subtitle: Text(
                  context.l10n.profileAccountDesc,
                  style: TextStyle(
                    color: context.colors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/me/account'),
              ),
              ListTile(
                leading: const Icon(Icons.settings_outlined),
                title: Text(context.l10n.profileSettings),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/me/settings'),
              ),
              ListTile(
                leading: const Icon(Icons.logout),
                title: Text(context.l10n.profileSignOut),
                onTap: () => _signOut(context, ref),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.colors.surface,
        title: Text(context.l10n.profileSignOut),
        content: Text(context.l10n.profileSignOutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(context.l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: context.colors.primary,
              foregroundColor: context.colors.onPrimary,
            ),
            child: Text(context.l10n.profileSignOut),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    await ref.read(activeGroupProvider.notifier).clear();
    await ref.read(authRepositoryProvider).signOut();
    ref.invalidate(currentUserProvider);
    ref.read(groupVersionProvider.notifier).state++;

    if (context.mounted) context.go('/login');
  }
}

// -----------------------------------------------------------------------------

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user});

  final AppUser? user;

  String _displayName(BuildContext context) {
    final full = user?.fullName?.trim();
    if (full != null && full.isNotEmpty) return full;
    final username = user?.username?.trim();
    if (username != null && username.isNotEmpty) return username;
    return context.l10n.profileDefaultUserName;
  }

  @override
  Widget build(BuildContext context) {
    final username = user?.username?.trim();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          EditableAvatar(user: user, radius: 34),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _displayName(context),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.colors.textPrimary,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  username != null && username.isNotEmpty
                      ? '@$username'
                      : context.l10n.accountNotSet,
                  style: TextStyle(
                    color: context.colors.textSecondary,
                    fontSize: 13,
                    fontStyle: username != null && username.isNotEmpty
                        ? FontStyle.normal
                        : FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.manage_accounts_outlined),
            tooltip: context.l10n.accountTitle,
            onPressed: () => context.push('/me/account'),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------

class _GroupSection extends ConsumerWidget {
  const _GroupSection({required this.groups, required this.activeGroup});

  final List<AppGroup> groups;
  final AppGroup? activeGroup;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        ...groups.map((g) {
          final isActive = activeGroup?.id == g.id;
          // Giữ (long-press) để chuyển nhóm đang chọn — kèm nút ở trailing
          // vì cử chỉ giữ một mình rất khó tự khám phá.
          void switchTo() {
            HapticFeedback.lightImpact();
            ref.read(activeGroupProvider.notifier).setActiveGroup(g);
          }

          return Semantics(
            onLongPressHint: isActive ? null : context.l10n.profileSelectGroup,
            child: ListTile(
              leading: Icon(
                g.isPersonal ? Icons.person_outline : Icons.groups_outlined,
                color: isActive
                    ? context.colors.primary
                    : context.colors.textSecondary,
              ),
              title: Text(
                g.name,
                style: TextStyle(
                  color: isActive
                      ? context.colors.primary
                      : context.colors.textPrimary,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              subtitle: isActive
                  ? Text(
                      context.l10n.profileGroupActive,
                      style: TextStyle(
                        color: context.colors.textTertiary,
                        fontSize: 12,
                      ),
                    )
                  : null,
              trailing: isActive
                  ? const Icon(Icons.chevron_right)
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: context.l10n.profileSelectGroup,
                          icon: Icon(
                            Icons.swap_horiz,
                            color: context.colors.textSecondary,
                          ),
                          onPressed: switchTo,
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
              onTap: () => context.push(
                '/me/group-members',
                extra: {
                  'groupId': g.id,
                  'groupName': g.name,
                  'isPersonal': g.isPersonal,
                },
              ),
              onLongPress: isActive ? null : switchTo,
            ),
          );
        }),
        ListTile(
          leading: Icon(
            Icons.add_circle_outline,
            color: context.colors.primary,
          ),
          title: Text(
            context.l10n.profileCreateOrJoinGroup,
            style: TextStyle(color: context.colors.primary),
          ),
          onTap: () => context.push('/me/manage-groups'),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: context.colors.textTertiary,
          fontSize: 11,
          letterSpacing: 1.1,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Tieu de tab tren thanh shell — const de setTitle canonical hoa va bo qua,
/// doi ngon ngu/theme van tu cap nhat vi l10n/mau doc trong build.
class _MeShellTitle extends StatelessWidget {
  const _MeShellTitle();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Text(
        context.l10n.profileMe,
        style: TextStyle(
          color: context.colors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
