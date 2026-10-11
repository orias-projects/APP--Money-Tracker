import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spend_sync/src/core/l10n/l10n.dart';

import '../../../../core/constants/app_palette.dart';
import '../../../../core/utils/format_helpers.dart';
import '../../../../shell/shell_app_bar_provider.dart';
import '../../../accounts/domain/account.dart';
import '../../../accounts/presentation/providers/accounts_provider.dart';
import '../../../shared/presentation/widgets/async_states.dart';
import '../../../transactions/presentation/widgets/account_selector.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountsListProvider);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // const → canonical hoá: setTitle so bằng và bỏ qua, shell không rebuild.
      ref
          .read(shellAppBarTitleProvider.notifier)
          .setTitle(3, const _ReportsShellTitle());
    });

    return Scaffold(
      backgroundColor: context.colors.background,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.read(accountVersionProvider.notifier).state++;
          await ref.read(accountsListProvider.future);
        },
        child: accountsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(
            children: [
              SizedBox(height: MediaQuery.sizeOf(context).height * 0.25),
              AsyncErrorView(
                error: e,
                onRetry: () =>
                    ref.read(accountVersionProvider.notifier).state++,
              ),
            ],
          ),
          data: (accounts) {
            final active = accounts.where((a) => a.isActive).toList();

            if (active.isEmpty) {
              return ListView(
                children: [
                  SizedBox(height: MediaQuery.sizeOf(context).height * 0.2),
                  AsyncEmptyView(
                    icon: Icons.account_balance_wallet_outlined,
                    title: context.l10n.reportsNoWalletsTitle,
                    message: context.l10n.reportsNoWalletsMessage,
                    actionLabel: context.l10n.reportsAddWallet,
                    onAction: () async {
                      final created = await showCreateAccountDialog(context);
                      if (created != null) {
                        ref.read(accountVersionProvider.notifier).state++;
                      }
                    },
                  ),
                ],
              );
            }

            // Chỉ cộng những ví được đánh dấu tính vào tổng.
            final counted = active.where((a) => a.includeInTotal).toList();
            final byCurrency = _groupByCurrency(counted);

            final assets = active.where((a) => a.isAsset).toList();
            final liabilities = active.where((a) => a.isLiability).toList();

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              children: [
                ...byCurrency.entries.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _NetWorthCard(
                      currency: e.key,
                      totals: e.value,
                      showCurrencyLabel: byCurrency.length > 1,
                    ),
                  ),
                ),
                if (byCurrency.length > 1) const _MultiCurrencyNote(),
                const SizedBox(height: 20),
                if (assets.isNotEmpty) ...[
                  _SectionTitle(context.l10n.reportsAssets),
                  const SizedBox(height: 8),
                  ...assets.map((a) => _AccountTile(account: a)),
                  const SizedBox(height: 20),
                ],
                if (liabilities.isNotEmpty) ...[
                  _SectionTitle(context.l10n.reportsLiabilitiesSection),
                  const SizedBox(height: 8),
                  ...liabilities.map((a) => _AccountTile(account: a)),
                  const SizedBox(height: 20),
                ],
                OutlinedButton.icon(
                  onPressed: () => context.push('/me/accounts'),
                  icon: const Icon(Icons.tune, size: 18),
                  label: Text(context.l10n.reportsManageWallets),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.colors.textSecondary,
                    side: BorderSide(color: context.colors.divider),
                    minimumSize: const Size(0, 48),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () async {
                    final created = await showCreateAccountDialog(context);
                    if (created != null) {
                      ref.read(accountVersionProvider.notifier).state++;
                    }
                  },
                  icon: const Icon(Icons.add),
                  label: Text(context.l10n.reportsAddWallet),
                  style: FilledButton.styleFrom(
                    backgroundColor: context.colors.primary,
                    foregroundColor: context.colors.onPrimary,
                    minimumSize: const Size(0, 52),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Gom theo đơn vị tiền tệ.
  ///
  /// Trước đây màn này cộng thẳng `balance` của mọi ví bất kể đơn vị — 100 USD
  /// cộng 100 VND ra 200. Giờ mỗi đơn vị có một thẻ tài sản ròng riêng.
  static Map<String, _Totals> _groupByCurrency(List<Account> accounts) {
    final map = <String, _Totals>{};
    for (final a in accounts) {
      final totals = map.putIfAbsent(a.currency, () => _Totals());
      if (a.isAsset) {
        totals.assets += a.balance;
      } else {
        totals.liabilities += a.balance;
      }
    }
    return map;
  }
}

class _Totals {
  double assets = 0;
  double liabilities = 0;
  double get net => assets - liabilities;
}

class _NetWorthCard extends StatelessWidget {
  const _NetWorthCard({
    required this.currency,
    required this.totals,
    required this.showCurrencyLabel,
  });

  final String currency;
  final _Totals totals;
  final bool showCurrencyLabel;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: context.colors.surface,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  context.l10n.reportsNetWorth,
                  style: TextStyle(
                    color: context.colors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                if (showCurrencyLabel) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: context.colors.surfaceVariant,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      currency,
                      style: TextStyle(
                        color: context.colors.textTertiary,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Text(
              FormatHelpers.currency(totals.net, currency: currency),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: totals.net >= 0
                    ? context.colors.textPrimary
                    : context.colors.expense,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _Stat(
                    label: context.l10n.reportsAssets,
                    value: totals.assets,
                    currency: currency,
                    color: context.colors.income,
                  ),
                ),
                Expanded(
                  child: _Stat(
                    label: context.l10n.reportsDebt,
                    value: totals.liabilities,
                    currency: currency,
                    color: context.colors.expense,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.value,
    required this.currency,
    required this.color,
  });

  final String label;
  final double value;
  final String currency;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: context.colors.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          FormatHelpers.currency(value, currency: currency),
          style: TextStyle(color: color, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _MultiCurrencyNote extends StatelessWidget {
  const _MultiCurrencyNote();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            size: 15,
            color: context.colors.textTertiary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              context.l10n.reportsMultiCurrencyNote,
              style: TextStyle(
                color: context.colors.textTertiary,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        color: context.colors.textTertiary,
        fontSize: 11,
        letterSpacing: 1.1,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _AccountTile extends StatelessWidget {
  const _AccountTile({required this.account});

  final Account account;

  @override
  Widget build(BuildContext context) {
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
            color: context.colors.primary,
            size: 20,
          ),
        ),
        title: Text(
          account.name,
          style: TextStyle(color: context.colors.textPrimary),
        ),
        subtitle: !account.includeInTotal
            ? Text(
                context.l10n.reportsNotCountedInNetWorth,
                style: TextStyle(
                  color: context.colors.textTertiary,
                  fontSize: 12,
                ),
              )
            : (creditLeft != null
                  ? Text(
                      context.l10n.reportsCreditLeft(
                        FormatHelpers.currency(
                          creditLeft,
                          currency: account.currency,
                        ),
                      ),
                      style: TextStyle(
                        color: context.colors.textSecondary,
                        fontSize: 12,
                      ),
                    )
                  : null),
        trailing: Text(
          FormatHelpers.currency(account.balance, currency: account.currency),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: account.isLiability
                ? context.colors.expense
                : context.colors.textPrimary,
          ),
        ),
      ),
    );
  }
}

/// Tieu de tab tren thanh shell — const de setTitle canonical hoa va bo qua,
/// doi ngon ngu/theme van tu cap nhat vi l10n/mau doc trong build.
class _ReportsShellTitle extends StatelessWidget {
  const _ReportsShellTitle();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Text(
        context.l10n.reportsTitle,
        style: TextStyle(
          color: context.colors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
