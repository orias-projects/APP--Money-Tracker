import '../../../categories/domain/category_label.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spend_sync/src/core/l10n/l10n.dart';

import '../../../../common_widgets/transaction_tile.dart';
import '../../../../core/constants/app_palette.dart';
import '../../../../core/utils/category_icons.dart';
import '../../../../core/utils/format_helpers.dart';
import '../../../categories/domain/category.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../../../groups/presentation/providers/active_group_provider.dart';
import '../../../shared/presentation/widgets/async_states.dart';
import '../../../transactions/data/transaction_repository.dart';
import '../../../transactions/presentation/providers/transactions_provider.dart';

/// Tìm giao dịch theo ghi chú, nơi chi, danh mục, loại và khoảng số tiền.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  final _minController = TextEditingController();
  final _maxController = TextEditingController();

  Timer? _debounce;
  String _query = '';
  final Set<String> _types = {};
  final Set<String> _categoryIds = {};
  double? _minAmount;
  double? _maxAmount;
  DateTimeRange? _dateRange;
  bool _filtersOpen = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  /// Gõ xong 350ms mới gọi mạng, tránh mỗi phím một truy vấn.
  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => _query = value.trim());
    });
  }

  void _applyAmountFilters() {
    setState(() {
      _minAmount = FormatHelpers.parseAmount(_minController.text);
      _maxAmount = FormatHelpers.parseAmount(_maxController.text);
    });
  }

  bool get _hasAnyFilter =>
      _query.isNotEmpty ||
      _types.isNotEmpty ||
      _categoryIds.isNotEmpty ||
      _minAmount != null ||
      _maxAmount != null ||
      _dateRange != null;

  void _clearAll() {
    _searchController.clear();
    _minController.clear();
    _maxController.clear();
    setState(() {
      _query = '';
      _types.clear();
      _categoryIds.clear();
      _minAmount = null;
      _maxAmount = null;
      _dateRange = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final group = ref.watch(activeGroupProvider);
    final categoriesAsync = ref.watch(categoriesListProvider);

    final query = TransactionQuery(
      groupId: group?.id ?? '',
      search: _query.isEmpty ? null : _query,
      types: _types.isEmpty ? null : _types.toList(),
      categoryIds: _categoryIds.isEmpty ? null : _categoryIds.toList(),
      minAmount: _minAmount,
      maxAmount: _maxAmount,
      from: _dateRange?.start,
      to: _dateRange?.end,
      limit: 100,
    );

    final resultsAsync = _hasAnyFilter
        ? ref.watch(transactionsListProvider(query))
        : const AsyncValue.data(<dynamic>[]);

    final categoryMap = {
      for (final c in categoriesAsync.valueOrNull ?? const <Category>[])
        c.id: c,
    };

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: context.colors.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: context.l10n.searchBack,
          onPressed: () => context.pop(),
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: context.l10n.searchHint,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
            contentPadding: EdgeInsets.zero,
            // Chỉ rebuild nút xoá theo controller, không setState cả màn hình
            // mỗi phím gõ.
            suffixIcon: ValueListenableBuilder<TextEditingValue>(
              valueListenable: _searchController,
              builder: (context, value, _) {
                if (value.text.isEmpty) return const SizedBox.shrink();
                return IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  tooltip: context.l10n.searchClear,
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _query = '');
                  },
                );
              },
            ),
          ),
          style: TextStyle(color: context.colors.textPrimary, fontSize: 16),
          onChanged: _onQueryChanged,
        ),
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible:
                  _types.isNotEmpty ||
                  _categoryIds.isNotEmpty ||
                  _minAmount != null ||
                  _maxAmount != null ||
                  _dateRange != null,
              backgroundColor: context.colors.primary,
              child: const Icon(Icons.tune),
            ),
            tooltip: context.l10n.searchFilters,
            onPressed: () => setState(() => _filtersOpen = !_filtersOpen),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) => Column(
          children: [
            if (_filtersOpen)
              // Giới hạn chiều cao panel để không tràn trên màn hình thấp
              // khi bàn phím mở; phần thừa cuộn bên trong panel.
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: constraints.maxHeight * 0.6,
                ),
                child: _FilterPanel(
                  types: _types,
                  categoryIds: _categoryIds,
                  categories: categoriesAsync.valueOrNull ?? const [],
                  dateRange: _dateRange,
                  minController: _minController,
                  maxController: _maxController,
                  onTypeToggle: (t) => setState(() {
                    if (!_types.remove(t)) _types.add(t);
                  }),
                  onCategoryToggle: (id) => setState(() {
                    if (!_categoryIds.remove(id)) _categoryIds.add(id);
                  }),
                  onPickRange: () async {
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                      initialDateRange: _dateRange,
                    );
                    if (picked != null) setState(() => _dateRange = picked);
                  },
                  onAmountsChanged: _applyAmountFilters,
                  onClear: _clearAll,
                ),
              ),
            Expanded(
              child: !_hasAnyFilter
                  ? AsyncEmptyView(
                      icon: Icons.search,
                      title: context.l10n.searchEmptyTitle,
                      message: context.l10n.searchEmptyMessage,
                    )
                  : resultsAsync.when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (e, _) => AsyncErrorView(
                        error: e,
                        onRetry: () => ref
                            .read(transactionVersionProvider.notifier)
                            .state++,
                      ),
                      data: (dynamic raw) {
                        final list = (raw as List).cast<dynamic>();
                        if (list.isEmpty) {
                          return AsyncEmptyView(
                            icon: Icons.search_off,
                            title: context.l10n.searchNoResultsTitle,
                            message: context.l10n.searchNoResultsMessage,
                          );
                        }
                        final total = list.fold<double>(
                          0,
                          (s, t) => s + (t.isExpense ? t.amount : -t.amount),
                        );
                        return Column(
                          children: [
                            _ResultSummary(
                              count: list.length,
                              netExpense: total,
                            ),
                            Expanded(
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                // Tile kết quả luôn có title + subtitle 1 dòng
                                // (không accountName/shareLabel) nên cao đồng
                                // nhất; prototype giúp bỏ qua đo layout từng ô.
                                prototypeItem: const TransactionTile(
                                  title: 'A',
                                  subtitle: 'A',
                                  amount: '0',
                                ),
                                itemCount: list.length,
                                itemBuilder: (_, i) {
                                  final t = list[i];
                                  final cat = t.categoryId != null
                                      ? categoryMap[t.categoryId]
                                      : null;
                                  return TransactionTile(
                                    title: t.isTransfer
                                        ? context.l10n.searchTransfer
                                        : (cat == null
                                              ? context.l10n.searchUncategorized
                                              : categoryLabel(
                                                  context.l10n,
                                                  cat.name,
                                                )),
                                    type: t.type,
                                    subtitle: [
                                      FormatHelpers.date(t.transactionDate),
                                      if (t.note != null &&
                                          (t.note as String).trim().isNotEmpty)
                                        (t.note as String).trim(),
                                    ].join(' · '),
                                    amount: FormatHelpers.currency(t.amount),
                                    colorHex: cat?.colorHex,
                                    iconName: cat?.iconName,
                                    hasReceipt: t.imageUrl != null,
                                    onTap: () => context.push(
                                      '/edit-transaction',
                                      extra: t,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultSummary extends StatelessWidget {
  const _ResultSummary({required this.count, required this.netExpense});

  final int count;
  final double netExpense;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: context.colors.surface,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            context.l10n.searchResultCount(count),
            style: TextStyle(color: context.colors.textSecondary, fontSize: 13),
          ),
          Text(
            context.l10n.searchNetSpending(FormatHelpers.currency(netExpense)),
            style: TextStyle(
              color: context.colors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterPanel extends StatelessWidget {
  const _FilterPanel({
    required this.types,
    required this.categoryIds,
    required this.categories,
    required this.dateRange,
    required this.minController,
    required this.maxController,
    required this.onTypeToggle,
    required this.onCategoryToggle,
    required this.onPickRange,
    required this.onAmountsChanged,
    required this.onClear,
  });

  final Set<String> types;
  final Set<String> categoryIds;
  final List<Category> categories;
  final DateTimeRange? dateRange;
  final TextEditingController minController;
  final TextEditingController maxController;
  final ValueChanged<String> onTypeToggle;
  final ValueChanged<String> onCategoryToggle;
  final VoidCallback onPickRange;
  final VoidCallback onAmountsChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.colors.surface,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      // Cuộn được khi panel bị giới hạn chiều cao (màn hình thấp + bàn phím).
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.l10n.searchFilters,
                    style: TextStyle(
                      color: context.colors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onClear,
                  child: Text(context.l10n.searchClearAll),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              children: [
                for (final entry in {
                  'expense': context.l10n.searchTypeExpense,
                  'income': context.l10n.searchTypeIncome,
                  'transfer': context.l10n.searchTypeTransfer,
                }.entries)
                  FilterChip(
                    label: Text(entry.value),
                    selected: types.contains(entry.key),
                    onSelected: (_) => onTypeToggle(entry.key),
                    backgroundColor: context.colors.surfaceVariant,
                    selectedColor: context.colors.primary.withValues(
                      alpha: 0.25,
                    ),
                    checkmarkColor: context.colors.primary,
                    labelStyle: const TextStyle(fontSize: 13),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: minController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [AmountInputFormatter()],
                    decoration: InputDecoration(
                      labelText: context.l10n.searchAmountFrom,
                      isDense: true,
                    ),
                    onChanged: (_) => onAmountsChanged(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: maxController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [AmountInputFormatter()],
                    decoration: InputDecoration(
                      labelText: context.l10n.searchAmountTo,
                      isDense: true,
                    ),
                    onChanged: (_) => onAmountsChanged(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onPickRange,
              icon: const Icon(Icons.date_range, size: 18),
              label: Text(
                dateRange == null
                    ? context.l10n.searchPickDateRange
                    : FormatHelpers.dateRange(dateRange!.start, dateRange!.end),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: context.colors.textSecondary,
                side: BorderSide(color: context.colors.divider),
              ),
            ),
            if (categories.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                // Nới chiều cao theo cỡ chữ hệ thống để chip không bị cắt.
                height:
                    40.0 *
                    MediaQuery.textScalerOf(context).scale(1.0).clamp(1.0, 1.6),
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final c = categories[i];
                    final selected = categoryIds.contains(c.id);
                    final color = parseHexColor(c.colorHex);
                    return FilterChip(
                      avatar: Icon(
                        iconFromName(c.iconName),
                        size: 16,
                        color: color,
                      ),
                      label: Text(categoryLabel(context.l10n, c.name)),
                      selected: selected,
                      onSelected: (_) => onCategoryToggle(c.id),
                      backgroundColor: context.colors.surfaceVariant,
                      selectedColor: color.withValues(alpha: 0.25),
                      checkmarkColor: color,
                      labelStyle: const TextStyle(fontSize: 12),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
