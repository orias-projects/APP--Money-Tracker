import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:spend_sync/src/core/utils/format_helpers.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('vi_VN');
    await initializeDateFormatting('en_US');
  });

  setUp(() {
    FormatHelpers.setDefaultCurrency('VND');
  });

  group('FormatHelpers.parseAmount', () {
    test('VND: dấu chấm và phẩy đều là phân cách hàng nghìn', () {
      expect(FormatHelpers.parseAmount('150.000'), 150000);
      expect(FormatHelpers.parseAmount('150,000'), 150000);
      expect(FormatHelpers.parseAmount('1.234.567'), 1234567);
    });

    test('VND: bỏ ký hiệu tiền tệ và khoảng trắng', () {
      expect(FormatHelpers.parseAmount('150.000 ₫'), 150000);
      expect(FormatHelpers.parseAmount('  99  '), 99);
    });

    test('USD: dấu chấm cuối là phân cách thập phân', () {
      FormatHelpers.setDefaultCurrency('USD');
      expect(FormatHelpers.parseAmount('1,234.56'), closeTo(1234.56, 0.001));
      expect(FormatHelpers.parseAmount('99.99'), closeTo(99.99, 0.001));
    });

    test('chuỗi rỗng hoặc không có số trả null', () {
      expect(FormatHelpers.parseAmount(''), isNull);
      expect(FormatHelpers.parseAmount('   '), isNull);
      expect(FormatHelpers.parseAmount('abc'), isNull);
      expect(FormatHelpers.parseAmount('₫'), isNull);
    });

    test('vòng lặp format → parse giữ nguyên giá trị', () {
      for (final value in [0, 1, 999, 150000, 1234567, 99999999]) {
        final formatted = FormatHelpers.amount(value);
        expect(
          FormatHelpers.parseAmount(formatted),
          value.toDouble(),
          reason: 'format("$value") = "$formatted" phải parse lại đúng',
        );
      }
    });
  });

  group('FormatHelpers.currency', () {
    test('VND làm tròn, không hiện phần lẻ', () {
      // decimalDigits = 0 → 150000.7 hiện thành 150.001, không phải 150.000,70
      expect(FormatHelpers.currency(150000), FormatHelpers.currency(150000.4));
      expect(FormatHelpers.currency(1.4), FormatHelpers.currency(1));
    });

    test('USD giữ hai chữ số thập phân', () {
      // Cách nhóm số theo locale người dùng (vi_VN dùng dấu phẩy thập phân),
      // ký hiệu theo đơn vị của ví. 99.5 → "99,50 $".
      final result = FormatHelpers.currency(99.5, currency: 'USD');
      expect(result, contains('99'));
      expect(result, contains('50'));
      expect(result, contains(r'$'));
      expect(
        FormatHelpers.currency(99, currency: 'USD'),
        isNot(FormatHelpers.currency(99.5, currency: 'USD')),
      );
    });

    test('mỗi ví giữ ký hiệu riêng, không bị đơn vị mặc định ghi đè', () {
      FormatHelpers.setDefaultCurrency('VND');
      expect(FormatHelpers.currency(100, currency: 'USD'), contains(r'$'));
      expect(FormatHelpers.currency(100), contains('₫'));
    });

    test('số âm giữ được dấu', () {
      expect(FormatHelpers.currency(-50000), contains('50'));
      expect(FormatHelpers.currency(-50000), contains('-'));
    });
  });

  group('AmountInputFormatter', () {
    TextEditingValue apply(String oldText, String newText) {
      return AmountInputFormatter().formatEditUpdate(
        TextEditingValue(text: oldText),
        TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: newText.length),
        ),
      );
    }

    test('chèn dấu phân cách hàng nghìn khi gõ', () {
      expect(apply('', '150000').text, FormatHelpers.amount(150000));
    });

    test('bỏ số 0 thừa ở đầu', () {
      expect(apply('', '000123').text, FormatHelpers.amount(123));
    });

    test('giữ lại số 0 đơn lẻ', () {
      expect(apply('', '0').text, '0');
    });

    test('chuỗi rỗng trả về rỗng', () {
      expect(apply('123', '').text, '');
    });

    test('bỏ ký tự không phải chữ số', () {
      expect(apply('', '1a2b3').text, FormatHelpers.amount(123));
    });

    test('VND không cho nhập phần thập phân', () {
      FormatHelpers.setDefaultCurrency('VND');
      expect(apply('', '100.50').text, FormatHelpers.amount(10050));
    });

    test('con trỏ không vượt quá độ dài chuỗi', () {
      final result = apply('', '1234567');
      expect(
        result.selection.baseOffset,
        lessThanOrEqualTo(result.text.length),
      );
      expect(result.selection.baseOffset, greaterThanOrEqualTo(0));
    });
  });

  group('FormatHelpers.dayHeader', () {
    test('hôm nay và hôm qua hiển thị bằng chữ', () {
      final now = DateTime.now();
      expect(FormatHelpers.dayHeader(now), 'Hôm nay');
      expect(
        FormatHelpers.dayHeader(now.subtract(const Duration(days: 1))),
        'Hôm qua',
      );
    });

    test('ngày xa hơn hiển thị thứ và ngày', () {
      final old = DateTime.now().subtract(const Duration(days: 10));
      final header = FormatHelpers.dayHeader(old);
      expect(header, isNot('Hôm nay'));
      expect(header, isNot('Hôm qua'));
      expect(header.isNotEmpty, isTrue);
    });
  });

  group('currencyInfo', () {
    test('mã không xác định rơi về VND', () {
      expect(currencyInfo('XYZ').code, 'VND');
    });

    test('VND không có phần lẻ, USD có 2 chữ số', () {
      expect(currencyInfo('VND').decimalDigits, 0);
      expect(currencyInfo('USD').decimalDigits, 2);
    });
  });
}
