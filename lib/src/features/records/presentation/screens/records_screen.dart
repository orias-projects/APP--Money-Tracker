import '../../../categories/domain/category_label.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spend_sync/src/core/l10n/l10n.dart';

import '../../../../common_widgets/transaction_tile.dart';
import '../../../../core/constants/app_palette.dart';
import '../../../../core/utils/format_helpers.dart';
import '../../../../shell/shell_app_bar_provider.dart';
import '../../../accounts/domain/account.dart';
import '../../../accounts/presentation/providers/accounts_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../categories/domain/category.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../../../groups/presentation/providers/active_group_provider.dart';
import '../../../groups/presentation/widgets/group_switcher.dart';
import '../../../shared/presentation/providers/filter_provider.dart';
import '../../../shared/presentation/widgets/async_states.dart';
import '../../../transactions/data/transaction_repository.dart';
import '../../../transactions/domain/transaction.dart';
import '../../../transactions/presentation/providers/transactions_provider.dart';

class RecordsScreen extends ConsumerStatefulWidget {
  const RecordsScreen({super.key});

  @override
  ConsumerState<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends ConsumerState<RecordsScreen> {
  final _scrollController = ScrollController();
  TransactionQuery? _query;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  /// Nạp trang tiếp theo khi còn cách đáy chưa tới 400px.
  void _onScroll() {
    final q = _query;
    if (q == null) return;
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 400) {
      ref.read(pagedTransactionsProvider(q).notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeGroup = ref.watch(activeGroupProvider);
    final filterState = ref.watch(filterProvider);
    final currentUserId = ref.watch(
      currentUserProvider.select((a) => a.valueOrNull?.id),
    );
    final isSharedGroup = activeGroup?.isPersonal == false;

    final query = TransactionQuery(
      groupId: activeGroup?.id ?? '',
      from: filterState.startDate,
      to: filterState.endDate,
      accountIds: filterState.selectedAccountIds.isEmpty
          ? null
          : filterState.selectedAccountIds,
    );
    _query = query;

    final pagedAsync = ref.watch(pagedTransactionsProvider(query));
    final summaryAsync = ref.watch(periodSummaryProvider(query));
    final labelsAsync = ref.watch(accountLabelsProvider(activeGroup?.id ?? ''));
    // Map tra cứu memo hoá trong provider — không dựng lại mỗi build.
    final categoryMap =
        ref.watch(categoryMapProvider).valueOrNull ??
        const <String, Category>{};
    final ownAccountMap = ref.watch(accountMapProvider);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(shellAppBarTitleProvider.notifier)
          .setTitle(
            0,
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: SizedBox(width: 256, child: GroupSwitcher()),
            ),
          );
    });

    final labelMap = labelsAsync.valueOrNull ?? const <String, AccountLabel>{};

    return Scaffold(
      backgroundColor: context.colors.background,
      body: RefreshIndicator(
        onRefresh: () async {
          // Chỉ bump transaction: danh sách, tổng kỳ, nhãn ví và số dư nhóm
          // đều watch biến này. Bump thêm account từng kéo theo 4 request
          // ví không cần thiết cho một cử chỉ kéo-làm-mới.
          ref.read(transactionVersionProvider.notifier).state++;
          await ref.read(pagedTransactionsProvider(query).future);
        },
        child: pagedAsync.when(
          skipLoadingOnRefresh: true,
          loading: () => const _RecordsSkeleton(),
          error: (e, st) => AsyncErrorView(
            error: e,
            onRetry: () => ref.invalidate(pagedTransactionsProvider(query)),
          ),
          data: (page) {
            final sections = _groupByDate(page.items);

            return CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      children: [
                        if (filterState.startDate != null &&
                            filterState.endDate != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              FormatHelpers.dateRange(
                                filterState.startDate!,
                                filterState.endDate!,
                              ),
                              style: TextStyle(
                                color: context.colors.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        _SummaryCard(summaryAsync: summaryAsync),
                        if (isSharedGroup) ...[
                          const SizedBox(height: 12),
                          _SettlementBanner(groupId: activeGroup!.id),
                        ],
                      ],
                    ),
                  ),
                ),
                if (page.items.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: AsyncEmptyView(
                      icon: Icons.receipt_long_outlined,
                      title: context.l10n.recordsEmptyTitle,
                      message: context.l10n.recordsEmptyMessage,
                    ),
                  )
                else
                  SliverList.builder(
                    itemCount: sections.length,
                    itemBuilder: (context, index) {
                      final section = sections[index];
                      return _DaySection(
                        date: section.date,
                        transactions: section.transactions,
                        categoryMap: categoryMap,
                        ownAccountMap: ownAccountMap,
                        labelMap: labelMap,
                        currentUserId: currentUserId,
                        showPaidBy: isSharedGroup,
                      );
                    },
                  ),
                SliverToBoxAdapter(
                  child: _ListFooter(
                    hasMore: page.hasMore,
                    isLoadingMore: page.isLoadingMore,
                    isEmpty: page.items.isEmpty,
                    loadedCount: page.items.length,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // Memo theo identity của trang dữ liệu: danh sách lớn dần khi cuộn vô hạn,
  // sort O(n log n) mỗi build (kể cả build do kéo nút nổi) là phí vô ích.
  List<Transaction>? _groupInput;
  List<_DayGroup>? _groupOutput;

  List<_DayGroup> _groupByDate(List<Transaction> list) {
    if (identical(list, _groupInput)) return _groupOutput!;
    final map = <DateTime, List<Transaction>>{};
    for (final t in list) {
      final d = DateTime(
        t.transactionDate.year,
        t.transactionDate.month,
        t.transactionDate.day,
      );
      map.putIfAbsent(d, () => []).add(t);
    }
    final keys = map.keys.toList()..sort((a, b) => b.compareTo(a));
    _groupInput = list;
    _groupOutput = [
      for (final k in keys) _DayGroup(date: k, transactions: map[k]!),
    ];
    return _groupOutput!;
  }
}

class _DayGroup {
  const _DayGroup({required this.date, required this.transactions});
  final DateTime date;
  final List<Transaction> transactions;
}

// -----------------------------------------------------------------------------

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summaryAsync});

  final AsyncValue<PeriodSummary> summaryAsync;

  @override
  Widget build(BuildContext context) {
    // Lỗi tải tổng kỳ phải khác "kỳ này bằng 0" — hiện lỗi thay vì ba số 0.
    if (summaryAsync.hasError && !summaryAsync.hasValue) {
      return Card(
        color: context.colors.surface,
        child: AsyncErrorView(error: summaryAsync.error!, compact: true),
      );
    }
    final summary = summaryAsync.valueOrNull ?? PeriodSummary.empty;
    final isLoading = summaryAsync.isLoading && !summaryAsync.hasValue;

    return Card(
      color: context.colors.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _SummaryChip(
              label: context.l10n.recordsExpense,
              value: summary.expense,
              color: context.colors.expense,
              isLoading: isLoading,
            ),
            _SummaryChip(
              label: context.l10n.recordsIncome,
              value: summary.income,
              color: context.colors.income,
              isLoading: isLoading,
            ),
            _SummaryChip(
              label: context.l10n.recordsRemaining,
              value: summary.balance,
              color: summary.balance >= 0
                  ? context.colors.textPrimary
                  : context.colors.expense,
              isLoading: isLoading,
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.label,
    required this.value,
    required this.color,
    required this.isLoading,
  });

  final String label;
  final double value;
  final Color color;
  final bool isLoading;

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
        if (isLoading)
          Container(
            width: 64,
            height: 16,
            decoration: BoxDecoration(
              color: context.colors.surfaceVariant,
              borderRadius: BorderRadius.circular(4),
            ),
          )
        else
          Text(
            FormatHelpers.currency(value),
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
      ],
    );
  }
}

/// Nhắc công nợ khi đang ở nhóm chung.
class _SettlementBanner extends ConsumerWidget {
  const _SettlementBanner({required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balancesAsync = ref.watch(groupBalancesProvider(groupId));
    final me = ref.watch(currentUserProvider).valueOrNull?.id;
    final balances = balancesAsync.valueOrNull;
    if (balances == null || me == null) return const SizedBox.shrink();

    final mine = balances.where((b) => b.userId == me).firstOrNull;
    if (mine == null || mine.isSettled) return const SizedBox.shrink();

    final owes = mine.net < 0;
    final amount = mine.net.abs();

    return Card(
      color: context.colors.surface,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/settle-up', extra: groupId),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(
                owes ? Icons.trending_down : Icons.trending_up,
                color: owes ? context.colors.expense : context.colors.income,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  owes
                      ? context.l10n.recordsYouOweGroup(
                          FormatHelpers.currency(amount),
                        )
                      : context.l10n.recordsGroupOwesYou(
                          FormatHelpers.currency(amount),
                        ),
                  style: TextStyle(
                    color: context.colors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: context.colors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------

class _DaySection extends StatelessWidget {
  const _DaySection({
    required this.date,
    required this.transactions,
    required this.categoryMap,
    required this.ownAccountMap,
    required this.labelMap,
    required this.currentUserId,
    required this.showPaidBy,
  });

  final DateTime date;
  final List<Transaction> transactions;
  final Map<String, Category> categoryMap;
  final Map<String, Account> ownAccountMap;
  final Map<String, AccountLabel> labelMap;
  final String? currentUserId;
  final bool showPaidBy;

  /// Tên ví hiển thị được, kể cả ví cá nhân của thành viên khác trong nhóm.
  String? _accountName(String accountId) {
    final own = ownAccountMap[accountId];
    if (own != null) return own.name;
    final label = labelMap[accountId];
    if (label != null) return label.labelFor(isMine: false);
    return null;
  }

  double _dayTotal() {
    var total = 0.0;
    for (final t in transactions) {
      if (t.isExpense) total -= t.amount;
      if (t.isIncome) total += t.amount;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final total = _dayTotal();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 16, 4, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  FormatHelpers.dayHeader(date),
                  style: TextStyle(
                    color: context.colors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  FormatHelpers.currency(total),
                  style: TextStyle(
                    color: total >= 0
                        ? context.colors.income
                        : context.colors.expense,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          ...transactions.map((t) {
            final cat = t.categoryId != null ? categoryMap[t.categoryId] : null;
            final myShare = currentUserId != null
                ? t.shareOf(currentUserId!)
                : 0.0;
            final showShare =
                showPaidBy &&
                t.splitMode.isSplit &&
                myShare > 0 &&
                myShare != t.amount;

            return TransactionTile(
              title: t.isTransfer
                  ? context.l10n.recordsTransfer
                  : (cat == null
                        ? context.l10n.recordsUncategorized
                        : categoryLabel(context.l10n, cat.name)),
              type: t.type,
              subtitle: t.note,
              accountName: _accountName(t.accountId),
              amount: FormatHelpers.currency(t.amount),
              colorHex: cat?.colorHex,
              iconName: cat?.iconName,
              hasReceipt: t.imageUrl != null,
              paidByLabel: showPaidBy
                  ? (t.paidBy == currentUserId
                        ? context.l10n.recordsYou
                        : t.paidByUserName)
                  : null,
              shareLabel: showShare
                  ? context.l10n.recordsYourShare(
                      FormatHelpers.currency(myShare),
                    )
                  : null,
              onTap: () => context.push('/edit-transaction', extra: t),
            );
          }),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------

class _ListFooter extends StatelessWidget {
  const _ListFooter({
    required this.hasMore,
    required this.isLoadingMore,
    required this.isEmpty,
    required this.loadedCount,
  });

  final bool hasMore;
  final bool isLoadingMore;
  final bool isEmpty;
  final int loadedCount;

  @override
  Widget build(BuildContext context) {
    if (isEmpty) return const SizedBox(height: 24);
    if (isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    if (hasMore) return const SizedBox(height: 48);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(
          context.l10n.recordsAllShown(loadedCount),
          style: TextStyle(color: context.colors.textTertiary, fontSize: 12),
        ),
      ),
    );
  }
}

class _RecordsSkeleton extends StatelessWidget {
  const _RecordsSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          height: 76,
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        const SizedBox(height: 24),
        for (var i = 0; i < 6; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: context.colors.surfaceVariant,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    height: 14,
                    decoration: BoxDecoration(
                      color: context.colors.surfaceVariant,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(width: 48),
                Container(
                  width: 72,
                  height: 14,
                  decoration: BoxDecoration(
                    color: context.colors.surfaceVariant,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
