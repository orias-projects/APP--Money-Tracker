import 'package:flutter/widgets.dart';

import '../../features/budgets/domain/budget.dart';
import '../../features/recurring/domain/recurring_transaction.dart';
import '../../features/transactions/domain/transaction.dart';
import 'l10n.dart';

/// Nhãn đã dịch cho các enum ở tầng domain.
///
/// Enum domain không nên phụ thuộc BuildContext, nên phần dịch được đặt ở đây và
/// gọi tại nơi hiển thị: `frequency.localizedLabel(context)`.

extension RecurringFrequencyL10n on RecurringFrequency {
  String localizedLabel(BuildContext context) => switch (this) {
    RecurringFrequency.daily => context.l10n.freqDaily,
    RecurringFrequency.weekly => context.l10n.freqWeekly,
    RecurringFrequency.monthly => context.l10n.freqMonthly,
    RecurringFrequency.yearly => context.l10n.freqYearly,
  };
}

extension BudgetPeriodL10n on BudgetPeriod {
  String localizedLabel(BuildContext context) => switch (this) {
    BudgetPeriod.weekly => context.l10n.freqWeekly,
    BudgetPeriod.monthly => context.l10n.freqMonthly,
    BudgetPeriod.yearly => context.l10n.freqYearly,
    BudgetPeriod.custom => context.l10n.periodCustom,
  };
}

extension SplitModeL10n on SplitMode {
  String localizedLabel(BuildContext context) => localizedLabelOf(context.l10n);

  /// Bản không cần BuildContext — cho nơi chỉ có [AppLocalizations]
  /// (xuất CSV chạy ngoài cây widget).
  String localizedLabelOf(AppLocalizations l10n) => switch (this) {
    SplitMode.none => l10n.splitModeNone,
    SplitMode.equal => l10n.splitModeEqual,
    SplitMode.exact => l10n.splitModeExact,
    SplitMode.percent => l10n.splitModePercent,
    SplitMode.shares => l10n.splitModeShares,
  };
}
