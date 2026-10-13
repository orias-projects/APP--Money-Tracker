import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spend_sync/src/core/l10n/l10n.dart';

import '../../../../core/constants/app_palette.dart';
import '../../../../core/errors/error_l10n.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/group_member.dart';
import '../../domain/group.dart';
import '../../../shared/presentation/widgets/async_states.dart';
import '../providers/active_group_provider.dart';

class GroupMembersScreen extends ConsumerStatefulWidget {
  const GroupMembersScreen({
    super.key,
    required this.groupId,
    required this.groupName,
    this.isPersonal = true,
  });

  final String groupId;
  final String groupName;
  final bool isPersonal;

  @override
  ConsumerState<GroupMembersScreen> createState() => _GroupMembersScreenState();
}

class _GroupMembersScreenState extends ConsumerState<GroupMembersScreen> {
  String? _actionError;
  bool _kicking = false;
  late String _groupName;

  @override
  void initState() {
    super.initState();
    _groupName = widget.groupName;
  }

  String _memberInitial(GroupMember m) {
    final name = m.user?.fullName ?? m.user?.username ?? '';
    if (name.isEmpty) return '?';
    return name[0].toUpperCase();
  }

  Future<void> _leaveGroup() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.colors.surface,
        title: Text(context.l10n.groupsLeaveGroup),
        content: Text(context.l10n.groupsLeaveGroupConfirm(_groupName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(context.l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: context.colors.expense,
              foregroundColor: Colors.white,
            ),
            child: Text(context.l10n.groupsLeaveGroup),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    HapticFeedback.lightImpact();
    setState(() => _actionError = null);
    final result = await ref
        .read(groupRepositoryProvider)
        .leaveGroup(widget.groupId);
    if (!mounted) return;
    if (result.isErr) {
      setState(() => _actionError = result.localizedErrorOrNull(context.l10n));
      return;
    }
    ref.read(groupVersionProvider.notifier).state++;
    await _fallBackToAnotherGroup();
    if (mounted) context.pop();
  }

  Future<void> _kickMember(GroupMember member) async {
    final name =
        member.user?.fullName ??
        member.user?.username ??
        context.l10n.groupsMemberLabel;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.colors.surface,
        title: Text(context.l10n.groupsRemoveFromGroup),
        content: Text(context.l10n.groupsRemoveMemberConfirm(name, _groupName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(context.l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: context.colors.expense,
              foregroundColor: Colors.white,
            ),
            child: Text(context.l10n.actionDelete),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    HapticFeedback.lightImpact();
    setState(() {
      _actionError = null;
      _kicking = true;
    });
    final result = await ref
        .read(groupRepositoryProvider)
        .kickMember(widget.groupId, member.userId);
    if (!mounted) return;
    setState(() => _kicking = false);
    if (result.isErr) {
      setState(() => _actionError = result.localizedErrorOrNull(context.l10n));
      return;
    }
    ref.read(groupVersionProvider.notifier).state++;
  }

  Future<void> _editGroup() async {
    final nameController = TextEditingController(text: _groupName);
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.colors.surface,
        title: Text(context.l10n.groupsEditGroupName),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: context.l10n.groupsGroupNameLabel,
            hintText: context.l10n.groupsGroupNameHint,
          ),
          style: TextStyle(color: context.colors.textPrimary),
          autofocus: true,
          onSubmitted: (_) => Navigator.of(ctx).pop(true),
        ),
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
            child: Text(context.l10n.actionSave),
          ),
        ],
      ),
    );
    final newName = nameController.text.trim();
    nameController.dispose();
    if (result != true || !mounted || newName.isEmpty) return;
    setState(() => _actionError = null);
    final renamed = await ref
        .read(groupRepositoryProvider)
        .renameGroup(widget.groupId, newName);
    if (!mounted) return;
    final updated = renamed.valueOrNull;
    if (updated == null) {
      setState(() => _actionError = renamed.localizedErrorOrNull(context.l10n));
      return;
    }
    setState(() => _groupName = updated.name);
    ref.read(groupVersionProvider.notifier).state++;
    final active = ref.read(activeGroupProvider);
    if (active?.id == widget.groupId) {
      await ref.read(activeGroupProvider.notifier).setActiveGroup(updated);
    }
    if (mounted) {
      showResultSnackBar(context, message: context.l10n.groupsGroupNameUpdated);
    }
  }

  Future<void> _deleteGroup() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.colors.surface,
        title: Text(context.l10n.groupsDeleteGroup),
        content: Text(
          context.l10n.groupsDeleteGroupConfirm(_groupName),
          style: TextStyle(color: context.colors.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(context.l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: context.colors.expense,
            ),
            child: Text(context.l10n.actionDelete),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    HapticFeedback.lightImpact();
    setState(() => _actionError = null);
    final result = await ref
        .read(groupRepositoryProvider)
        .deleteGroup(widget.groupId);
    if (!mounted) return;
    if (result.isErr) {
      setState(() => _actionError = result.localizedErrorOrNull(context.l10n));
      return;
    }
    ref.read(groupVersionProvider.notifier).state++;
    await _fallBackToAnotherGroup();
    if (mounted) {
      showResultSnackBar(context, message: context.l10n.groupsGroupDeleted);
      context.pop();
    }
  }

  /// Sau khi rời/xoá nhóm đang xem: chuyển về nhóm cá nhân (hoặc nhóm còn lại).
  Future<void> _fallBackToAnotherGroup() async {
    final active = ref.read(activeGroupProvider);
    if (active?.id != widget.groupId) return;
    final notifier = ref.read(activeGroupProvider.notifier);
    await notifier.setActiveGroup(null);
    try {
      final list = await ref.read(groupRepositoryProvider).getUserGroups();
      if (list.isEmpty) return;
      final personal = list.where((x) => x.isPersonal).firstOrNull;
      await notifier.setActiveGroup(personal ?? list.first);
    } catch (_) {
      // Mất mạng: để ensureActiveGroup() ở shell thử lại sau.
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = ref.watch(currentUserProvider).valueOrNull?.id;
    final membersAsync = ref.watch(groupMembersProvider(widget.groupId));
    GroupMember? myMembership;
    var isAdmin = false;
    if (membersAsync.hasValue && currentUserId != null) {
      myMembership = membersAsync.value!
          .where((m) => m.userId == currentUserId)
          .firstOrNull;
      isAdmin = myMembership?.isAdmin ?? false;
    }

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        title: Text(_groupName, maxLines: 1, overflow: TextOverflow.ellipsis),
        backgroundColor: context.colors.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: context.l10n.commonBack,
          onPressed: () => context.pop(),
        ),
        actions: [
          if (isAdmin) ...[
            IconButton(
              icon: Icon(Icons.edit_outlined, color: context.colors.primary),
              onPressed: _editGroup,
              tooltip: context.l10n.groupsEditGroupName,
            ),
            if (!widget.isPersonal)
              IconButton(
                icon: Icon(Icons.delete_outline, color: context.colors.expense),
                onPressed: _deleteGroup,
                tooltip: context.l10n.groupsDeleteGroup,
              ),
          ],
        ],
      ),
      body: Column(
        children: [
          if (_actionError != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                _actionError!,
                style: TextStyle(color: context.colors.expense),
              ),
            ),
          if (!widget.isPersonal) ...[
            _InviteCodeCard(groupId: widget.groupId, isAdmin: isAdmin),
            ListTile(
              leading: Icon(
                Icons.receipt_long_outlined,
                color: context.colors.primary,
              ),
              title: Text(context.l10n.groupsGroupDebts),
              subtitle: Text(
                context.l10n.groupsGroupDebtsSubtitle,
                style: TextStyle(
                  color: context.colors.textSecondary,
                  fontSize: 12,
                ),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/settle-up', extra: widget.groupId),
            ),
            const Divider(height: 1),
          ],
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.read(groupVersionProvider.notifier).state++;
                await ref.read(groupMembersProvider(widget.groupId).future);
              },
              child: membersAsync.when(
                data: (members) {
                  if (members.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        AsyncEmptyView(
                          icon: Icons.people_outline,
                          title: context.l10n.groupsNoMembers,
                        ),
                      ],
                    );
                  }
                  return ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: members.length,
                    itemBuilder: (context, index) {
                      final m = members[index];
                      final isMe = m.userId == currentUserId;
                      final canKick = isAdmin && !isMe;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: context.colors.primary.withValues(
                            alpha: 0.3,
                          ),
                          child: Text(
                            _memberInitial(m),
                            style: TextStyle(color: context.colors.primary),
                          ),
                        ),
                        title: Text(
                          m.user?.fullName ??
                              m.user?.username ??
                              context.l10n.groupsMemberLabel,
                          style: TextStyle(
                            fontWeight: isMe
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isMe ? context.colors.income : null,
                          ),
                        ),
                        subtitle: Text(
                          m.role == 'admin'
                              ? context.l10n.groupsRoleAdmin
                              : context.l10n.groupsMemberLabel,
                        ),
                        trailing: canKick
                            ? TextButton(
                                onPressed: _kicking
                                    ? null
                                    : () => _kickMember(m),
                                child: Text(context.l10n.groupsRemoveFromGroup),
                              )
                            : null,
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    AsyncErrorView(
                      error: e,
                      onRetry: () =>
                          ref.invalidate(groupMembersProvider(widget.groupId)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (!widget.isPersonal && myMembership != null)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _leaveGroup,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.colors.expense,
                      side: BorderSide(color: context.colors.expense),
                    ),
                    child: Text(context.l10n.groupsLeaveGroup),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Mã mời nhóm — thay cho việc chia sẻ UUID, vì ai biết UUID cũng vào được.
class _InviteCodeCard extends ConsumerWidget {
  const _InviteCodeCard({required this.groupId, required this.isAdmin});

  final String groupId;
  final bool isAdmin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(userGroupsListProvider);
    final group = groupsAsync.valueOrNull
        ?.where((g) => g.id == groupId)
        .cast<AppGroup?>()
        .firstWhere((g) => true, orElse: () => null);

    final code = group?.inviteCode;
    if (code == null || code.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.groupsInviteCode,
                  style: TextStyle(
                    color: context.colors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Semantics(
                  label: context.l10n.groupsInviteCodeSemantics(code),
                  child: Text(
                    code,
                    style: TextStyle(
                      color: context.colors.primary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.copy, size: 20),
              tooltip: context.l10n.groupsCopyCodeTooltip,
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: code));
                if (context.mounted) {
                  showResultSnackBar(
                    context,
                    message: context.l10n.groupsCodeCopied,
                  );
                }
              },
            ),
            if (isAdmin)
              IconButton(
                icon: const Icon(Icons.refresh, size: 20),
                tooltip: context.l10n.groupsRotateCodeTooltip,
                onPressed: () async {
                  final result = await ref
                      .read(groupRepositoryProvider)
                      .rotateInviteCode(groupId);
                  ref.read(groupVersionProvider.notifier).state++;
                  if (context.mounted) {
                    showResultSnackBar(
                      context,
                      message:
                          result.localizedErrorOrNull(context.l10n) ??
                          context.l10n.groupsNewCode(result.valueOrNull ?? ''),
                      isError: result.isErr,
                    );
                  }
                },
              ),
          ],
        ),
      ),
    );
  }
}
