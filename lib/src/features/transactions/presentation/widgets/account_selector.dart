import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spend_sync/src/core/l10n/l10n.dart';

import '../../../../core/constants/app_palette.dart';
import '../../../../core/utils/format_helpers.dart';
import '../../../accounts/domain/account.dart';
import '../../../accounts/presentation/providers/accounts_provider.dart';
import '../../../groups/presentation/providers/active_group_provider.dart';
import '../../../shared/presentation/widgets/async_states.dart';

/// Chọn ví, kèm lối tắt tạo ví mới ngay trong danh sách.
class AccountSelector extends ConsumerWidget {
  const AccountSelector({
    super.key,
    required this.label,
    required this.accounts,
    required this.value,
    required this.onChanged,
    this.excludeId,
  });

  final String label;
  final List<Account> accounts;
  final Account? value;
  final ValueChanged<Account?> onChanged;

  /// Ẩn ví này khỏi danh sách (ví nguồn khi đang chọn ví đích).
  final String? excludeId;

  static const _createSentinel = '__create__';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final options = accounts
        .where((a) => a.id != excludeId && a.isActive)
        .toList();

    // Giá trị đang chọn có thể vừa bị loại khỏi danh sách (trùng ví đích).
    final selectedId = options.any((a) => a.id == value?.id) ? value?.id : null;

    if (options.isEmpty) {
      return _EmptyAccountsPrompt(
        label: label,
        onCreate: () => _showCreateDialog(context, ref),
      );
    }

    return DropdownButtonFormField<String>(
      initialValue: selectedId,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      dropdownColor: context.colors.surface,
      items: [
        for (final a in options)
          DropdownMenuItem(
            value: a.id,
            child: _AccountRow(account: a),
          ),
        DropdownMenuItem(
          value: _createSentinel,
          child: Row(
            children: [
              Icon(Icons.add, size: 18, color: context.colors.primary),
              const SizedBox(width: 8),
              Text(
                context.l10n.accountSelCreateNew,
                style: TextStyle(color: context.colors.primary),
              ),
            ],
          ),
        ),
      ],
      onChanged: (id) {
        if (id == null) return;
        if (id == _createSentinel) {
          _showCreateDialog(context, ref);
          return;
        }
        onChanged(options.firstWhere((a) => a.id == id));
      },
    );
  }

  Future<void> _showCreateDialog(BuildContext context, WidgetRef ref) async {
    final created = await showDialog<Account>(
      context: context,
      builder: (_) => const _CreateAccountDialog(),
    );
    if (created != null) onChanged(created);
  }
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({required this.account});
  final Account account;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          account.isShared
              ? Icons.groups
              : (account.isLiability
                    ? Icons.credit_card
                    : Icons.account_balance_wallet),
          size: 18,
          color: context.colors.textSecondary,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            account.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: context.colors.textPrimary, fontSize: 15),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          FormatHelpers.currency(account.balance, currency: account.currency),
          style: TextStyle(color: context.colors.textSecondary, fontSize: 13),
        ),
      ],
    );
  }
}

class _EmptyAccountsPrompt extends StatelessWidget {
  const _EmptyAccountsPrompt({required this.label, required this.onCreate});

  final String label;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(labelText: label),
      child: Row(
        children: [
          Expanded(
            child: Text(
              context.l10n.accountsEmptyTitle,
              style: TextStyle(
                color: context.colors.textSecondary,
                fontSize: 15,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add, size: 18),
            label: Text(context.l10n.accountSelCreate),
            style: TextButton.styleFrom(
              foregroundColor: context.colors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Tạo ví nhanh: tên, loại, số dư ban đầu, và (trong nhóm chung) ví dùng chung.
class _CreateAccountDialog extends ConsumerStatefulWidget {
  const _CreateAccountDialog();

  @override
  ConsumerState<_CreateAccountDialog> createState() =>
      _CreateAccountDialogState();
}

class _CreateAccountDialogState extends ConsumerState<_CreateAccountDialog> {
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();
  String _accountType = 'asset';
  bool _shared = false;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = context.l10n.accountSelEnterName);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });

    final group = ref.read(activeGroupProvider);
    final result = await ref
        .read(accountRepositoryProvider)
        .addAccount(
          name: name,
          accountType: _accountType,
          openingBalance:
              FormatHelpers.parseAmount(_balanceController.text) ?? 0,
          groupId: (_shared && group != null && !group.isPersonal)
              ? group.id
              : null,
        );

    if (!mounted) return;
    setState(() => _saving = false);

    final account = result.valueOrNull;
    if (account == null) {
      setState(() => _error = result.errorOrNull);
      return;
    }
    ref.read(accountVersionProvider.notifier).state++;
    if (mounted) Navigator.of(context).pop(account);
  }

  @override
  Widget build(BuildContext context) {
    final group = ref.watch(activeGroupProvider);
    final canShare = group != null && !group.isPersonal;

    return AlertDialog(
      backgroundColor: context.colors.surface,
      title: Text(context.l10n.accountSelCreateNew),
      content: SizedBox(
        width: 340,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _nameController,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: context.l10n.accountsNameLabel,
                  hintText: context.l10n.accountSelNameHint,
                ),
              ),
              const SizedBox(height: 16),
              SegmentedButton<String>(
                segments: [
                  ButtonSegment(
                    value: 'asset',
                    label: Text(context.l10n.accountsGroupAssets),
                    icon: const Icon(Icons.account_balance_wallet, size: 16),
                  ),
                  ButtonSegment(
                    value: 'liability',
                    label: Text(context.l10n.accountSelTypeLiability),
                    icon: const Icon(Icons.credit_card, size: 16),
                  ),
                ],
                selected: {_accountType},
                onSelectionChanged: (s) =>
                    setState(() => _accountType = s.first),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _balanceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [AmountInputFormatter()],
                decoration: InputDecoration(
                  labelText: _accountType == 'liability'
                      ? context.l10n.accountSelAmountOwed
                      : context.l10n.accountSelCurrentBalance,
                  helperText: _accountType == 'liability'
                      ? context.l10n.accountSelOwedHelper
                      : null,
                ),
              ),
              if (canShare) ...[
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _shared,
                  onChanged: (v) => setState(() => _shared = v),
                  activeThumbColor: context.colors.primary,
                  title: Text(
                    context.l10n.accountSelSharedWallet,
                    style: const TextStyle(fontSize: 14),
                  ),
                  subtitle: Text(
                    context.l10n.accountSelSharedSubtitle(group.name),
                    style: TextStyle(
                      fontSize: 12,
                      color: context.colors.textSecondary,
                    ),
                  ),
                ),
              ],
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
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(context.l10n.accountSelCreateAction),
        ),
      ],
    );
  }
}

/// Dùng ở nơi cần mở hộp thoại tạo ví từ ngoài (màn Quản lý ví).
Future<Account?> showCreateAccountDialog(BuildContext context) {
  return showDialog<Account>(
    context: context,
    builder: (_) => const _CreateAccountDialog(),
  );
}

/// Hiện lỗi tải danh sách ví ở dạng gọn.
class AccountsErrorRow extends StatelessWidget {
  const AccountsErrorRow({super.key, required this.error, this.onRetry});

  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) =>
      AsyncErrorView(error: error, onRetry: onRetry, compact: true);
}
