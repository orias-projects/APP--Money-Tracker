import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_test/flutter_test.dart';
import 'package:spend_sync/src/core/l10n/l10n.dart';
import 'package:spend_sync/src/features/categories/domain/category_label.dart';

void main() {
  late AppLocalizations vi;
  late AppLocalizations en;

  setUpAll(() async {
    vi = await AppLocalizations.delegate.load(const Locale('vi'));
    en = await AppLocalizations.delegate.load(const Locale('en'));
  });

  group('categoryLabel', () {
    test('danh mục mặc định được dịch theo ngôn ngữ', () {
      expect(categoryLabel(vi, 'Food & Dining'), 'Ăn uống');
      expect(categoryLabel(vi, 'Salary'), 'Lương');
      expect(categoryLabel(vi, 'Gifts Received'), 'Quà nhận được');
      expect(categoryLabel(en, 'Food & Dining'), 'Food & Dining');
      expect(categoryLabel(en, 'Salary'), 'Salary');
    });

    test('đủ 25 danh mục seed đều có bản dịch, không sót cái nào', () {
      // Danh sách lấy đúng từ seed trong Assets/SQL/INSTALL_ALL.sql.
      const seeded = [
        'Food & Dining',
        'Health',
        'Beauty',
        'Job',
        'Shopping',
        'Transportation',
        'Housing',
        'Entertainment',
        'Education',
        'Sports',
        'Social',
        'Clothing',
        'Car',
        'Electronics',
        'Travel',
        'Pets',
        'Gifts',
        'Donations',
        'Family',
        'Salary',
        'Bonus',
        'Investment',
        'Freelance',
        'Gifts Received',
        'Others',
      ];
      expect(seeded, hasLength(25));
      for (final name in seeded) {
        expect(
          categoryLabel(vi, name),
          isNot(name),
          reason: '"$name" chưa có bản dịch tiếng Việt',
        );
      }
    });

    test('danh mục người dùng tự đặt giữ nguyên tên', () {
      expect(categoryLabel(vi, 'Cà phê sáng'), 'Cà phê sáng');
      expect(categoryLabel(en, 'Cà phê sáng'), 'Cà phê sáng');
    });

    test('không có danh mục → nhãn "Khác" theo ngôn ngữ', () {
      expect(categoryLabel(vi, null), 'Khác');
      expect(categoryLabel(vi, '  '), 'Khác');
      expect(categoryLabel(en, null), 'Other');
    });

    test('chuỗi "Khác" cứng từ SQL cũng được dịch', () {
      // get_analytics dùng coalesce(c.name, 'Khác') nên máy chủ trả chữ tiếng
      // Việt kể cả khi người dùng để app tiếng Anh.
      expect(categoryLabel(en, 'Khác'), 'Other');
      expect(categoryLabel(vi, 'Khác'), 'Khác');
    });
  });
}
