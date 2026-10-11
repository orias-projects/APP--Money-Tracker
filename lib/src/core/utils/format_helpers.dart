import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Thông tin một đơn vị tiền tệ được hỗ trợ.
class CurrencyInfo {
  const CurrencyInfo({
    required this.code,
    required this.symbol,
    required this.name,
    required this.decimalDigits,
    required this.locale,
  });

  final String code;
  final String symbol;
  final String name;

  /// VND không có phần lẻ; USD/EUR có 2 chữ số.
  final int decimalDigits;

  final String locale;
}

const kSupportedCurrencies = <CurrencyInfo>[
  CurrencyInfo(
    code: 'VND',
    symbol: '₫',
    name: 'Việt Nam Đồng',
    decimalDigits: 0,
    locale: 'vi_VN',
  ),
  CurrencyInfo(
    code: 'USD',
    symbol: r'$',
    name: 'US Dollar',
    decimalDigits: 2,
    locale: 'en_US',
  ),
  CurrencyInfo(
    code: 'EUR',
    symbol: '€',
    name: 'Euro',
    decimalDigits: 2,
    locale: 'de_DE',
  ),
  CurrencyInfo(
    code: 'JPY',
    symbol: '¥',
    name: 'Japanese Yen',
    decimalDigits: 0,
    locale: 'ja_JP',
  ),
  CurrencyInfo(
    code: 'KRW',
    symbol: '₩',
    name: 'Korean Won',
    decimalDigits: 0,
    locale: 'ko_KR',
  ),
  CurrencyInfo(
    code: 'GBP',
    symbol: '£',
    name: 'British Pound',
    decimalDigits: 2,
    locale: 'en_GB',
  ),
  CurrencyInfo(
    code: 'AUD',
    symbol: r'A$',
    name: 'Australian Dollar',
    decimalDigits: 2,
    locale: 'en_AU',
  ),
  CurrencyInfo(
    code: 'SGD',
    symbol: r'S$',
    name: 'Singapore Dollar',
    decimalDigits: 2,
    locale: 'en_SG',
  ),
  CurrencyInfo(
    code: 'CNY',
    symbol: '¥',
    name: 'Chinese Yuan',
    decimalDigits: 2,
    locale: 'zh_CN',
  ),
  CurrencyInfo(
    code: 'THB',
    symbol: '฿',
    name: 'Thai Baht',
    decimalDigits: 2,
    locale: 'th_TH',
  ),
];

CurrencyInfo currencyInfo(String code) {
  for (final c in kSupportedCurrencies) {
    if (c.code == code) return c;
  }
  return kSupportedCurrencies.first;
}

/// Định dạng tiền tệ và ngày tháng.
///
/// Đơn vị mặc định được [setDefaultCurrency] cập nhật từ Cài đặt. Ví có đơn vị
/// riêng thì truyền `currency:` để không hiển thị nhầm ký hiệu.
///
/// Hai locale ĐỘC LẬP: [setDefaultCurrency] quyết định cách nhóm số
/// (150.000 ₫ vs $1,234.56), còn [setDateLocale] — do Cài đặt ngôn ngữ điều
/// khiển — quyết định tên thứ/tháng và các nhãn "Hôm nay"/"Tỷ/Tr/N".
/// Trước đây hai thứ dùng chung một biến nên đổi ngôn ngữ sang English mà
/// ngày tháng vẫn hiện tiếng Việt.
class FormatHelpers {
  static String _defaultCurrency = 'VND';
  static String _numberLocale = 'vi_VN';
  static String _dateLocale = 'vi_VN';
  static bool _hideAmounts = false;

  static String get defaultCurrency => _defaultCurrency;
  static String get locale => _numberLocale;
  static String get dateLocale => _dateLocale;
  static bool get hideAmounts => _hideAmounts;

  /// Chuỗi thay thế khi bật "Ẩn số dư" trong Cài đặt.
  static const maskedAmount = '••••••';

  static void setDefaultCurrency(String code) {
    _defaultCurrency = code;
    _numberLocale = currencyInfo(code).locale;
  }

  static void setDateLocale(String locale) => _dateLocale = locale;

  /// Bật/tắt che số tiền toàn app (tránh nhìn trộm nơi công cộng).
  /// CSV export không đi qua đây nên dữ liệu xuất ra vẫn đầy đủ.
  static void setHideAmounts(bool hide) => _hideAmounts = hide;

  static bool get _viLabels => _dateLocale.startsWith('vi');

  static final _cache = <String, NumberFormat>{};

  static NumberFormat _formatter(String code, {required bool withSymbol}) {
    final key = '$code|$withSymbol|$_numberLocale';
    return _cache.putIfAbsent(key, () {
      final info = currencyInfo(code);
      return NumberFormat.currency(
        locale: _numberLocale,
        symbol: withSymbol ? info.symbol : '',
        decimalDigits: info.decimalDigits,
      );
    });
  }

  /// Số tiền có ký hiệu tiền tệ. VD: `150.000 ₫`.
  static String currency(
    num value, {
    String? currency,
    bool withSymbol = true,
  }) {
    if (_hideAmounts) return maskedAmount;
    final code = currency ?? _defaultCurrency;
    return _formatter(code, withSymbol: withSymbol).format(value).trim();
  }

  /// Số tiền không ký hiệu, dùng khi cột đã có nhãn đơn vị riêng.
  static String amount(num value, {String? currency}) =>
      FormatHelpers.currency(value, currency: currency, withSymbol: false);

  /// Rút gọn cho nhãn biểu đồ: `1,2 Tr` / `1.2M`, `950 N` / `950K`.
  static String compact(num value, {String? currency}) {
    if (_hideAmounts) return maskedAmount;
    final abs = value.abs();
    final code = currency ?? _defaultCurrency;
    final digits = currencyInfo(code).decimalDigits;
    if (digits == 0) {
      final vi = _viLabels;
      if (abs >= 1000000000) {
        final n = (value / 1000000000).toStringAsFixed(1);
        return vi ? '$n Tỷ' : '${n}B';
      }
      if (abs >= 1000000) {
        final n = (value / 1000000).toStringAsFixed(1);
        return vi ? '$n Tr' : '${n}M';
      }
      if (abs >= 1000) {
        final n = (value / 1000).toStringAsFixed(0);
        return vi ? '$n N' : '${n}K';
      }
    }
    return NumberFormat.compact(locale: _numberLocale).format(value);
  }

  /// Chuỗi người dùng nhập (có dấu phân cách) → số.
  static double? parseAmount(String input) {
    final info = currencyInfo(_defaultCurrency);
    var cleaned = input.trim();
    if (cleaned.isEmpty) return null;

    // Bỏ mọi ký tự không phải chữ số, dấu chấm, dấu phẩy, dấu trừ.
    cleaned = cleaned.replaceAll(RegExp(r'[^\d.,-]'), '');
    if (cleaned.isEmpty) return null;

    if (info.decimalDigits == 0) {
      // VND: mọi dấu chấm/phẩy đều là phân cách hàng nghìn.
      cleaned = cleaned.replaceAll(RegExp(r'[.,]'), '');
    } else {
      // Dấu phân cách thập phân là ký tự [.,] xuất hiện cuối cùng.
      final lastDot = cleaned.lastIndexOf('.');
      final lastComma = cleaned.lastIndexOf(',');
      final decimalPos = lastDot > lastComma ? lastDot : lastComma;
      if (decimalPos >= 0) {
        final intPart = cleaned
            .substring(0, decimalPos)
            .replaceAll(RegExp(r'[.,]'), '');
        final decPart = cleaned
            .substring(decimalPos + 1)
            .replaceAll(RegExp(r'[.,]'), '');
        cleaned = '$intPart.$decPart';
      }
    }
    return double.tryParse(cleaned);
  }

  // ---------------------------------------------------------------------------
  // Ngày tháng
  // ---------------------------------------------------------------------------

  static String date(DateTime d) =>
      DateFormat('dd/MM/yyyy', _dateLocale).format(d);

  static String dateShort(DateTime d) =>
      DateFormat('dd/MM/yyyy', _dateLocale).format(d);

  static String dateTime(DateTime d) =>
      DateFormat('dd/MM/yyyy HH:mm', _dateLocale).format(d);

  /// `Thứ Hai, 25 tháng 8` — tiêu đề nhóm ngày trong danh sách giao dịch.
  static String dayHeader(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(d.year, d.month, d.day);
    final diff = today.difference(target).inDays;
    final vi = _viLabels;
    if (diff == 0) return vi ? 'Hôm nay' : 'Today';
    if (diff == 1) return vi ? 'Hôm qua' : 'Yesterday';
    if (diff == -1) return vi ? 'Ngày mai' : 'Tomorrow';
    if (d.year == now.year) {
      return DateFormat('EEEE, d MMMM', _dateLocale).format(d);
    }
    return DateFormat('EEEE, d MMMM y', _dateLocale).format(d);
  }

  static String monthYear(DateTime d) =>
      DateFormat('MMMM y', _dateLocale).format(d);

  /// Khoảng thời gian gọn: `01/08 – 31/08/2026`.
  static String dateRange(DateTime from, DateTime to) {
    if (from.year == to.year) {
      return '${DateFormat('dd/MM', _dateLocale).format(from)} – '
          '${DateFormat('dd/MM/yyyy', _dateLocale).format(to)}';
    }
    return '${date(from)} – ${date(to)}';
  }
}

/// Nhập số tiền có dấu phân cách hàng nghìn theo locale đang dùng.
class AmountInputFormatter extends TextInputFormatter {
  AmountInputFormatter({this.currencyCode});

  final String? currencyCode;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;

    final info = currencyInfo(currencyCode ?? FormatHelpers.defaultCurrency);
    final allowDecimals = info.decimalDigits > 0;

    var raw = newValue.text.replaceAll(
      RegExp(allowDecimals ? r'[^\d.]' : r'[^\d]'),
      '',
    );
    if (raw.isEmpty) {
      return const TextEditingValue(text: '');
    }

    String intPart = raw;
    String decPart = '';
    if (allowDecimals) {
      final parts = raw.split('.');
      intPart = parts.first;
      if (parts.length > 1) {
        decPart = parts.sublist(1).join('');
        if (decPart.length > info.decimalDigits) {
          decPart = decPart.substring(0, info.decimalDigits);
        }
      }
    }

    // Bỏ số 0 thừa ở đầu, nhưng giữ lại "0" đơn lẻ.
    intPart = intPart.replaceFirst(RegExp(r'^0+(?=\d)'), '');

    final grouped = NumberFormat.decimalPattern(
      FormatHelpers.locale,
    ).format(int.tryParse(intPart) ?? 0);

    final hasTrailingDot =
        allowDecimals && raw.endsWith('.') && decPart.isEmpty;
    final result = hasTrailingDot
        ? '$grouped.'
        : (decPart.isEmpty ? grouped : '$grouped.$decPart');

    // Giữ con trỏ ở đúng vị trí tương đối sau khi chèn dấu phân cách.
    final delta = result.length - newValue.text.length;
    final cursor = (newValue.selection.baseOffset + delta).clamp(
      0,
      result.length,
    );

    return TextEditingValue(
      text: result,
      selection: TextSelection.collapsed(offset: cursor),
    );
  }
}
