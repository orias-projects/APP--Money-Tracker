import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spend_sync/src/core/l10n/l10n.dart';
import 'package:spend_sync/src/features/auth/domain/social_provider.dart';
import 'package:spend_sync/src/features/auth/presentation/widgets/social_sign_in_buttons.dart';

Widget wrap(Widget child) => MaterialApp(
  theme: ThemeData.dark(),
  locale: const Locale('vi'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: child),
);

void main() {
  group('SocialSignInButtons', () {
    testWidgets('chỉ vẽ provider đang bật — Facebook và X đã tắt', (
      tester,
    ) async {
      await tester.pumpWidget(wrap(SocialSignInButtons(onPressed: (_) {})));

      // Bấm nút của provider chưa bật bên Supabase chỉ nhận lỗi khó hiểu
      // "provider is not enabled" — thà không hiện nút.
      for (final p in SocialProvider.values) {
        expect(
          find.byWidgetPredicate(
            (w) => w is SocialProviderIcon && w.provider == p,
          ),
          p.isEnabled ? findsOneWidget : findsNothing,
          reason: 'nút ${socialProviderLabel(p)}',
        );
      }
      expect(find.text('Tiếp tục với Facebook'), findsNothing);
      expect(find.text('Tiếp tục với X'), findsNothing);
    });

    testWidgets('bấm nút gọi onPressed đúng provider', (tester) async {
      final tapped = <SocialProvider>[];
      await tester.pumpWidget(wrap(SocialSignInButtons(onPressed: tapped.add)));

      await tester.tap(find.text('Tiếp tục với Google'));
      await tester.pump();

      expect(tapped, [SocialProvider.google]);
    });

    testWidgets('đang xử lý một provider thì mọi nút đều bị khoá', (
      tester,
    ) async {
      final tapped = <SocialProvider>[];
      await tester.pumpWidget(
        wrap(
          SocialSignInButtons(
            onPressed: tapped.add,
            busy: SocialProvider.google,
          ),
        ),
      );

      // Nút đang chạy đổi icon thành vòng xoay, nên tìm theo nút chứ không
      // theo icon provider.
      final buttons = find.byType(OutlinedButton);
      expect(buttons, findsNWidgets(SocialProvider.enabled.length));
      for (var i = 0; i < SocialProvider.enabled.length; i++) {
        await tester.tap(buttons.at(i), warnIfMissed: false);
      }
      await tester.pump();

      expect(tapped, isEmpty);
    });
  });
}
