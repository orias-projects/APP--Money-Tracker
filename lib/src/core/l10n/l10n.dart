import 'package:flutter/widgets.dart';
import 'package:spend_sync/l10n/app_localizations.dart';

export 'package:spend_sync/l10n/app_localizations.dart';

/// Lối tắt truy cập chuỗi đã dịch: `context.l10n.actionSave`.
extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
