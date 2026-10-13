import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spend_sync/src/core/l10n/l10n.dart';

import '../../../../core/constants/app_palette.dart';
import '../../../../core/utils/format_helpers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../shared/presentation/widgets/async_states.dart';
import '../../domain/group_balance.dart';
import '../providers/active_group_provider.dart';

/// Ai đang nợ ai, và cần chuyển bao nhiêu lần để mọi người về 0.
class SettleUpScreen extends ConsumerWidget {
  const SettleUpScreen({super.key, required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balancesAsync = ref.watch(groupBalancesProvider(groupId));
    final me = ref.watch(currentUserProvider).valueOrNull?.id;

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: context.colors.background,
        title: Text(context.l10n.groupsGroupDebts),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: context.l10n.groupsSettlementHistory,
            onPressed: () => _showHistory(context, ref),
          ),
        ],
      ),
      body: balancesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => AsyncErrorView(
          error: e,
          onRetry: () => ref.invalidate(groupBalancesProvider(groupId)),
        ),
        data: (balances) {
          final suggestions = suggestSettlements(
            balances,
            memberFallback: context.l10n.memberFallback,
          );
          final allSettled = balances.every((b) => b.isSettled);

          return RefreshIndicator(
            onRefresh: () async {
              ref.read(settlementVersionProvider.notifier).state++;
              await ref.read(groupBalancesProvider(groupId).future);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                if (allSettled)
                  const _AllSettledCard()
                else ...[
                  _SectionHeader(
                    context.l10n.groupsToTransfer,
                    subtitle: context.l10n.groupsToTransferSubtitle,
                  ),
                  const SizedBox(height: 8),
                  ...suggestions.map(
                    (s) => _SuggestionTile(
                      suggestion: s,
                      groupId: groupId,
                      isMine: s.fromUserId == me,
                    ),
                  ),
                  const SizedBox(height: 28),
                ],
                _SectionHeader(context.l10n.groupsPerPersonDetail),
                const SizedBox(height: 8),
                ...balances.map(
                  (b) => _BalanceTile(balance: b, isMe: b.userId == me),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showHistory(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.colors.surface,
      isScrollControlled: true,
      builder: (_) => _SettlementHistorySheet(groupId: groupId),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title, {this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: context.colors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (subtitle != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              subtitle!,
              style: TextStyle(
                color: context.colors.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}

class _AllSettledCard extends StatelessWidget {
  const _AllSettledCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: context.colors.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        child: Column(
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 44,
              color: context.colors.income.withValues(alpha: 0.9),
            ),
            const SizedBox(height: 12),
            Text(
              context.l10n.groupsNobodyOwes,
              style: TextStyle(
                color: context.colors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              context.l10n.groupsAllBalanced,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.colors.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionTile extends ConsumerStatefulWidget {
  const _SuggestionTile({
    required this.suggestion,
    required this.groupId,
    required this.isMine,
  });

  final SettlementSuggestion suggestion;
  final String groupId;
  final bool isMine;

  @override
  ConsumerState<_SuggestionTile> createState() => _SuggestionTileState();
}

class _SuggestionTileState extends ConsumerState<_SuggestionTile> {
  bool _saving = false;

  Future<void> _confirm() async {
    final s = widget.suggestion;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.colors.surface,
        title: Text(context.l10n.groupsRecordPayment),
        content: Text(
          context.l10n.groupsConfirmPaymentBody(
            FormatHelpers.currency(s.amount),
            s.toName,
          ),
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
            child: Text(context.l10n.groupsMarkPaid),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _saving = true);
    final result = await ref
        .read(groupRepositoryProvider)
        .settleUp(
          groupId: widget.groupId,
          toUserId: s.toUserId,
          amount: s.amount,
        );
    if (!mounted) return;
    setState(() => _saving = false);

    if (result.isErr) {
      showResultSnackBar(
        context,
        message: result.errorOrNull ?? context.l10n.groupsRecordFailed,
        isError: true,
      );
      return;
    }
    ref.read(settlementVersionProvider.notifier).state++;
    showResultSnackBar(context, message: context.l10n.groupsPaymentRecorded);
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.suggestion;
    return Card(
      color: context.colors.surface,
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          widget.isMine ? context.l10n.groupsYou : s.fromName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: context.colors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(
                          Icons.arrow_forward,
                          size: 15,
                          color: context.colors.textTertiary,
                        ),
                      ),
                      Flexible(
                        child: Text(
                          s.toName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: context.colors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    FormatHelpers.currency(s.amount),
                    style: TextStyle(
                      color: context.colors.primary,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            if (widget.isMine)
              _saving
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : FilledButton(
                      onPressed: _confirm,
                      style: FilledButton.styleFrom(
                        backgroundColor: context.colors.primary,
                        foregroundColor: context.colors.onPrimary,
                        minimumSize: const Size(0, 40),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      child: Text(context.l10n.groupsMarkPaid),
                    ),
          ],
        ),
      ),
    );
  }
}

class _BalanceTile extends StatelessWidget {
  const _BalanceTile({required this.balance, required this.isMe});

  final GroupBalance balance;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final net = balance.net;
    final label = balance.isSettled
        ? context.l10n.groupsSettled
        : (net > 0
              ? context.l10n.groupsToReceive(FormatHelpers.currency(net))
              : context.l10n.groupsStillOwes(FormatHelpers.currency(-net)));

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: CircleAvatar(
        backgroundColor: context.colors.surfaceVariant,
        child: Text(
          balance
              .displayNameOr(context.l10n.memberFallback)
              .characters
              .first
              .toUpperCase(),
          style: TextStyle(color: context.colors.textSecondary),
        ),
      ),
      title: Text(
        isMe
            ? context.l10n.groupsNameYou(
                balance.displayNameOr(context.l10n.memberFallback),
              )
            : balance.displayNameOr(context.l10n.memberFallback),
        style: TextStyle(color: context.colors.textPrimary, fontSize: 15),
      ),
      subtitle: Text(
        context.l10n.groupsPaidShare(
          FormatHelpers.currency(balance.paid),
          FormatHelpers.currency(balance.owed),
        ),
        style: TextStyle(color: context.colors.textSecondary, fontSize: 12),
      ),
      trailing: Text(
        label,
        style: TextStyle(
          color: context.colors.forNet(net),
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SettlementHistorySheet extends ConsumerWidget {
  const _SettlementHistorySheet({required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settlementsAsync = ref.watch(settlementsProvider(groupId));

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (context, scrollController) => Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: context.colors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              context.l10n.groupsSettlementHistory,
              style: TextStyle(
                color: context.colors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: settlementsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => AsyncErrorView(error: e),
              data: (list) {
                if (list.isEmpty) {
                  return AsyncEmptyView(
                    icon: Icons.history,
                    title: context.l10n.groupsNoSettlements,
                    message: context.l10n.groupsSettlementsEmptyHint,
                  );
                }
                return ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final s = list[i];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        context.l10n.groupsFromTo(s.fromName, s.toName),
                        style: TextStyle(
                          color: context.colors.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        FormatHelpers.dateTime(s.settledAt),
                        style: TextStyle(
                          color: context.colors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      trailing: Text(
                        FormatHelpers.currency(s.amount),
                        style: TextStyle(
                          color: context.colors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
