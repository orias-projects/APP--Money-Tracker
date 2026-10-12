import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spend_sync/src/common_widgets/category_picker.dart';
import 'package:spend_sync/src/core/l10n/l10n.dart';
import 'package:spend_sync/src/features/categories/domain/category.dart';

Widget wrap(Widget child) => MaterialApp(
  theme: ThemeData.dark(),
  locale: const Locale('vi'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

const shopping = Category(
  id: 'c1',
  name: 'Shopping',
  type: 'expense',
  iconName: 'shopping_cart',
  colorHex: '#FFA500',
);
const myOwn = Category(
  id: 'c2',
  name: 'Cà phê sáng',
  type: 'expense',
  iconName: 'restaurant',
  colorHex: '#FFD700',
  userId: 'u1',
);

void main() {
  group('CategoryField (ô thu gọn)', () {
    testWidgets('chưa chọn gì → hiện "Chưa phân loại"', (tester) async {
      await tester.pumpWidget(
        wrap(CategoryField(selected: null, expanded: false, onTap: () {})),
      );

      expect(find.text('Chưa phân loại'), findsOneWidget);
      // Lưới chưa bung nên mũi tên chỉ xuống.
      expect(find.byIcon(Icons.expand_more), findsOneWidget);
    });

    testWidgets('đã chọn → hiện tên danh mục đã dịch', (tester) async {
      await tester.pumpWidget(
        wrap(CategoryField(selected: shopping, expanded: true, onTap: () {})),
      );

      expect(find.text('Mua sắm'), findsOneWidget);
      expect(find.text('Shopping'), findsNothing);
      expect(find.byIcon(Icons.expand_less), findsOneWidget);
    });

    testWidgets('bấm vào ô gọi onTap để bung/thu lưới', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        wrap(
          CategoryField(selected: null, expanded: false, onTap: () => taps++),
        ),
      );

      await tester.tap(find.byType(CategoryField));
      expect(taps, 1);
    });
  });

  group('CategorySelectorGrid (lưới bung ra)', () {
    testWidgets('ô đầu tiên là "Chưa phân loại", chọn thì trả về null', (
      tester,
    ) async {
      Category? picked = shopping;
      var called = false;
      await tester.pumpWidget(
        wrap(
          CategorySelectorGrid(
            categories: const [shopping, myOwn],
            selected: shopping,
            onSelect: (c) {
              picked = c;
              called = true;
            },
            onAdd: () {},
          ),
        ),
      );

      expect(find.text('Chưa phân loại'), findsOneWidget);
      await tester.tap(find.text('Chưa phân loại'));
      expect(called, isTrue);
      expect(picked, isNull);
    });

    testWidgets('danh mục mặc định được dịch, danh mục tự tạo giữ nguyên', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          CategorySelectorGrid(
            categories: const [shopping, myOwn],
            selected: null,
            onSelect: (_) {},
            onAdd: () {},
          ),
        ),
      );

      expect(find.text('Mua sắm'), findsOneWidget);
      expect(find.text('Cà phê sáng'), findsOneWidget);
    });

    testWidgets('chỉ danh mục của người dùng mới nhấn giữ được', (
      tester,
    ) async {
      final longPressed = <String>[];
      await tester.pumpWidget(
        wrap(
          CategorySelectorGrid(
            categories: const [shopping, myOwn],
            selected: null,
            onSelect: (_) {},
            onAdd: () {},
            onLongPress: (c) => longPressed.add(c.id),
          ),
        ),
      );

      // 25 danh mục mặc định có user_id = null nên RLS chặn sửa/xoá.
      await tester.longPress(find.text('Mua sắm'));
      await tester.longPress(find.text('Cà phê sáng'));
      expect(longPressed, ['c2']);
    });
  });
}
