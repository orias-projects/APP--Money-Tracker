import 'package:flutter_test/flutter_test.dart';
import 'package:spend_sync/src/features/charts/data/analytics_repository.dart';
import 'package:spend_sync/src/features/charts/domain/pie_breakdown.dart';

CategoryAmount _cat(String name, double amount, [String color = '#111111']) =>
    CategoryAmount(name: name, amount: amount, colorHex: color);

void main() {
  group('buildPieSlices', () {
    test('tổng bằng 0 trả về danh sách rỗng', () {
      expect(buildPieSlices([]), isEmpty);
      expect(buildPieSlices([_cat('A', 0)]), isEmpty);
    });

    test('gộp các danh mục nhỏ hơn ngưỡng vào đúng một lát "Khác"', () {
      // total = 100, threshold = 3% = 3
      final slices = buildPieSlices([
        _cat('Ăn uống', 70),
        _cat('Đi lại', 28),
        _cat('Lặt vặt A', 1),
        _cat('Lặt vặt B', 1),
      ]);

      final others = slices.where((s) => s.isOthers).toList();
      expect(others, hasLength(1));
      expect(others.single.amount, 2); // 1 + 1
      expect(
        slices.where((s) => !s.isOthers).map((s) => s.name),
        containsAll(<String>['Ăn uống', 'Đi lại']),
      );
    });

    test(
      'danh mục CÓ THẬT tên "Khác" nhưng đủ lớn không bị coi là lát tổng hợp',
      () {
        // Regression: trước đây so sánh name == "Khác" nên một danh mục thật tên
        // "Khác" bị nuốt vào lát tổng hợp và ẩn mất phần trăm.
        final slices = buildPieSlices([_cat('Ăn uống', 50), _cat('Khác', 50)]);

        final khac = slices.firstWhere((s) => s.name == 'Khác');
        expect(khac.isOthers, isFalse);
        expect(slices.any((s) => s.isOthers), isFalse);
      },
    );

    test('không tạo lát "Khác" khi mọi danh mục đều trên ngưỡng', () {
      final slices = buildPieSlices([_cat('A', 60), _cat('B', 40)]);
      expect(slices.any((s) => s.isOthers), isFalse);
      expect(slices, hasLength(2));
    });

    test('nhãn và màu của lát tổng hợp có thể tuỳ biến', () {
      final slices = buildPieSlices(
        [_cat('A', 98), _cat('B', 1), _cat('C', 1)],
        othersLabel: 'Others',
        othersColorHex: '#CCCCCC',
      );
      final others = slices.firstWhere((s) => s.isOthers);
      expect(others.name, 'Others');
      expect(others.colorHex, '#CCCCCC');
    });
  });
}
