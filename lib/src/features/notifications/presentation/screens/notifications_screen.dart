import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spend_sync/src/core/l10n/l10n.dart';

import '../../../../core/constants/app_palette.dart';
import '../../../../core/errors/error_l10n.dart';
import '../../../groups/domain/group_invitation.dart';
import '../../../groups/presentation/providers/active_group_provider.dart';
import '../../../shared/presentation/widgets/async_states.dart';

/// Nội dung danh sách thông báo, dùng trong màn route hoặc form nổi.
class NotificationsPanelContent extends ConsumerWidget {
  const NotificationsPanelContent({super.key, this.onClose});

  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invitationsAsync = ref.watch(myInvitationsProvider);
    return invitationsAsync.when(
      data: (list) {
        if (list.isEmpty) {
          // Rỗng vẫn phải kéo-làm-mới được nên bọc trong ListView cuộn được.
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(myInvitationsProvider),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                AsyncEmptyView(
                  icon: Icons.notifications_none_rounded,
                  title: context.l10n.notifEmpty,
                ),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(myInvitationsProvider),
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final inv = list[index];
              return _InvitationTile(invitation: inv, onAcceptSuccess: onClose);
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => RefreshIndicator(
        onRefresh: () async => ref.invalidate(myInvitationsProvider),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            AsyncErrorView(
              error: e,
              onRetry: () => ref.invalidate(myInvitationsProvider),
            ),
          ],
        ),
      ),
    );
  }
}

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        title: Text(context.l10n.notifTitle),
        backgroundColor: context.colors.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: context.l10n.notifBack,
          onPressed: () => context.pop(),
        ),
      ),
      body: NotificationsPanelContent(onClose: null),
    );
  }
}

class _InvitationTile extends ConsumerStatefulWidget {
  const _InvitationTile({required this.invitation, this.onAcceptSuccess});

  final GroupInvitation invitation;
  final VoidCallback? onAcceptSuccess;

  @override
  ConsumerState<_InvitationTile> createState() => _InvitationTileState();
}

class _InvitationTileState extends ConsumerState<_InvitationTile> {
  bool _loading = false;

  Future<void> _accept() async {
    if (_loading) return;
    setState(() => _loading = true);
    final repo = ref.read(groupRepositoryProvider);
    final result = await repo.acceptInvitation(widget.invitation.id);
    if (!mounted) return;
    setState(() => _loading = false);

    if (result.isErr) {
      showResultSnackBar(
        context,
        message:
            result.localizedErrorOrNull(context.l10n) ??
            context.l10n.notifJoinError,
        isError: true,
      );
      return;
    }

    ref.read(groupVersionProvider.notifier).state++;
    try {
      final groups = await ref.read(userGroupsListProvider.future);
      if (!mounted) return;
      for (final g in groups) {
        if (g.id == widget.invitation.groupId) {
          await ref.read(activeGroupProvider.notifier).setActiveGroup(g);
          break;
        }
      }
    } catch (_) {
      // Đã vào nhóm; chọn nhóm để sau cũng được.
    }
    if (!mounted) return;

    showResultSnackBar(
      context,
      message: context.l10n.notifJoinedGroup(widget.invitation.groupName),
    );
    if (widget.onAcceptSuccess != null) {
      widget.onAcceptSuccess!();
    } else {
      context.pop();
    }
  }

  Future<void> _decline() async {
    if (_loading) return;
    setState(() => _loading = true);
    final repo = ref.read(groupRepositoryProvider);
    final result = await repo.declineInvitation(widget.invitation.id);
    if (!mounted) return;
    setState(() => _loading = false);
    ref.read(groupVersionProvider.notifier).state++;
    showResultSnackBar(
      context,
      message:
          result.localizedErrorOrNull(context.l10n) ??
          context.l10n.notifDeclined,
      isError: result.isErr,
    );
  }

  @override
  Widget build(BuildContext context) {
    final inv = widget.invitation;
    final inviterName = inv.inviterName.isNotEmpty
        ? inv.inviterName
        : context.l10n.notifSomeone;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      leading: CircleAvatar(
        backgroundColor: context.colors.surface,
        child: Icon(Icons.group_add, color: context.colors.primary),
      ),
      title: Text(
        context.l10n.notifInviteTitle(inviterName),
        style: TextStyle(
          color: context.colors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            inv.groupName,
            style: TextStyle(color: context.colors.primary, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FilledButton(
                onPressed: _loading ? null : _accept,
                style: FilledButton.styleFrom(
                  backgroundColor: context.colors.income,
                  foregroundColor: context.colors.onPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  minimumSize: const Size(0, 48),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(context.l10n.notifAccept),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: _loading ? null : _decline,
                style: OutlinedButton.styleFrom(
                  foregroundColor: context.colors.textSecondary,
                  minimumSize: const Size(0, 48),
                ),
                child: Text(context.l10n.notifDecline),
              ),
            ],
          ),
        ],
      ),
      isThreeLine: true,
    );
  }
}
