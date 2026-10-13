import 'package:flutter_test/flutter_test.dart';
import 'package:spend_sync/src/core/settings/app_settings.dart';

void main() {
  group('currentFinancialMonth', () {
    test('firstDayOfMonth = 1 khớp đúng tháng dương lịch', () {
      const s = AppSettings(firstDayOfMonth: 1);
      final r = currentFinancialMonth(s, DateTime(2026, 3, 15));
      expect(r.start, DateTime(2026, 3, 1));
      expect(r.end.year, 2026);
      expect(r.end.month, 3);
      expect(r.end.day, 31); // cuối tháng 3
    });

    test('ngày hiện tại trước ngày bắt đầu kỳ → thuộc kỳ tháng trước', () {
      const s = AppSettings(firstDayOfMonth: 10);
      final r = currentFinancialMonth(s, DateTime(2026, 3, 5)); // 5 < 10
      expect(r.start, DateTime(2026, 2, 10));
    });

    test('ngày hiện tại đúng ngày bắt đầu kỳ → thuộc kỳ tháng này', () {
      const s = AppSettings(firstDayOfMonth: 10);
      final r = currentFinancialMonth(s, DateTime(2026, 3, 10));
      expect(r.start, DateTime(2026, 3, 10));
    });

    test('biên tháng 1: ngày trước kỳ lùi về tháng 12 năm trước', () {
      const s = AppSettings(firstDayOfMonth: 15);
      final r = currentFinancialMonth(s, DateTime(2026, 1, 5)); // 5 < 15
      expect(r.start, DateTime(2025, 12, 15));
    });

    test('end luôn ngay trước start của kỳ kế tiếp', () {
      const s = AppSettings(firstDayOfMonth: 20);
      final r = currentFinancialMonth(s, DateTime(2026, 6, 25));
      expect(r.start, DateTime(2026, 6, 20));
      // end = 2026-07-20 trừ 1ms
      expect(r.end.isBefore(DateTime(2026, 7, 20)), isTrue);
      expect(r.end.isAfter(DateTime(2026, 7, 19, 23, 59, 59)), isTrue);
    });
  });
}
