import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spend_sync/src/common_widgets/transaction_tile.dart';
import 'package:spend_sync/src/core/constants/app_colors.dart';
import 'package:spend_sync/src/core/l10n/l10n.dart';

Widget wrap(Widget child) => MaterialApp(
  theme: ThemeData.dark(),
  locale: const Locale('vi'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: child),
);

void main() {
  group('TransactionTile', () {
    testWidgets('khoản chi hiện dấu trừ và màu đỏ', (tester) async {
      await tester.pumpWidget(
        wrap(
          const TransactionTile(
            title: 'Ăn uống',
            amount: '150.000',
            type: 'expense',
            colorHex: '#FFD700',
          ),
        ),
      );

      expect(find.text('Ăn uống'), findsOneWidget);
      expect(find.text('-150.000'), findsOneWidget);

      final text = tester.widget<Text>(find.text('-150.000'));
      expect(text.style?.color, AppColors.expense);
    });

    testWidgets('khoản thu hiện dấu cộng và màu xanh', (tester) async {
      await tester.pumpWidget(
        wrap(
          const TransactionTile(
            title: 'Lương',
            amount: '10.000.000',
            type: 'income',
          ),
        ),
      );

      expect(find.text('+10.000.000'), findsOneWidget);
      final text = tester.widget<Text>(find.text('+10.000.000'));
      expect(text.style?.color, AppColors.income);
    });

    testWidgets('chuyển khoản KHÔNG có dấu +/- và không dùng màu thu/chi', (
      tester,
    ) async {
      // Trước đây transfer bị coi là "không phải chi" nên hiện thành +xanh,
      // khiến người dùng tưởng vừa nhận được tiền.
      await tester.pumpWidget(
        wrap(
          const TransactionTile(
            title: 'Chuyển khoản',
            amount: '500.000',
            type: 'transfer',
          ),
        ),
      );

      expect(find.text('500.000'), findsOneWidget);
      expect(find.text('+500.000'), findsNothing);
      expect(find.text('-500.000'), findsNothing);

      final text = tester.widget<Text>(find.text('500.000'));
      expect(text.style?.color, AppColors.textPrimary);
    });

    testWidgets('hiện tên ví ở cột phải', (tester) async {
      await tester.pumpWidget(
        wrap(
          const TransactionTile(
            title: 'Ăn uống',
            amount: '150.000',
            accountName: 'Tiền mặt',
          ),
        ),
      );
      expect(find.text('Tiền mặt'), findsOneWidget);
    });

    testWidgets('ghép ghi chú và người trả trong nhóm chung', (tester) async {
      await tester.pumpWidget(
        wrap(
          const TransactionTile(
            title: 'Ăn uống',
            amount: '150.000',
            subtitle: 'Cơm trưa',
            paidByLabel: 'Minh',
          ),
        ),
      );
      expect(find.text('Cơm trưa • Trả bởi Minh'), findsOneWidget);
    });

    testWidgets('hiện phần mình gánh khi khoản chi được chia', (tester) async {
      await tester.pumpWidget(
        wrap(
          const TransactionTile(
            title: 'Ăn uống',
            amount: '300.000',
            shareLabel: 'Phần bạn: 100.000',
          ),
        ),
      );
      expect(find.text('Phần bạn: 100.000'), findsOneWidget);
    });

    testWidgets('hiện biểu tượng khi có ảnh hoá đơn', (tester) async {
      await tester.pumpWidget(
        wrap(
          const TransactionTile(
            title: 'Ăn uống',
            amount: '150.000',
            hasReceipt: true,
          ),
        ),
      );
      expect(find.byIcon(Icons.receipt_long), findsOneWidget);
    });

    testWidgets('không có ảnh thì không hiện biểu tượng hoá đơn', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(const TransactionTile(title: 'Ăn uống', amount: '150.000')),
      );
      expect(find.byIcon(Icons.receipt_long), findsNothing);
    });

    testWidgets('dùng đúng biểu tượng của danh mục', (tester) async {
      await tester.pumpWidget(
        wrap(
          const TransactionTile(
            title: 'Ăn uống',
            amount: '150.000',
            iconName: 'restaurant',
          ),
        ),
      );
      expect(find.byIcon(Icons.restaurant), findsOneWidget);
    });

    testWidgets('gọi onTap khi chạm', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        wrap(
          TransactionTile(
            title: 'Ăn uống',
            amount: '150.000',
            onTap: () => tapped = true,
          ),
        ),
      );

      await tester.tap(find.byType(ListTile));
      expect(tapped, isTrue);
    });

    testWidgets('tên dài bị cắt chứ không tràn layout', (tester) async {
      await tester.pumpWidget(
        wrap(
          const TransactionTile(
            title: 'Một danh mục có cái tên rất dài để kiểm tra tràn dòng',
            amount: '150.000',
            accountName: 'Một cái ví cũng có tên rất dài không kém',
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });
}
