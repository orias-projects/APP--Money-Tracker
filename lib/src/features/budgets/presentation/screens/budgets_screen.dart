import '../../../categories/domain/category_label.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spend_sync/src/core/l10n/enum_labels.dart';
import 'package:spend_sync/src/core/l10n/l10n.dart';

import '../../../../core/constants/app_palette.dart';
import '../../../../core/errors/error_l10n.dart';
import '../../../../core/settings/app_settings.dart';
import '../../../../core/utils/category_icons.dart';
import '../../../../core/utils/format_helpers.dart';
import '../../../categories/domain/category.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../../../groups/presentation/providers/active_group_provider.dart';
import '../../../shared/presentation/widgets/async_states.dart';
import '../../../transactions/presentation/providers/transactions_provider.dart';
import '../../data/budget_repository.dart';
import '../../domain/budget.dart';

final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  return BudgetRepository();
});

final budgetVersionProvider = StateProvider<int>((ref) => 0);

final budgetsProvider = FutureProvider<List<Budget>>((ref) async {
  ref.watch(budgetVersionProvider);
  ref.watch(transactionVersionProvider);
  final group = ref.watch(activeGroupProvider);
  if (group == null) return const [];
  return ref.read(budgetRepositoryProvider).getBudgets(group.id);
});

class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetsAsync = ref.watch(budgetsProvider);

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: context.colors.background,
        title: Text(context.l10n.budgetsTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: context.l10n.budgetsBack,
          onPressed: () => context.pop(),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEditor(context, ref),
        backgroundColor: context.colors.primary,
        foregroundColor: context.colors.onPrimary,
        icon: const Icon(Icons.add),
        label: Text(context.l10n.budgetsSetLimit),
      ),
      body: budgetsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => AsyncErrorView(
          error: e,
          onRetry: () => ref.read(budgetVersionProvider.notifier).state++,
        ),
        data: (budgets) {
          if (budgets.isEmpty) {
            return AsyncEmptyView(
              icon: Icons.savings_outlined,
              title: context.l10n.budgetsEmptyTitle,
              message: context.l10n.budgetsEmptyMessage,
              actionLabel: context.l10n.budgetsSetLimit,
              onAction: () => _showEditor(context, ref),
            );
          }

          final active = budgets.where((b) => b.isActive).toList();
          final past = budgets.where((b) => !b.isActive).toList();

          return RefreshIndicator(
            onRefresh: () async {
              ref.read(budgetVersionProvider.notifier).state++;
              await ref.read(budgetsProvider.future);
            },
            child: ListView(
              // Cho phép kéo-làm-mới cả khi danh sách ngắn hơn màn hình.
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              children: [
                if (active.isNotEmpty) ...[
                  _TotalCard(budgets: active),
                  const SizedBox(height: 16),
                  ...active.map(
                    (b) => _BudgetCard(
                      budget: b,
                      onEdit: () => _showEditor(context, ref, existing: b),
                      onDelete: () => _delete(context, ref, b),
                    ),
                  ),
                ],
                if (past.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 24, 4, 8),
                    child: Text(
                      context.l10n.budgetsPastPeriods,
                      style: TextStyle(
                        color: context.colors.textTertiary,
                        fontSize: 11,
                        letterSpacing: 1.1,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  ...past.map(
                    (b) => _BudgetCard(
                      budget: b,
                      onEdit: () => _showEditor(context, ref, existing: b),
                      onDelete: () => _delete(context, ref, b),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _showEditor(
    BuildContext context,
    WidgetRef ref, {
    Budget? existing,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _BudgetEditorDialog(existing: existing),
    );
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    Budget budget,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.colors.surface,
        title: Text(context.l10n.budgetsDeleteTitle),
        content: Text(
          context.l10n.budgetsDeleteConfirm(
            categoryLabel(context.l10n, budget.categoryName),
          ),
        ),
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

    final result = await ref
        .read(budgetRepositoryProvider)
        .deleteBudget(budget.id);
    ref.read(budgetVersionProvider.notifier).state++;
    if (context.mounted) {
      showResultSnackBar(
        context,
        message:
            result.localizedErrorOrNull(context.l10n) ??
            context.l10n.budgetsDeleted,
        isError: result.isErr,
      );
    }
  }
}

/// Tổng quan mọi hạn mức đang chạy.
class _TotalCard extends StatelessWidget {
  const _TotalCard({required this.budgets});

  final List<Budget> budgets;

  @override
  Widget build(BuildContext context) {
    final limit = budgets.fold<double>(0, (s, b) => s + b.amount);
    final spent = budgets.fold<double>(0, (s, b) => s + b.spent);
    final progress = limit <= 0 ? 0.0 : (spent / limit).clamp(0.0, 1.0);
    final over = spent > limit;

    return Card(
      color: context.colors.surface,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.budgetsTotalActive,
              style: TextStyle(
                color: context.colors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  FormatHelpers.currency(spent),
                  style: TextStyle(
                    color: over
                        ? context.colors.expense
                        : context.colors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '/ ${FormatHelpers.currency(limit)}',
                  style: TextStyle(
                    color: context.colors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: context.colors.surfaceVariant,
                valueColor: AlwaysStoppedAnimation(
                  over ? context.colors.expense : context.colors.primary,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              over
                  ? context.l10n.budgetsOverBy(
                      FormatHelpers.currency(spent - limit),
                    )
                  : context.l10n.budgetsRemaining(
                      FormatHelpers.currency(limit - spent),
                    ),
              style: TextStyle(
                color: over ? context.colors.expense : context.colors.income,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({
    required this.budget,
    required this.onEdit,
    required this.onDelete,
  });

  final Budget budget;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final color = parseHexColor(budget.colorHex);
    final progress = budget.progress.clamp(0.0, 1.0);

    final barColor = budget.isOverBudget
        ? context.colors.expense
        : (budget.isNearLimit ? context.colors.warning : color);

    return Card(
      color: context.colors.surface,
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onEdit,
        onLongPress: () {
          // Rung nhẹ báo hiệu thao tác nhấn giữ (xoá) đã được nhận.
          HapticFeedback.lightImpact();
          onDelete();
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: color.withValues(alpha: 0.22),
                    child: Icon(
                      iconFromName(budget.iconName),
                      color: color,
                      size: 17,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      categoryLabel(context.l10n, budget.categoryName),
                      style: TextStyle(
                        color: context.colors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (budget.isOverBudget)
                    Icon(
                      Icons.warning_amber_rounded,
                      color: context.colors.expense,
                      size: 18,
                    )
                  else if (budget.isNearLimit)
                    Icon(
                      Icons.info_outline,
                      color: context.colors.warning,
                      size: 18,
                    ),
                  // Lối vào nhìn thấy được cho sửa/xoá, thay vì chỉ nhấn giữ.
                  PopupMenuButton<String>(
                    tooltip: context.l10n.accountsMoreActions,
                    icon: Icon(
                      Icons.more_vert,
                      size: 18,
                      color: context.colors.textTertiary,
                    ),
                    color: context.colors.surface,
                    onSelected: (v) => v == 'delete' ? onDelete() : onEdit(),
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Text(context.l10n.actionEdit),
                      ),
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
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: context.colors.surfaceVariant,
                  valueColor: AlwaysStoppedAnimation(barColor),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${FormatHelpers.currency(budget.spent)} / '
                    '${FormatHelpers.currency(budget.amount)}',
                    style: TextStyle(
                      color: context.colors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    budget.isOverBudget
                        ? context.l10n.budgetsOverBy(
                            FormatHelpers.currency(-budget.remaining),
                          )
                        : (budget.isActive
                              ? context.l10n.budgetsDaysLeft(budget.daysLeft)
                              : budget.period.localizedLabel(context)),
                    style: TextStyle(
                      color: budget.isOverBudget
                          ? context.colors.expense
                          : context.colors.textTertiary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------

class _BudgetEditorDialog extends ConsumerStatefulWidget {
  const _BudgetEditorDialog({this.existing});

  final Budget? existing;

  @override
  ConsumerState<_BudgetEditorDialog> createState() =>
      _BudgetEditorDialogState();
}

class _BudgetEditorDialogState extends ConsumerState<_BudgetEditorDialog> {
  late final TextEditingController _amountController;
  String? _categoryId;
  BudgetPeriod _period = BudgetPeriod.monthly;
  bool _saving = false;
  String? _error;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.existing == null
          ? ''
          : FormatHelpers.amount(widget.existing!.amount),
    );
    _categoryId = widget.existing?.categoryId;
    _period = widget.existing?.period ?? BudgetPeriod.monthly;
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = FormatHelpers.parseAmount(_amountController.text);
    if (amount == null || amount <= 0) {
      setState(() => _error = context.l10n.budgetsInvalidAmount);
      return;
    }
    if (_categoryId == null) {
      setState(() => _error = context.l10n.budgetsChooseCategory);
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final settings = ref.read(settingsProvider);
    final range = periodRange(
      _period,
      DateTime.now(),
      firstDayOfMonth: settings.firstDayOfMonth,
    );

    final repo = ref.read(budgetRepositoryProvider);
    final result = _isEdit
        ? await repo.updateBudget(
            widget.existing!.id,
            amount: amount,
            startDate: range.start,
            endDate: range.end,
          )
        : await repo.addBudget(
            categoryId: _categoryId!,
            amount: amount,
            period: _period,
            startDate: range.start,
            endDate: range.end,
          );

    if (!mounted) return;
    setState(() => _saving = false);

    if (result.isErr) {
      setState(() => _error = result.localizedErrorOrNull(context.l10n));
      return;
    }
    ref.read(budgetVersionProvider.notifier).state++;
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesByTypeProvider('expense'));

    return AlertDialog(
      backgroundColor: context.colors.surface,
      // Cuộn được khi bàn phím che bớt chiều cao, tránh khuất ô đang gõ.
      scrollable: true,
      title: Text(
        _isEdit ? context.l10n.budgetsEditLimit : context.l10n.budgetsSetLimit,
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              categoriesAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => AsyncErrorView(
                  error: e,
                  compact: true,
                  onRetry: () =>
                      ref.invalidate(categoriesByTypeProvider('expense')),
                ),
                data: (categories) => DropdownButtonFormField<String>(
                  initialValue: _categoryId,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: context.l10n.budgetsCategoryLabel,
                  ),
                  dropdownColor: context.colors.surface,
                  items: [
                    for (final c in categories)
                      DropdownMenuItem(
                        value: c.id,
                        child: _CategoryRow(category: c),
                      ),
                  ],
                  onChanged: _isEdit
                      ? null
                      : (v) => setState(() => _categoryId = v),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [AmountInputFormatter()],
                decoration: InputDecoration(
                  labelText: context.l10n.budgetsLimitLabel,
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<BudgetPeriod>(
                initialValue: _period,
                decoration: InputDecoration(
                  labelText: context.l10n.budgetsPeriodLabel,
                ),
                dropdownColor: context.colors.surface,
                items: [
                  for (final p in BudgetPeriod.values)
                    if (p != BudgetPeriod.custom)
                      DropdownMenuItem(
                        value: p,
                        child: Text(p.localizedLabel(context)),
                      ),
                ],
                onChanged: (v) => setState(() => _period = v ?? _period),
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
              : Text(context.l10n.actionSave),
        ),
      ],
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.category});
  final Category category;

  @override
  Widget build(BuildContext context) {
    final color = parseHexColor(category.colorHex);
    return Row(
      children: [
        Icon(iconFromName(category.iconName), size: 18, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            categoryLabel(context.l10n, category.name),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: context.colors.textPrimary, fontSize: 15),
          ),
        ),
      ],
    );
  }
}
