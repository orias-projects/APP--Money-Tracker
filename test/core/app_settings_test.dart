import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spend_sync/src/core/settings/app_settings.dart';

void main() {
  group('AppSettings giá trị mặc định', () {
    test('mặc định khớp tài liệu (VND, vi, dark, ngày 1)', () {
      const s = AppSettings();
      expect(s.currency, 'VND');
      expect(s.languageCode, 'vi');
      expect(s.themeMode, ThemeMode.dark);
      expect(s.firstDayOfMonth, 1);
      expect(s.biometricLock, isFalse);
      expect(s.hideAmounts, isFalse);
    });
  });

  group('AppSettings.locale', () {
    test('mặc định → Locale(vi)', () {
      expect(const AppSettings().locale, const Locale('vi'));
    });

    test('theo languageCode', () {
      expect(const AppSettings(languageCode: 'en').locale, const Locale('en'));
    });
  });

  group('AppSettings.copyWith', () {
    const base = AppSettings(
      currency: 'USD',
      languageCode: 'en',
      themeMode: ThemeMode.light,
      firstDayOfMonth: 15,
      biometricLock: true,
      hideAmounts: true,
    );

    test('không tham số → sao chép mọi field y nguyên', () {
      final c = base.copyWith();
      expect(c.currency, base.currency);
      expect(c.languageCode, base.languageCode);
      expect(c.themeMode, base.themeMode);
      expect(c.firstDayOfMonth, base.firstDayOfMonth);
      expect(c.biometricLock, base.biometricLock);
      expect(c.hideAmounts, base.hideAmounts);
    });

    test('đổi currency, giữ field khác', () {
      final c = base.copyWith(currency: 'EUR');
      expect(c.currency, 'EUR');
      expect(c.languageCode, 'en');
      expect(c.themeMode, ThemeMode.light);
      expect(c.firstDayOfMonth, 15);
    });

    test('đổi languageCode kéo theo locale mới', () {
      final c = base.copyWith(languageCode: 'vi');
      expect(c.languageCode, 'vi');
      expect(c.locale, const Locale('vi'));
      expect(c.currency, 'USD'); // giữ nguyên
    });

    test('đổi themeMode, giữ field khác', () {
      final c = base.copyWith(themeMode: ThemeMode.system);
      expect(c.themeMode, ThemeMode.system);
      expect(c.currency, 'USD');
    });

    test('đổi firstDayOfMonth, giữ field khác', () {
      final c = base.copyWith(firstDayOfMonth: 28);
      expect(c.firstDayOfMonth, 28);
      expect(c.biometricLock, isTrue);
    });

    test('đổi biometricLock, giữ field khác', () {
      final c = base.copyWith(biometricLock: false);
      expect(c.biometricLock, isFalse);
      expect(c.hideAmounts, isTrue);
    });

    test('đổi hideAmounts, giữ field khác', () {
      final c = base.copyWith(hideAmounts: false);
      expect(c.hideAmounts, isFalse);
      expect(c.biometricLock, isTrue);
    });

    test('đổi nhiều field cùng lúc', () {
      final c = base.copyWith(currency: 'JPY', hideAmounts: false);
      expect(c.currency, 'JPY');
      expect(c.hideAmounts, isFalse);
      expect(c.languageCode, 'en'); // không đổi
    });
  });
}
