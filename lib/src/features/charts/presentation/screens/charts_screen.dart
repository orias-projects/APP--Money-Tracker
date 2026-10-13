import '../../../categories/domain/category_label.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spend_sync/src/core/l10n/l10n.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_palette.dart';
import '../../../../core/utils/category_icons.dart';
import '../../../../core/utils/format_helpers.dart';
import '../../../../shell/shell_app_bar_provider.dart';
import '../../../groups/presentation/providers/active_group_provider.dart';
import '../../../shared/presentation/providers/filter_provider.dart';
import '../../../shared/presentation/widgets/async_states.dart';
import '../../data/analytics_repository.dart';
import '../../domain/pie_breakdown.dart';
import '../providers/analytics_provider.dart';

class ChartsScreen extends ConsumerStatefulWidget {
  const ChartsScreen({super.key});

  @override
  ConsumerState<ChartsScreen> createState() => _ChartsScreenState();
}

class _ChartsScreenState extends ConsumerState<ChartsScreen> {
  ChartsParams? _params;

  /// Chỉ làm mới đúng bộ tham số đang xem — invalidate cả family sẽ vứt cache
  /// của mọi khoảng thời gian từng mở.
  void _invalidateCurrent() {
    final params = _params;
    if (params != null) ref.invalidate(analyticsProvider(params));
  }

  @override
  Widget build(BuildContext context) {
    final activeGroup = ref.watch(activeGroupProvider);
    final filterState = ref.watch(filterProvider);

    final params = ChartsParams.fromFilter(filterState, activeGroup?.id ?? '');
    _params = params;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // const → canonical hoá: setTitle so bằng và bỏ qua, shell không rebuild.
      ref
          .read(shellAppBarTitleProvider.notifier)
          .setTitle(1, const _ChartsShellTitle());
    });

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: context.colors.background,
        body: Column(
          children: [
            TabBar(
              indicatorColor: context.colors.primary,
              labelColor: context.colors.primary,
              unselectedLabelColor: context.colors.textSecondary,
              tabs: [
                Tab(text: context.l10n.chartsTabOverview),
                Tab(text: context.l10n.chartsTabIncome),
                Tab(text: context.l10n.chartsTabExpense),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _OverviewTabContent(
                    params: params,
                    filterState: filterState,
                    onRefresh: () async => _invalidateCurrent(),
                  ),
                  _ChartTabContent(
                    isIncome: true,
                    params: params,
                    filterState: filterState,
                    onRefresh: () async => _invalidateCurrent(),
                  ),
                  _ChartTabContent(
                    isIncome: false,
                    params: params,
                    filterState: filterState,
                    onRefresh: () async => _invalidateCurrent(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartTabContent extends ConsumerStatefulWidget {
  const _ChartTabContent({
    required this.isIncome,
    required this.params,
    required this.filterState,
    required this.onRefresh,
  });

  final bool isIncome;
  final ChartsParams params;
  final FilterState filterState;
  final Future<void> Function() onRefresh;

  @override
  ConsumerState<_ChartTabContent> createState() => _ChartTabContentState();
}

class _ChartTabContentState extends ConsumerState<_ChartTabContent> {
  @override
  Widget build(BuildContext context) {
    return _buildContent(context, ref.watch(analyticsProvider(widget.params)));
  }

  Widget _buildContent(
    BuildContext context,
    AsyncValue<AnalyticsSnapshot> analyticsAsync,
  ) {
    String chartTitle = widget.isIncome
        ? context.l10n.chartsIncome
        : context.l10n.chartsExpense;
    if (widget.filterState.startDate != null &&
        widget.filterState.endDate != null) {
      chartTitle += context.l10n.chartsDateRangeSuffix(
        FormatHelpers.dateShort(widget.filterState.startDate!),
        FormatHelpers.dateShort(widget.filterState.endDate!),
      );
    }

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Chart Section
            Card(
              color: context.colors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: analyticsAsync.when(
                  data: (data) => _ChartAndLegend(
                    total: widget.isIncome
                        ? data.incomeTotal
                        : data.expenseTotal,
                    items: widget.isIncome
                        ? data.incomeByCategory
                        : data.expenseByCategory,
                    title: chartTitle,
                  ),
                  loading: () => const SizedBox(
                    height: 300,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => SizedBox(
                    height: 300,
                    child: AsyncErrorView(
                      error: e,
                      onRetry: () =>
                          ref.invalidate(analyticsProvider(widget.params)),
                    ),
                  ),
                ),
              ),
            ),
            // Top 5 List
            analyticsAsync.when(
              data: (data) => _Top5List(
                title: widget.isIncome
                    ? context.l10n.chartsTopIncome
                    : context.l10n.chartsTopExpense,
                transactions: widget.isIncome
                    ? data.topIncome
                    : data.topExpense,
                isIncome: widget.isIncome,
              ),
              loading: () => Card(
                color: context.colors.surface,
                child: const SizedBox(
                  height: 150,
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              // Lỗi đã hiện ở card biểu đồ phía trên (cùng một provider) —
              // không lặp lại thông điệp lần hai.
              error: (_, _) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tiêu đề tab Biểu đồ trên thanh shell. Là widget const để
/// `setTitle` nhận diện "không đổi" và bỏ qua (xem shell_app_bar_provider);
/// đổi ngôn ngữ/theme vẫn tự cập nhật vì l10n/màu được đọc trong build.
class _ChartsShellTitle extends StatelessWidget {
  const _ChartsShellTitle();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Text(
        context.l10n.chartsTitle,
        style: TextStyle(
          color: context.colors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _OverviewTabContent extends ConsumerStatefulWidget {
  const _OverviewTabContent({
    required this.params,
    required this.filterState,
    required this.onRefresh,
  });

  final ChartsParams params;
  final FilterState filterState;
  final Future<void> Function() onRefresh;

  @override
  ConsumerState<_OverviewTabContent> createState() =>
      _OverviewTabContentState();
}

class _OverviewTabContentState extends ConsumerState<_OverviewTabContent> {
  @override
  Widget build(BuildContext context) {
    final analyticsAsync = ref.watch(analyticsProvider(widget.params));

    String chartTitle = context.l10n.chartsOverviewTitle;
    if (widget.filterState.startDate != null &&
        widget.filterState.endDate != null) {
      chartTitle += context.l10n.chartsDateRangeSuffix(
        FormatHelpers.dateShort(widget.filterState.startDate!),
        FormatHelpers.dateShort(widget.filterState.endDate!),
      );
    }

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: analyticsAsync.when(
          data: (data) {
            final combinedItems = [
              CategoryAmount(
                name: context.l10n.chartsIncome,
                amount: data.incomeTotal,
                colorHex: AppColors.incomeHex,
              ),
              CategoryAmount(
                name: context.l10n.chartsExpense,
                amount: data.expenseTotal,
                colorHex: AppColors.expenseHex,
              ),
            ];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  color: context.colors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: _ChartAndLegend(
                      total: data.incomeTotal + data.expenseTotal,
                      items: combinedItems,
                      title: chartTitle,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _NetRow(income: data.incomeTotal, expense: data.expenseTotal),
              ],
            );
          },
          loading: () => const SizedBox(
            height: 300,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => SizedBox(
            height: 300,
            child: AsyncErrorView(
              error: e,
              onRetry: () => ref.invalidate(analyticsProvider(widget.params)),
            ),
          ),
        ),
      ),
    );
  }
}

/// Dòng "Còn lại" dưới biểu đồ tổng quan.
class _NetRow extends StatelessWidget {
  const _NetRow({required this.income, required this.expense});

  final double income;
  final double expense;

  @override
  Widget build(BuildContext context) {
    final net = income - expense;
    return Card(
      color: context.colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              context.l10n.chartsRemaining,
              style: TextStyle(
                color: context.colors.textSecondary,
                fontSize: 14,
              ),
            ),
            Text(
              FormatHelpers.currency(net),
              style: TextStyle(
                color: net >= 0
                    ? context.colors.income
                    : context.colors.expense,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartAndLegend extends StatefulWidget {
  const _ChartAndLegend({
    required this.total,
    required this.items,
    required this.title,
  });

  final double total;
  final List<CategoryAmount> items;
  final String title;

  @override
  State<_ChartAndLegend> createState() => _ChartAndLegendState();
}

class _ChartAndLegendState extends State<_ChartAndLegend> {
  // Memo theo NỘI DUNG dữ liệu: build lại vì lý do khác (kéo nút nổi, đổi tab)
  // không được phép tính lại slices/parse màu, và nhất là không được cấp
  // list sections mới — list mới làm PieChart chạy lại animation 300ms.
  int? _memoKey;
  List<PieSlice> _displayItems = const [];
  List<PieChartSectionData> _sections = const [];

  double get total => widget.total;
  List<CategoryAmount> get items => widget.items;
  String get title => widget.title;

  void _computeIfNeeded(BuildContext context) {
    final othersLabel = context.l10n.chartsOthers;
    final uncatLabel = context.l10n.commonOther;
    final key = Object.hash(
      total,
      othersLabel,
      uncatLabel,
      Object.hashAll([
        for (final e in items) Object.hash(e.name, e.amount, e.colorHex),
      ]),
    );
    if (key == _memoKey) return;
    _memoKey = key;

    _displayItems = buildPieSlices(
      [
        for (final e in items)
          CategoryAmount(
            name: categoryLabel(context.l10n, e.name),
            amount: e.amount,
            colorHex: e.colorHex,
            iconName: e.iconName,
          ),
      ],
      othersLabel: othersLabel,
      uncategorizedLabel: uncatLabel,
    );
    _sections = _displayItems.map((e) {
      final isOthers = e.isOthers;
      final pct = total > 0 ? (e.amount / total * 100).toStringAsFixed(1) : '0';
      final sliceColor = parseHexColor(e.colorHex);

      return PieChartSectionData(
        value: e.amount,
        title: isOthers ? '' : '$pct%',
        color: sliceColor,
        radius: 60,
        titleStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: sliceColor.computeLuminance() > 0.5
              ? Colors.black
              : Colors.white,
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return SizedBox(
        height: 300,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: TextStyle(
                color: context.colors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              context.l10n.chartsNoData,
              style: TextStyle(
                color: context.colors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    _computeIfNeeded(context);
    final displayItems = _displayItems;
    final sections = _sections;

    return Column(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: context.colors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 250,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 65,
                  sections: sections,
                ),
                duration: const Duration(milliseconds: 300),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    context.l10n.chartsTotal,
                    style: TextStyle(
                      color: context.colors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    FormatHelpers.currency(total),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: context.colors.textPrimary,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        // Legend Group
        Wrap(
          spacing: 16,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: displayItems.map((e) {
            String displayName = e.name;
            if (e.isOthers && total > 0) {
              final pct = (e.amount / total * 100).toStringAsFixed(1);
              displayName = '${e.name} ($pct%)';
            }

            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: parseHexColor(e.colorHex),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  displayName,
                  style: TextStyle(
                    color: context.colors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _Top5List extends StatelessWidget {
  const _Top5List({
    required this.title,
    required this.transactions,
    required this.isIncome,
  });

  final String title;
  final List<TopTransaction> transactions;
  final bool isIncome;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: context.colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: TextStyle(
                color: context.colors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            if (transactions.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    context.l10n.chartsNoTransactions,
                    style: TextStyle(
                      color: context.colors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ),
              )
            else
              ...transactions.map((t) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        margin: const EdgeInsets.only(top: 5),
                        decoration: BoxDecoration(
                          color: parseHexColor(t.colorHex),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              categoryLabel(context.l10n, t.categoryName),
                              style: TextStyle(
                                color: context.colors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              t.note != null && t.note!.trim().isNotEmpty
                                  ? '${FormatHelpers.date(t.transactionDate)} · ${t.note!.trim()}'
                                  : FormatHelpers.date(t.transactionDate),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: context.colors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        FormatHelpers.currency(t.amount),
                        style: TextStyle(
                          color: isIncome
                              ? context.colors.income
                              : context.colors.expense,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
