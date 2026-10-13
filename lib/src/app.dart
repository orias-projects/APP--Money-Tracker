import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_theme.dart';
import 'core/l10n/l10n.dart';
import 'core/routing/app_router.dart';
import 'core/settings/app_lock.dart';
import 'core/settings/app_settings.dart';

class CoinsortApp extends ConsumerWidget {
  const CoinsortApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Chỉ nghe đúng 2 trường dùng ở đây — watch cả object sẽ rebuild
    // MaterialApp.router (toàn bộ cây) mỗi khi bất kỳ setting nào đổi.
    final themeMode = ref.watch(settingsProvider.select((s) => s.themeMode));
    final locale = ref.watch(settingsProvider.select((s) => s.locale));

    return MaterialApp.router(
      onGenerateTitle: (context) => context.l10n.appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: ref.watch(appRouterProvider),
      builder: (context, child) {
        // Android 15+ ép edge-to-edge; app phải tự đặt màu icon status bar
        // theo theme, nếu không icon trắng sẽ tàng hình trên nền sáng.
        final dark = Theme.of(context).brightness == Brightness.dark;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: (dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
              .copyWith(
                statusBarColor: Colors.transparent,
                systemNavigationBarColor: Colors.transparent,
              ),
          // Chắn toàn app khi bật khoá sinh trắc học trong Cài đặt.
          child: AppLockGate(child: child ?? const SizedBox()),
        );
      },
    );
  }
}
