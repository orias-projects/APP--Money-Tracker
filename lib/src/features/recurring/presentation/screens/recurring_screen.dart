import '../../../categories/domain/category_label.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spend_sync/src/core/l10n/enum_labels.dart';
import 'package:spend_sync/src/core/l10n/l10n.dart';

import '../../../../core/constants/app_palette.dart';
import '../../../../core/errors/error_l10n.dart';
import '../../../../core/utils/category_icons.dart';
import '../../../../core/utils/format_helpers.dart';
import '../../../accounts/domain/account.dart';
import '../../../accounts/presentation/providers/accounts_provider.dart';
import '../../../categories/domain/category.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../../../groups/presentation/providers/active_group_provider.dart';
import '../../../shared/presentation/widgets/async_states.dart';
import '../../../transactions/presentation/providers/transactions_provider.dart';
import '../../data/recurring_repository.dart';
import '../../domain/recurring_transaction.dart';

final recurringRepositoryProvider = Provider<RecurringRepository>((ref) {
  return RecurringRepository();
});

final recurringVersionProvider = StateProvider<int>((ref) => 0);

final recurringListProvider = FutureProvider<List<RecurringTransaction>>((
  ref,
) async {
  ref.watch(recurringVersionProvider);
  return ref.read(recurringRepositoryProvider).getAll();
});

class RecurringScreen extends ConsumerStatefulWidget {
  const RecurringScreen({super.key});

  @override
  ConsumerState<RecurringScreen> createState() => _RecurringScreenState();
}

class _RecurringScreenState extends ConsumerState<RecurringScreen> {
  bool _running = false;

  /// Sinh các giao dịch đã tới hạn ngay bây giờ, không đợi lịch server.
  Future<void> _runDue() async {
    final group = ref.read(activeGroupProvider);
    if (group == null) return;

    setState(() => _running = true);
    final result = await ref.read(recurringRepositoryProvider).runDue(group.id);
    if (!mounted) return;
    setState(() => _running = false);

    if (result.isErr) {
      showResultSnackBar(
        context,
        message:
            result.localizedErrorOrNull(context.l10n) ??
            context.l10n.recurringRunFailed,
        isError: true,
      );
      return;
    }

    final count = result.valueOrNull ?? 0;
    ref.read(recurringVersionProvider.notifier).state++;
    ref.read(transactionVersionProvider.notifier).state++;
    ref.read(accountVersionProvider.notifier).state++;

    showResultSnackBar(
      context,
      message: count == 0
          ? context.l10n.recurringNoneDue
          : context.l10n.recurringCreatedDue(count),
    );
  }

  @override
  Widget build(BuildContext context) {
    final listAsync = ref.watch(recurringListProvider);
    final categoriesAsync = ref.watch(categoriesListProvider);
    final accountsAsync = ref.watch(accountsListProvider);

    final categoryMap = {
      for (final c in categoriesAsync.valueOrNull ?? const <Category>[])
        c.id: c,
    };
    final accountMap = {
      for (final a in accountsAsync.valueOrNull ?? const <Account>[]) a.id: a,
    };

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: context.colors.background,
        title: Text(context.l10n.recurringTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: context.l10n.recurringBack,
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: _running
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.play_circle_outline),
            tooltip: context.l10n.recurringRunDueTooltip,
            onPressed: _running ? null : _runDue,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showDialog<void>(
          context: context,
          builder: (_) => const _RecurringEditorDialog(),
        ),
        backgroundColor: context.colors.primary,
        foregroundColor: context.colors.onPrimary,
        icon: const Icon(Icons.add),
        label: Text(context.l10n.actionAdd),
      ),
      body: listAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => AsyncErrorView(
          error: e,
          onRetry: () => ref.read(recurringVersionProvider.notifier).state++,
        ),
        data: (items) {
          if (items.isEmpty) {
            return AsyncEmptyView(
              icon: Icons.repeat,
              title: context.l10n.recurringEmptyTitle,
              message: context.l10n.recurringEmptyMessage,
              actionLabel: context.l10n.recurringAddTitle,
              onAction: () => showDialog<void>(
                context: context,
                builder: (_) => const _RecurringEditorDialog(),
              ),
            );
          }

          final overdue = items.where((r) => r.isOverdue).length;

          return RefreshIndicator(
            onRefresh: () async {
              ref.read(recurringVersionProvider.notifier).state++;
              await ref.read(recurringListProvider.future);
            },
            child: ListView(
              // Cho phép kéo-làm-mới cả khi danh sách ngắn hơn màn hình.
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              children: [
                if (overdue > 0)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: context.colors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: context.colors.warning.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          color: context.colors.warning,
                          size: 18,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            context.l10n.recurringOverdueCount(overdue),
                            style: TextStyle(
                              color: context.colors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: _running ? null : _runDue,
                          child: Text(context.l10n.recurringRunNow),
                        ),
                      ],
                    ),
                  ),
                ...items.map(
                  (r) => _RecurringCard(
                    item: r,
                    category: r.categoryId == null
                        ? null
                        : categoryMap[r.categoryId],
                    account: accountMap[r.accountId],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _RecurringCard extends ConsumerWidget {
  const _RecurringCard({
    required this.item,
    required this.category,
    required this.account,
  });

  final RecurringTransaction item;
  final Category? category;
  final Account? account;

  /// Hỏi xác nhận rồi xoá giao dịch định kỳ. Dùng chung cho nhấn giữ và menu.
  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.colors.surface,
        title: Text(context.l10n.recurringDeleteTitle),
        content: Text(context.l10n.recurringDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(context.l10n.actionCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: context.colors.expense,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(context.l10n.actionDelete),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final result = await ref.read(recurringRepositoryProvider).delete(item.id);
    ref.read(recurringVersionProvider.notifier).state++;
    if (context.mounted) {
      showResultSnackBar(
        context,
        message:
            result.localizedErrorOrNull(context.l10n) ??
            context.l10n.recurringDeleted,
        isError: result.isErr,
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = parseHexColor(
      category?.colorHex,
      fallback: item.isExpense ? context.colors.expense : context.colors.income,
    );

    final days = item.daysUntilNext;
    final due = item.isOverdue
        ? context.l10n.recurringDue
        : (days == 0
              ? context.l10n.recurringToday
              : (days == 1
                    ? context.l10n.recurringTomorrow
                    : context.l10n.recurringInDays(days)));

    return Card(
      color: context.colors.surface,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.22),
          child: Icon(iconFromName(category?.iconName), color: color, size: 20),
        ),
        title: Text(
          category == null
              ? (item.isExpense
                    ? context.l10n.recurringExpense
                    : context.l10n.recurringIncome)
              : categoryLabel(context.l10n, category?.name),
          style: TextStyle(
            color: item.isActive
                ? context.colors.textPrimary
                : context.colors.textTertiary,
          ),
        ),
        subtitle: Text(
          '${item.frequency.localizedLabel(context)} · ${account?.name ?? context.l10n.recurringDeletedAccount}\n'
          '${FormatHelpers.date(item.nextDate)} · $due',
          style: TextStyle(
            color: item.isOverdue
                ? context.colors.warning
                : context.colors.textSecondary,
            fontSize: 12,
          ),
        ),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  FormatHelpers.currency(item.amount),
                  style: TextStyle(
                    color: item.isExpense
                        ? context.colors.expense
                        : context.colors.income,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Switch(
                  value: item.isActive,
                  activeThumbColor: context.colors.primary,
                  onChanged: (v) async {
                    final result = await ref
                        .read(recurringRepositoryProvider)
                        .setActive(item.id, v);
                    ref.read(recurringVersionProvider.notifier).state++;
                    if (context.mounted && result.isErr) {
                      showResultSnackBar(
                        context,
                        message: result.localizedErrorOrNull(context.l10n)!,
                        isError: true,
                      );
                    }
                  },
                ),
              ],
            ),
            // Lối vào nhìn thấy được cho thao tác xoá, thay vì chỉ nhấn giữ.
            PopupMenuButton<String>(
              tooltip: context.l10n.accountsMoreActions,
              icon: Icon(
                Icons.more_vert,
                size: 20,
                color: context.colors.textTertiary,
              ),
              color: context.colors.surface,
              onSelected: (_) => _confirmDelete(context, ref),
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'delete',
                  child: Text(
                    context.l10n.actionDelete,
                    style: TextStyle(color: context.colors.expense),
                  ),
                ),
              ],
            ),
          ],
        ),
        onLongPress: () {
          // Rung nhẹ báo hiệu thao tác nhấn giữ (xoá) đã được nhận.
          HapticFeedback.lightImpact();
          _confirmDelete(context, ref);
        },
      ),
    );
  }
}

// -----------------------------------------------------------------------------

class _RecurringEditorDialog extends ConsumerStatefulWidget {
  const _RecurringEditorDialog();

  @override
  ConsumerState<_RecurringEditorDialog> createState() =>
      _RecurringEditorDialogState();
}

class _RecurringEditorDialogState
    extends ConsumerState<_RecurringEditorDialog> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  String _type = 'expense';
  String? _accountId;
  String? _categoryId;
  RecurringFrequency _frequency = RecurringFrequency.monthly;
  DateTime _nextDate = DateTime.now().add(const Duration(days: 1));
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = FormatHelpers.parseAmount(_amountController.text);
    if (amount == null || amount <= 0) {
      setState(() => _error = context.l10n.recurringAmountMustBePositive);
      return;
    }
    if (_accountId == null) {
      setState(() => _error = context.l10n.recurringSelectAccount);
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final result = await ref
        .read(recurringRepositoryProvider)
        .add(
          accountId: _accountId!,
          categoryId: _categoryId,
          type: _type,
          amount: amount,
          frequency: _frequency,
          nextDate: _nextDate,
          note: _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim(),
        );

    if (!mounted) return;
    setState(() => _saving = false);

    if (result.isErr) {
      setState(() => _error = result.localizedErrorOrNull(context.l10n));
      return;
    }
    ref.read(recurringVersionProvider.notifier).state++;
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(accountsListProvider);
    final categoriesAsync = ref.watch(categoriesByTypeProvider(_type));

    return AlertDialog(
      backgroundColor: context.colors.surface,
      // Cuộn được khi bàn phím che bớt chiều cao, tránh khuất ô đang gõ.
      scrollable: true,
      title: Text(context.l10n.recurringAddTitle),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SegmentedButton<String>(
                segments: [
                  ButtonSegment(
                    value: 'expense',
                    label: Text(context.l10n.recurringExpenseSegment),
                  ),
                  ButtonSegment(
                    value: 'income',
                    label: Text(context.l10n.recurringIncomeSegment),
                  ),
                ],
                selected: {_type},
                onSelectionChanged: (s) => setState(() {
                  _type = s.first;
                  _categoryId = null;
                }),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [AmountInputFormatter()],
                decoration: InputDecoration(
                  labelText: context.l10n.recurringAmountLabel,
                ),
              ),
              const SizedBox(height: 16),
              accountsAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => AsyncErrorView(
                  error: e,
                  compact: true,
                  onRetry: () => ref.invalidate(accountsListProvider),
                ),
                data: (accounts) => DropdownButtonFormField<String>(
                  initialValue: _accountId,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: context.l10n.recurringAccountLabel,
                  ),
                  dropdownColor: context.colors.surface,
                  items: [
                    for (final a in accounts.where((a) => a.isActive))
                      DropdownMenuItem(value: a.id, child: Text(a.name)),
                  ],
                  onChanged: (v) => setState(() => _accountId = v),
                ),
              ),
              const SizedBox(height: 16),
              categoriesAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => AsyncErrorView(
                  error: e,
                  compact: true,
                  onRetry: () =>
                      ref.invalidate(categoriesByTypeProvider(_type)),
                ),
                data: (categories) => DropdownButtonFormField<String>(
                  initialValue: _categoryId,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: context.l10n.recurringCategoryLabel,
                  ),
                  dropdownColor: context.colors.surface,
                  items: [
                    for (final c in categories)
                      DropdownMenuItem(value: c.id, child: Text(c.name)),
                  ],
                  onChanged: (v) => setState(() => _categoryId = v),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<RecurringFrequency>(
                initialValue: _frequency,
                decoration: InputDecoration(
                  labelText: context.l10n.recurringFrequencyLabel,
                ),
                dropdownColor: context.colors.surface,
                items: [
                  for (final f in RecurringFrequency.values)
                    DropdownMenuItem(
                      value: f,
                      child: Text(f.localizedLabel(context)),
                    ),
                ],
                onChanged: (v) => setState(() => _frequency = v ?? _frequency),
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  context.l10n.recurringNextDate,
                  style: const TextStyle(fontSize: 14),
                ),
                subtitle: Text(
                  FormatHelpers.date(_nextDate),
                  style: TextStyle(
                    color: context.colors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                trailing: const Icon(Icons.calendar_today, size: 18),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _nextDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 3650)),
                  );
                  if (picked != null) setState(() => _nextDate = picked);
                },
              ),
              TextField(
                controller: _noteController,
                decoration: InputDecoration(
                  labelText: context.l10n.recurringNote,
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
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(context.l10n.actionAdd),
        ),
      ],
    );
  }
}
