import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spend_sync/src/core/constants/app_colors.dart';
import 'package:spend_sync/src/core/utils/category_icons.dart';

void main() {
  group('iconFromName', () {
    test('tên có trong bảng → đúng icon', () {
      expect(iconFromName('restaurant'), Icons.restaurant);
      expect(iconFromName('payments'), Icons.payments);
      expect(iconFromName('savings'), Icons.savings);
    });

    test('tên lạ → fallback Icons.category', () {
      expect(iconFromName('khong_ton_tai'), Icons.category);
    });

    test('null → fallback Icons.category', () {
      expect(iconFromName(null), Icons.category);
    });

    test('chuỗi rỗng → fallback Icons.category', () {
      expect(iconFromName(''), Icons.category);
    });

    test('phân biệt hoa/thường (map dùng key thường) → tên viết hoa là lạ', () {
      expect(iconFromName('Restaurant'), Icons.category);
    });
  });

  group('parseHexColor — hợp lệ', () {
    test('6 ký tự có #', () {
      expect(parseHexColor('#FF4500'), const Color(0xFFFF4500));
    });

    test('6 ký tự không #', () {
      expect(parseHexColor('22C55E'), const Color(0xFF22C55E));
    });

    test('cắt khoảng trắng thừa quanh chuỗi', () {
      expect(parseHexColor('  #3B82F6  '), const Color(0xFF3B82F6));
    });

    test('rút gọn 3 ký tự → nhân đôi mỗi ký tự', () {
      // #F00 → FF0000 → FFFF0000
      expect(parseHexColor('#F00'), const Color(0xFFFF0000));
    });

    test('8 ký tự giữ nguyên alpha', () {
      expect(parseHexColor('#80FF4500'), const Color(0x80FF4500));
    });

    test('chữ thường vẫn parse được', () {
      expect(parseHexColor('#ff4500'), const Color(0xFFFF4500));
    });
  });

  group('parseHexColor — không hợp lệ → fallback', () {
    test('null → fallback mặc định (AppColors.textSecondary)', () {
      expect(parseHexColor(null), AppColors.textSecondary);
    });

    test('chuỗi rỗng → fallback', () {
      expect(parseHexColor(''), AppColors.textSecondary);
    });

    test('toàn khoảng trắng → fallback', () {
      expect(parseHexColor('   '), AppColors.textSecondary);
    });

    test('độ dài lạ (5 ký tự) → fallback', () {
      expect(parseHexColor('#12345'), AppColors.textSecondary);
    });

    test('đủ 6 ký tự nhưng không phải hex → fallback', () {
      expect(parseHexColor('#GGGGGG'), AppColors.textSecondary);
    });

    test('tôn trọng fallback tuỳ biến', () {
      expect(
        parseHexColor(null, fallback: const Color(0xFF123456)),
        const Color(0xFF123456),
      );
      expect(
        parseHexColor('sai', fallback: const Color(0xFF123456)),
        const Color(0xFF123456),
      );
    });
  });
}
