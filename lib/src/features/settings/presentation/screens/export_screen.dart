import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spend_sync/src/core/l10n/l10n.dart';

import '../../../../core/constants/app_palette.dart';
import '../../../../core/errors/error_l10n.dart';
import '../../../../core/utils/format_helpers.dart';
import '../../../accounts/domain/account.dart';
import '../../../accounts/presentation/providers/accounts_provider.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../../../groups/presentation/providers/active_group_provider.dart';
import '../../../shared/presentation/widgets/async_states.dart';
import '../../../transactions/data/transaction_repository.dart';
import '../../../transactions/presentation/providers/transactions_provider.dart';
import '../../data/export_service.dart';

class ExportScreen extends ConsumerStatefulWidget {
  const ExportScreen({super.key});

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  DateTimeRange? _range;
  bool _exporting = false;

  /// Tải tối đa 5000 giao dịch — đủ cho nhiều năm dùng cá nhân, và vẫn nằm
  /// trong giới hạn bộ nhớ an toàn của thiết bị.
  static const _maxRows = 5000;

  Future<void> _export() async {
    final group = ref.read(activeGroupProvider);
    if (group == null) {
      showResultSnackBar(
        context,
        message: context.l10n.settingsExportNoGroup,
        isError: true,
      );
      return;
    }

    // Chụp l10n trước các await — context có thể unmount giữa chừng.
    final l10n = context.l10n;
    setState(() => _exporting = true);
    try {
      final transactions = await ref
          .read(transactionRepositoryProvider)
          .getTransactions(
            TransactionQuery(
              groupId: group.id,
              from: _range?.start,
              to: _range?.end,
              limit: _maxRows,
            ),
          );

      final categories = await ref.read(categoryMapProvider.future);
      final accountList = await ref.read(accountsListProvider.future);
      final accounts = {for (final a in accountList) a.id: a};

      final csv = ExportService.buildCsv(
        transactions: transactions,
        categories: categories,
        accounts: accounts,
        l10n: l10n,
      );

      if (!mounted) return;
      final result = await ExportService.shareCsv(
        csv: csv,
        fileName: ExportService.suggestedFileName(),
        l10n: l10n,
      );

      if (!mounted) return;
      setState(() => _exporting = false);

      showResultSnackBar(
        context,
        message:
            result.localizedErrorOrNull(l10n) ??
            l10n.settingsExportSuccess(transactions.length),
        isError: result.isErr,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _exporting = false);
      showResultSnackBar(
        context,
        message: localizedError(l10n, e),
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final group = ref.watch(activeGroupProvider);
    final accountsAsync = ref.watch(accountsListProvider);

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: context.colors.background,
        title: Text(context.l10n.settingsExportData),
        leading: IconButton(
          tooltip: context.l10n.settingsBack,
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: context.colors.surface,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.table_chart_outlined,
                    color: context.colors.primary,
                    size: 28,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    context.l10n.settingsExportCsvTitle,
                    style: TextStyle(
                      color: context.colors.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.l10n.settingsExportCsvDesc,
                    style: TextStyle(
                      color: context.colors.textSecondary,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    context.l10n.settingsExportGroupLabel(group?.name ?? '—'),
                    style: TextStyle(
                      color: context.colors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              Icons.date_range,
              color: context.colors.textSecondary,
            ),
            title: Text(context.l10n.settingsExportDateRange),
            subtitle: Text(
              _range == null
                  ? context.l10n.settingsExportAllHistory
                  : FormatHelpers.dateRange(_range!.start, _range!.end),
              style: TextStyle(
                color: context.colors.textSecondary,
                fontSize: 12,
              ),
            ),
            trailing: _range == null
                ? const Icon(Icons.chevron_right)
                : IconButton(
                    tooltip: context.l10n.settingsExportClearRange,
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () => setState(() => _range = null),
                  ),
            onTap: () async {
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2000),
                lastDate: DateTime.now(),
                initialDateRange: _range,
              );
              if (picked != null) setState(() => _range = picked);
            },
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _exporting ? null : _export,
            icon: _exporting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.ios_share),
            label: Text(
              _exporting
                  ? context.l10n.settingsExportPreparing
                  : context.l10n.settingsExportShare,
            ),
            style: FilledButton.styleFrom(
              backgroundColor: context.colors.primary,
              foregroundColor: context.colors.onPrimary,
              minimumSize: const Size(0, 52),
            ),
          ),
          const SizedBox(height: 24),
          accountsAsync.when(
            loading: () => const SizedBox.shrink(),
            // Không tải được danh sách ví thì không biết có đa tiền tệ không —
            // hiện lỗi gọn thay vì nuốt trong im lặng.
            error: (e, _) => AsyncErrorView(error: e, compact: true),
            data: (accounts) => _CurrencyWarning(accounts: accounts),
          ),
          const SizedBox(height: 12),
          Text(
            context.l10n.settingsExportMaxRowsNote,
            style: TextStyle(color: context.colors.textTertiary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

/// Cảnh báo khi ví đang dùng nhiều đơn vị tiền tệ — cột "Số tiền" trong CSV
/// khi đó không cộng thẳng lại được.
class _CurrencyWarning extends StatelessWidget {
  const _CurrencyWarning({required this.accounts});

  final List<Account> accounts;

  @override
  Widget build(BuildContext context) {
    final currencies = accounts.map((a) => a.currency).toSet();
    if (currencies.length <= 1) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: context.colors.warning.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: context.colors.warning, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              context.l10n.settingsExportCurrencyWarning(
                currencies.length,
                currencies.join(', '),
              ),
              style: TextStyle(
                color: context.colors.textSecondary,
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
