import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_palette.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/utils/format_helpers.dart';
import '../../../accounts/presentation/providers/accounts_provider.dart';
import '../providers/filter_provider.dart';

class FilterBottomSheet extends ConsumerStatefulWidget {
  const FilterBottomSheet({super.key});

  static Future<void> show(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const FilterBottomSheet(),
    );
  }

  @override
  ConsumerState<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends ConsumerState<FilterBottomSheet> {
  late int selectedTimeIndex;
  DateTime? tempStart;
  DateTime? tempEnd;
  late List<String> tempAccounts;

  @override
  void initState() {
    super.initState();
    final filterState = ref.read(filterProvider);
    selectedTimeIndex = filterState.selectedTimeIndex;
    tempStart = filterState.startDate;
    tempEnd = filterState.endDate;
    tempAccounts = List.from(filterState.selectedAccountIds);
  }

  void updateTimeByIndex(int index) {
    selectedTimeIndex = index;
    if (index == 0) {
      tempStart = null;
      tempEnd = null;
    } else if (index == 1) {
      final now = DateTime.now();
      tempEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
      tempStart = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(const Duration(days: 6));
    } else if (index == 2) {
      final now = DateTime.now();
      tempEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
      tempStart = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(const Duration(days: 29));
    }
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(accountsListProvider);
    final accounts = accountsAsync.valueOrNull ?? [];

    return Padding(
      padding: EdgeInsets.only(
        // viewPadding.bottom để nút Áp dụng không bị thanh gesture che.
        bottom:
            MediaQuery.viewInsetsOf(context).bottom +
            MediaQuery.viewPaddingOf(context).bottom +
            24,
        top: 24,
        left: 24,
        right: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Nội dung cuộn được để không tràn khi nhiều ví hoặc cỡ chữ lớn;
          // nút Áp dụng luôn cố định bên dưới.
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        context.l10n.filterTitle,
                        style: TextStyle(
                          color: context.colors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            updateTimeByIndex(0);
                            tempAccounts.clear();
                          });
                        },
                        child: Text(context.l10n.filterClear),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    context.l10n.filterTimeLabel,
                    style: TextStyle(color: context.colors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        label: Text(context.l10n.filterTimeAll),
                        selected: selectedTimeIndex == 0,
                        onSelected: (val) {
                          if (val) setState(() => updateTimeByIndex(0));
                        },
                      ),
                      ChoiceChip(
                        label: Text(context.l10n.filterTime7Days),
                        selected: selectedTimeIndex == 1,
                        onSelected: (val) {
                          if (val) setState(() => updateTimeByIndex(1));
                        },
                      ),
                      ChoiceChip(
                        label: Text(context.l10n.filterTime30Days),
                        selected: selectedTimeIndex == 2,
                        onSelected: (val) {
                          if (val) setState(() => updateTimeByIndex(2));
                        },
                      ),
                      ChoiceChip(
                        label: Text(context.l10n.filterTimeCustom),
                        selected: selectedTimeIndex == 3,
                        onSelected: (val) async {
                          if (!val) return;
                          final picked = await showDateRangePicker(
                            context: context,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                            initialDateRange:
                                tempStart != null && tempEnd != null
                                ? DateTimeRange(
                                    start: tempStart!,
                                    end: tempEnd!,
                                  )
                                : null,
                          );
                          if (picked != null) {
                            final diff = picked.end
                                .difference(picked.start)
                                .inDays;
                            if (diff > 90) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(context.l10n.filterMax90Days),
                                  backgroundColor: context.colors.expense,
                                ),
                              );
                              return;
                            }
                            setState(() {
                              selectedTimeIndex = 3;
                              tempStart = picked.start;
                              tempEnd = DateTime(
                                picked.end.year,
                                picked.end.month,
                                picked.end.day,
                                23,
                                59,
                                59,
                              );
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  if (selectedTimeIndex == 3 &&
                      tempStart != null &&
                      tempEnd != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        context.l10n.filterDateRange(
                          FormatHelpers.dateShort(tempStart!),
                          FormatHelpers.dateShort(tempEnd!),
                        ),
                        style: TextStyle(color: context.colors.primary),
                      ),
                    ),
                  const SizedBox(height: 24),
                  Text(
                    context.l10n.filterAccountsLabel,
                    style: TextStyle(color: context.colors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: accounts.map((account) {
                      return FilterChip(
                        label: Text(account.name),
                        selected: tempAccounts.contains(account.id),
                        onSelected: (val) {
                          setState(() {
                            if (val) {
                              tempAccounts.add(account.id);
                            } else {
                              tempAccounts.remove(account.id);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: () {
              ref
                  .read(filterProvider.notifier)
                  .updateFilter(
                    selectedTimeIndex: selectedTimeIndex,
                    startDate: tempStart,
                    endDate: tempEnd,
                    selectedAccountIds: tempAccounts,
                  );
              Navigator.pop(context);
            },
            child: Text(
              context.l10n.filterApply,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
