import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spend_sync/src/core/l10n/l10n.dart';

import '../../../../core/constants/app_palette.dart';
import '../../../../core/errors/error_l10n.dart';
import '../../../shared/presentation/widgets/async_states.dart';
import '../../domain/group.dart';
import '../providers/active_group_provider.dart';

class ManageGroupsScreen extends ConsumerStatefulWidget {
  const ManageGroupsScreen({super.key});

  @override
  ConsumerState<ManageGroupsScreen> createState() => _ManageGroupsScreenState();
}

class _ManageGroupsScreenState extends ConsumerState<ManageGroupsScreen> {
  final _createNameController = TextEditingController();
  final _joinIdController = TextEditingController();
  var _createLoading = false;
  var _joinLoading = false;
  String? _createError;
  String? _joinError;
  String? _joinSuccess;

  @override
  void dispose() {
    _createNameController.dispose();
    _joinIdController.dispose();
    super.dispose();
  }

  Future<void> _createGroup() async {
    final name = _createNameController.text.trim();
    if (name.isEmpty) {
      setState(() {
        _createError = context.l10n.groupsEnterGroupName;
        _createLoading = false;
      });
      return;
    }
    setState(() {
      _createError = null;
      _createLoading = true;
    });
    final repo = ref.read(groupRepositoryProvider);
    final result = await repo.createGroup(name);
    if (!mounted) return;
    setState(() => _createLoading = false);
    final g = result.valueOrNull;
    if (g == null) {
      setState(() => _createError = result.localizedErrorOrNull(context.l10n));
      return;
    }
    await ref.read(activeGroupProvider.notifier).setActiveGroup(g);
    ref.read(groupVersionProvider.notifier).state++;
    if (mounted) context.pop();
  }

  Future<void> _joinGroup() async {
    final code = _joinIdController.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() {
        _joinError = context.l10n.groupsEnterInviteCode;
        _joinLoading = false;
      });
      return;
    }
    setState(() {
      _joinError = null;
      _joinSuccess = null;
      _joinLoading = true;
    });
    final repo = ref.read(groupRepositoryProvider);
    final result = await repo.joinGroupByCode(code);
    if (!mounted) return;
    setState(() => _joinLoading = false);
    if (result.isErr) {
      setState(() => _joinError = result.localizedErrorOrNull(context.l10n));
      return;
    }
    setState(() => _joinSuccess = context.l10n.groupsJoinedGroup);
    ref.read(groupVersionProvider.notifier).state++;
    try {
      final groups = await repo.getUserGroups();
      final joined = groups
          .where((g) => (g.inviteCode ?? '').toUpperCase() == code)
          .firstOrNull;
      if (joined != null && mounted) {
        await ref.read(activeGroupProvider.notifier).setActiveGroup(joined);
      }
    } catch (_) {
      // Đã vào nhóm rồi; chọn nhóm để sau cũng được.
    }
  }

  Future<void> _editGroup(AppGroup g) async {
    final nameController = TextEditingController(text: g.name);
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
    if (result != true || !mounted) return;
    if (newName.isEmpty) return;
    final repo = ref.read(groupRepositoryProvider);
    final renamed = await repo.renameGroup(g.id, newName);
    if (!mounted) return;
    final updated = renamed.valueOrNull;
    if (updated == null) {
      showResultSnackBar(
        context,
        message:
            renamed.localizedErrorOrNull(context.l10n) ??
            context.l10n.groupsRenameFailed,
        isError: true,
      );
      return;
    }
    ref.read(groupVersionProvider.notifier).state++;
    final active = ref.read(activeGroupProvider);
    if (active?.id == g.id) {
      await ref.read(activeGroupProvider.notifier).setActiveGroup(updated);
    }
    if (mounted) {
      showResultSnackBar(context, message: context.l10n.groupsGroupNameUpdated);
    }
  }

  Future<void> _deleteGroup(AppGroup g) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.colors.surface,
        title: Text(context.l10n.groupsDeleteGroup),
        content: Text(
          context.l10n.groupsDeleteGroupConfirm(g.name),
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
    final repo = ref.read(groupRepositoryProvider);
    final result = await repo.deleteGroup(g.id);
    if (!mounted) return;
    if (result.isErr) {
      showResultSnackBar(
        context,
        message:
            result.localizedErrorOrNull(context.l10n) ??
            context.l10n.groupsDeleteFailed,
        isError: true,
      );
      return;
    }
    ref.read(groupVersionProvider.notifier).state++;
    final active = ref.read(activeGroupProvider);
    if (active?.id == g.id) {
      final notifier = ref.read(activeGroupProvider.notifier);
      await notifier.setActiveGroup(null);
      try {
        final list = await repo.getUserGroups();
        if (list.isNotEmpty) {
          final personal = list.where((x) => x.isPersonal).firstOrNull;
          await notifier.setActiveGroup(personal ?? list.first);
        }
      } catch (_) {}
    }
    if (mounted) {
      showResultSnackBar(context, message: context.l10n.groupsGroupDeleted);
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupsAsync = ref.watch(userGroupsListProvider);
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        title: Text(context.l10n.groupsManageTitle),
        backgroundColor: context.colors.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: context.l10n.commonBack,
          onPressed: () => context.pop(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.read(groupVersionProvider.notifier).state++;
          await ref.read(userGroupsListProvider.future);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.l10n.groupsMyGroups,
                style: TextStyle(
                  color: context.colors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              groupsAsync.when(
                data: (groups) {
                  if (groups.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: AsyncEmptyView(
                        icon: Icons.groups_outlined,
                        title: context.l10n.groupsEmptyList,
                      ),
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Column(
                      children: groups.map((g) {
                        return Card(
                          color: context.colors.surface,
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(
                              g.name,
                              style: TextStyle(
                                color: context.colors.textPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: g.isPersonal
                                ? Text(
                                    context.l10n.groupsPersonal,
                                    style: TextStyle(
                                      color: context.colors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  )
                                : null,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    Icons.edit_outlined,
                                    color: context.colors.primary,
                                    size: 22,
                                  ),
                                  onPressed: () => _editGroup(g),
                                  tooltip: context.l10n.groupsEditNameTooltip,
                                ),
                                if (!g.isPersonal)
                                  IconButton(
                                    icon: Icon(
                                      Icons.delete_outline,
                                      color: context.colors.expense,
                                      size: 22,
                                    ),
                                    onPressed: () => _deleteGroup(g),
                                    tooltip: context.l10n.groupsDeleteGroup,
                                  ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.only(bottom: 24),
                  child: Center(
                    child: SizedBox(
                      height: 32,
                      width: 32,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: AsyncErrorView(
                    error: e,
                    onRetry: () => ref.invalidate(userGroupsListProvider),
                  ),
                ),
              ),
              Text(
                context.l10n.groupsCreateNew,
                style: TextStyle(
                  color: context.colors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _createNameController,
                decoration: InputDecoration(
                  labelText: context.l10n.groupsGroupNameLabel,
                  hintText: context.l10n.groupsGroupNameHint,
                ),
                style: TextStyle(color: context.colors.textPrimary),
                onSubmitted: (_) => _createGroup(),
              ),
              if (_createError != null) ...[
                const SizedBox(height: 8),
                Text(
                  _createError!,
                  style: TextStyle(color: context.colors.expense, fontSize: 14),
                ),
              ],
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _createLoading ? null : _createGroup,
                style: FilledButton.styleFrom(
                  backgroundColor: context.colors.primary,
                  foregroundColor: context.colors.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _createLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(context.l10n.groupsCreateButton),
              ),
              const SizedBox(height: 32),
              Text(
                context.l10n.groupsJoinByCodeHeader,
                style: TextStyle(
                  color: context.colors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _joinIdController,
                decoration: InputDecoration(
                  labelText: context.l10n.groupsInviteCodeLabel,
                  hintText: context.l10n.groupsInviteCodeHint,
                ),
                style: TextStyle(color: context.colors.textPrimary),
                onSubmitted: (_) => _joinGroup(),
              ),
              if (_joinError != null) ...[
                const SizedBox(height: 8),
                Text(
                  _joinError!,
                  style: TextStyle(color: context.colors.expense, fontSize: 14),
                ),
              ],
              if (_joinSuccess != null) ...[
                const SizedBox(height: 8),
                Text(
                  _joinSuccess!,
                  style: TextStyle(color: context.colors.income, fontSize: 14),
                ),
              ],
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _joinLoading ? null : _joinGroup,
                style: FilledButton.styleFrom(
                  backgroundColor: context.colors.surface,
                  foregroundColor: context.colors.textPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _joinLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(context.l10n.groupsJoinButton),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
