import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spend_sync/src/core/l10n/l10n.dart';

import '../../../../core/constants/app_palette.dart';
import '../../../../core/errors/error_l10n.dart';
import '../../../../core/utils/format_helpers.dart';
import '../../../groups/presentation/providers/active_group_provider.dart';
import '../../../shared/presentation/widgets/async_states.dart';
import '../../../transactions/presentation/providers/transactions_provider.dart';
import '../../../transactions/presentation/widgets/account_selector.dart';
import '../../data/account_service.dart';
import '../../domain/account.dart';
import '../providers/accounts_provider.dart';

final accountServiceProvider = Provider<AccountService>((ref) {
  return AccountService(
    accountRepository: ref.read(accountRepositoryProvider),
    transactionRepository: ref.read(transactionRepositoryProvider),
  );
});

class ManageAccountsScreen extends ConsumerWidget {
  const ManageAccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(allAccountsProvider);

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: context.colors.background,
        title: Text(context.l10n.accountsTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: context.l10n.accountsBack,
          onPressed: () => context.pop(),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await showCreateAccountDialog(context);
          if (created != null) {
            ref.read(accountVersionProvider.notifier).state++;
          }
        },
        backgroundColor: context.colors.primary,
        foregroundColor: context.colors.onPrimary,
        icon: const Icon(Icons.add),
        label: Text(context.l10n.accountsAddWallet),
      ),
      body: accountsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => AsyncErrorView(
          error: e,
          onRetry: () => ref.read(accountVersionProvider.notifier).state++,
        ),
        data: (accounts) {
          final active = accounts.where((a) => a.isActive).toList();
          final archived = accounts.where((a) => !a.isActive).toList();

          if (accounts.isEmpty) {
            return AsyncEmptyView(
              icon: Icons.account_balance_wallet_outlined,
              title: context.l10n.accountsEmptyTitle,
              message: context.l10n.accountsEmptyMessage,
              actionLabel: context.l10n.accountsAddWallet,
              onAction: () async {
                final created = await showCreateAccountDialog(context);
                if (created != null) {
                  ref.read(accountVersionProvider.notifier).state++;
                }
              },
            );
          }

          final assets = active.where((a) => a.isAsset).toList();
          final liabilities = active.where((a) => a.isLiability).toList();

          return RefreshIndicator(
            onRefresh: () async {
              ref.read(accountVersionProvider.notifier).state++;
              await ref.read(allAccountsProvider.future);
            },
            child: ListView(
              // Cho phép kéo-làm-mới cả khi danh sách ngắn hơn màn hình.
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              children: [
                if (assets.isNotEmpty) ...[
                  _GroupLabel(context.l10n.accountsGroupAssets),
                  ...assets.map((a) => _AccountCard(account: a)),
                  const SizedBox(height: 16),
                ],
                if (liabilities.isNotEmpty) ...[
                  _GroupLabel(context.l10n.accountsGroupLiabilities),
                  ...liabilities.map((a) => _AccountCard(account: a)),
                  const SizedBox(height: 16),
                ],
                if (archived.isNotEmpty) ...[
                  _GroupLabel(context.l10n.accountsGroupArchived),
                  ...archived.map((a) => _AccountCard(account: a)),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
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

class _AccountCard extends ConsumerWidget {
  const _AccountCard({required this.account});

  final Account account;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final creditLeft = account.availableCredit;

    return Card(
      color: context.colors.surface,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: context.colors.surfaceVariant,
          child: Icon(
            account.isShared
                ? Icons.groups
                : (account.isLiability
                      ? Icons.credit_card
                      : Icons.account_balance_wallet),
            color: account.isActive
                ? context.colors.primary
                : context.colors.textTertiary,
            size: 20,
          ),
        ),
        // Wrap để tên dài không đẩy nhãn tràn hàng: nhãn tự xuống dòng dưới.
        title: Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              account.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: account.isActive
                    ? context.colors.textPrimary
                    : context.colors.textTertiary,
              ),
            ),
            if (account.isShared) _Badge(context.l10n.accountsBadgeShared),
            if (!account.includeInTotal)
              _Badge(context.l10n.accountsBadgeExcluded),
          ],
        ),
        subtitle: Text(
          [
            account.currency,
            if (creditLeft != null)
              context.l10n.accountsCreditLeft(
                FormatHelpers.currency(creditLeft, currency: account.currency),
              ),
            if (account.paymentDate != null)
              context.l10n.accountsPayDay(account.paymentDate!),
          ].join(' · '),
          style: TextStyle(color: context.colors.textSecondary, fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              FormatHelpers.currency(
                account.balance,
                currency: account.currency,
              ),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: account.isLiability
                    ? context.colors.expense
                    : context.colors.textPrimary,
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.more_vert, size: 20),
              tooltip: context.l10n.accountsMoreActions,
              onPressed: () => _showActions(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  void _showActions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.colors.surface,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (account.isActive) ...[
              ListTile(
                leading: const Icon(Icons.edit),
                title: Text(context.l10n.accountsEditWallet),
                onTap: () {
                  Navigator.of(ctx).pop();
                  showDialog<void>(
                    context: context,
                    builder: (_) => _EditAccountDialog(account: account),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.tune),
                title: Text(context.l10n.accountsAdjustBalance),
                subtitle: Text(
                  context.l10n.accountsAdjustBalanceSubtitle,
                  style: TextStyle(
                    color: context.colors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  showDialog<void>(
                    context: context,
                    builder: (_) => _AdjustBalanceDialog(account: account),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.fact_check_outlined),
                title: Text(context.l10n.accountsReconcile),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  final result = await ref
                      .read(accountRepositoryProvider)
                      .recalcAccount(account.id);
                  ref.read(accountVersionProvider.notifier).state++;
                  if (context.mounted) {
                    showResultSnackBar(
                      context,
                      message:
                          result.localizedErrorOrNull(context.l10n) ??
                          context.l10n.accountsReconcileResult(
                            FormatHelpers.currency(result.valueOrNull ?? 0),
                          ),
                      isError: result.isErr,
                    );
                  }
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.archive_outlined,
                  color: context.colors.warning,
                ),
                title: Text(context.l10n.accountsArchive),
                subtitle: Text(
                  context.l10n.accountsArchiveSubtitle,
                  style: TextStyle(
                    color: context.colors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  final result = await ref
                      .read(accountServiceProvider)
                      .archive(account.id);
                  ref.read(accountVersionProvider.notifier).state++;
                  if (context.mounted) {
                    showResultSnackBar(
                      context,
                      message:
                          result.localizedErrorOrNull(context.l10n) ??
                          context.l10n.accountsArchived,
                      isError: result.isErr,
                    );
                  }
                },
              ),
            ] else
              ListTile(
                leading: const Icon(Icons.unarchive_outlined),
                title: Text(context.l10n.accountsRestore),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  final result = await ref
                      .read(accountServiceProvider)
                      .restore(account.id);
                  ref.read(accountVersionProvider.notifier).state++;
                  if (context.mounted) {
                    showResultSnackBar(
                      context,
                      message:
                          result.localizedErrorOrNull(context.l10n) ??
                          context.l10n.accountsRestored,
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

class _Badge extends StatelessWidget {
  const _Badge(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: context.colors.surfaceVariant,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(color: context.colors.textTertiary, fontSize: 10),
      ),
    );
  }
}

// -----------------------------------------------------------------------------

class _EditAccountDialog extends ConsumerStatefulWidget {
  const _EditAccountDialog({required this.account});
  final Account account;

  @override
  ConsumerState<_EditAccountDialog> createState() => _EditAccountDialogState();
}

class _EditAccountDialogState extends ConsumerState<_EditAccountDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _creditController;
  late String _currency;
  late bool _includeInTotal;
  int? _statementDate;
  int? _paymentDate;
  bool _saving = false;
  String? _error;

  Account get _a => widget.account;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: _a.name);
    _creditController = TextEditingController(
      text: _a.creditLimit > 0 ? FormatHelpers.amount(_a.creditLimit) : '',
    );
    _currency = _a.currency;
    _includeInTotal = _a.includeInTotal;
    _statementDate = _a.statementDate;
    _paymentDate = _a.paymentDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _creditController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    final result = await ref
        .read(accountRepositoryProvider)
        .updateAccount(
          _a.id,
          name: _nameController.text.trim(),
          currency: _currency,
          creditLimit: FormatHelpers.parseAmount(_creditController.text) ?? 0,
          statementDate: _statementDate,
          paymentDate: _paymentDate,
          includeInTotal: _includeInTotal,
        );
    if (!mounted) return;
    setState(() => _saving = false);

    if (result.isErr) {
      setState(() => _error = result.localizedErrorOrNull(context.l10n));
      return;
    }
    ref.read(accountVersionProvider.notifier).state++;
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: context.colors.surface,
      // Cuộn được khi bàn phím che bớt chiều cao, tránh khuất ô đang gõ.
      scrollable: true,
      title: Text(context.l10n.accountsEditWallet),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: context.l10n.accountsNameLabel,
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _currency,
                decoration: InputDecoration(
                  labelText: context.l10n.accountsCurrencyLabel,
                ),
                dropdownColor: context.colors.surface,
                items: [
                  for (final c in kSupportedCurrencies)
                    DropdownMenuItem(
                      value: c.code,
                      child: Text('${c.code} — ${c.symbol}'),
                    ),
                ],
                onChanged: (v) => setState(() => _currency = v ?? _currency),
              ),
              if (_a.isLiability) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _creditController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [AmountInputFormatter()],
                  decoration: InputDecoration(
                    labelText: context.l10n.accountsCreditLimitLabel,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _DayDropdown(
                        label: context.l10n.accountsStatementDay,
                        value: _statementDate,
                        onChanged: (v) => setState(() => _statementDate = v),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _DayDropdown(
                        label: context.l10n.accountsPaymentDay,
                        value: _paymentDate,
                        onChanged: (v) => setState(() => _paymentDate = v),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _includeInTotal,
                activeThumbColor: context.colors.primary,
                title: Text(
                  context.l10n.accountsIncludeNetWorth,
                  style: const TextStyle(fontSize: 14),
                ),
                onChanged: (v) => setState(() => _includeInTotal = v),
              ),
              if (_error != null)
                Text(
                  _error!,
                  style: TextStyle(color: context.colors.expense, fontSize: 13),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: Text(context.l10n.actionCancel),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          style: FilledButton.styleFrom(
            backgroundColor: context.colors.primary,
            foregroundColor: context.colors.onPrimary,
          ),
          child: Text(context.l10n.actionSave),
        ),
      ],
    );
  }
}

class _DayDropdown extends StatelessWidget {
  const _DayDropdown({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int? value;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      dropdownColor: context.colors.surface,
      items: [
        for (var d = 1; d <= 31; d++)
          DropdownMenuItem(value: d, child: Text('$d')),
      ],
      onChanged: onChanged,
    );
  }
}

// -----------------------------------------------------------------------------

class _AdjustBalanceDialog extends ConsumerStatefulWidget {
  const _AdjustBalanceDialog({required this.account});
  final Account account;

  @override
  ConsumerState<_AdjustBalanceDialog> createState() =>
      _AdjustBalanceDialogState();
}

class _AdjustBalanceDialogState extends ConsumerState<_AdjustBalanceDialog> {
  late final TextEditingController _controller;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: FormatHelpers.amount(widget.account.balance),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final target = FormatHelpers.parseAmount(_controller.text);
    if (target == null) {
      setState(() => _error = context.l10n.accountsInvalidBalance);
      return;
    }
    final group = ref.read(activeGroupProvider);
    if (group == null) {
      setState(() => _error = context.l10n.accountsNoGroup);
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    final result = await ref
        .read(accountServiceProvider)
        .adjustBalance(
          account: widget.account,
          targetBalance: target,
          groupId: group.id,
          // Ghi chú của giao dịch điều chỉnh theo ngôn ngữ đang chọn.
          note: context.l10n.accountsAdjustBalance,
        );
    if (!mounted) return;
    setState(() => _saving = false);

    if (result.isErr) {
      setState(() => _error = result.localizedErrorOrNull(context.l10n));
      return;
    }
    ref.read(transactionVersionProvider.notifier).state++;
    ref.read(accountVersionProvider.notifier).state++;
    if (mounted) {
      Navigator.of(context).pop();
      showResultSnackBar(
        context,
        message: context.l10n.accountsAdjustmentRecorded,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = widget.account.balance;
    final target = FormatHelpers.parseAmount(_controller.text) ?? current;
    final diff = target - current;

    return AlertDialog(
      backgroundColor: context.colors.surface,
      // Cuộn được khi bàn phím che bớt chiều cao, tránh khuất ô đang gõ.
      scrollable: true,
      title: Text(context.l10n.accountsAdjustBalance),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.l10n.accountsCurrentBalance(
                  FormatHelpers.currency(
                    current,
                    currency: widget.account.currency,
                  ),
                ),
                style: TextStyle(
                  color: context.colors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  AmountInputFormatter(currencyCode: widget.account.currency),
                ],
                decoration: InputDecoration(
                  labelText: context.l10n.accountsActualBalance,
                ),
                onChanged: (_) => setState(() {}),
              ),
              if (diff.abs() >= 0.005) ...[
                const SizedBox(height: 12),
                Text(
                  diff > 0
                      ? context.l10n.accountsWillRecordIncome(
                          FormatHelpers.currency(
                            diff.abs(),
                            currency: widget.account.currency,
                          ),
                        )
                      : context.l10n.accountsWillRecordExpense(
                          FormatHelpers.currency(
                            diff.abs(),
                            currency: widget.account.currency,
                          ),
                        ),
                  style: TextStyle(
                    color: diff > 0
                        ? context.colors.income
                        : context.colors.expense,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                context.l10n.accountsAdjustNote,
                style: TextStyle(
                  color: context.colors.textTertiary,
                  fontSize: 12,
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: TextStyle(color: context.colors.expense, fontSize: 13),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: Text(context.l10n.actionCancel),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          style: FilledButton.styleFrom(
            backgroundColor: context.colors.primary,
            foregroundColor: context.colors.onPrimary,
          ),
          child: Text(context.l10n.accountsRecordAdjustment),
        ),
      ],
    );
  }
}
