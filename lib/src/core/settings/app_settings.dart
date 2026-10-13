import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/format_helpers.dart';

/// Cài đặt của người dùng, lưu cục bộ bằng SharedPreferences.
@immutable
class AppSettings {
  const AppSettings({
    this.currency = 'VND',
    this.languageCode = 'vi',
    this.themeMode = ThemeMode.dark,
    this.firstDayOfMonth = 1,
    this.biometricLock = false,
    this.hideAmounts = false,
  });

  final String currency;
  final String languageCode;
  final ThemeMode themeMode;

  /// Ngày bắt đầu kỳ tài chính (1–28). Hữu ích khi lương về giữa tháng.
  final int firstDayOfMonth;

  /// Yêu cầu vân tay / Face ID khi mở app.
  final bool biometricLock;

  /// Ẩn số tiền (chế độ riêng tư nơi công cộng).
  final bool hideAmounts;

  Locale get locale => Locale(languageCode);

  AppSettings copyWith({
    String? currency,
    String? languageCode,
    ThemeMode? themeMode,
    int? firstDayOfMonth,
    bool? biometricLock,
    bool? hideAmounts,
  }) {
    return AppSettings(
      currency: currency ?? this.currency,
      languageCode: languageCode ?? this.languageCode,
      themeMode: themeMode ?? this.themeMode,
      firstDayOfMonth: firstDayOfMonth ?? this.firstDayOfMonth,
      biometricLock: biometricLock ?? this.biometricLock,
      hideAmounts: hideAmounts ?? this.hideAmounts,
    );
  }
}

class SettingsNotifier extends Notifier<AppSettings> {
  static const _kCurrency = 'settings.currency';
  static const _kLanguage = 'settings.language';
  static const _kTheme = 'settings.theme';
  static const _kFirstDay = 'settings.first_day_of_month';
  static const _kBiometric = 'settings.biometric_lock';
  static const _kHideAmounts = 'settings.hide_amounts';

  @override
  AppSettings build() {
    // Giá trị mặc định hiển thị ngay; giá trị đã lưu nạp bất đồng bộ ngay sau đó.
    _load();
    return const AppSettings();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final loaded = AppSettings(
      currency: prefs.getString(_kCurrency) ?? 'VND',
      languageCode: prefs.getString(_kLanguage) ?? 'vi',
      themeMode: _themeFromName(prefs.getString(_kTheme)),
      firstDayOfMonth: prefs.getInt(_kFirstDay) ?? 1,
      biometricLock: prefs.getBool(_kBiometric) ?? false,
      hideAmounts: prefs.getBool(_kHideAmounts) ?? false,
    );
    FormatHelpers.setDefaultCurrency(loaded.currency);
    FormatHelpers.setDateLocale(_dateLocaleFor(loaded.languageCode));
    FormatHelpers.setHideAmounts(loaded.hideAmounts);
    state = loaded;
  }

  Future<void> setCurrency(String code) async {
    FormatHelpers.setDefaultCurrency(code);
    state = state.copyWith(currency: code);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kCurrency, code);
  }

  Future<void> setLanguage(String code) async {
    // Ngày tháng ("Thứ Hai", "Monday") đi theo NGÔN NGỮ, không theo tiền tệ.
    FormatHelpers.setDateLocale(_dateLocaleFor(code));
    state = state.copyWith(languageCode: code);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLanguage, code);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kTheme, mode.name);
  }

  Future<void> setFirstDayOfMonth(int day) async {
    final clamped = day.clamp(1, 28);
    state = state.copyWith(firstDayOfMonth: clamped);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kFirstDay, clamped);
  }

  Future<void> setBiometricLock(bool value) async {
    state = state.copyWith(biometricLock: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kBiometric, value);
  }

  Future<void> setHideAmounts(bool value) async {
    FormatHelpers.setHideAmounts(value);
    state = state.copyWith(hideAmounts: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kHideAmounts, value);
  }

  static String _dateLocaleFor(String languageCode) =>
      languageCode == 'vi' ? 'vi_VN' : 'en_US';

  static ThemeMode _themeFromName(String? name) {
    return switch (name) {
      'light' => ThemeMode.light,
      'system' => ThemeMode.system,
      _ => ThemeMode.dark,
    };
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);

/// Kỳ tài chính hiện tại theo `firstDayOfMonth`.
({DateTime start, DateTime end}) currentFinancialMonth(
  AppSettings s, [
  DateTime? now,
]) {
  final today = now ?? DateTime.now();
  final day = s.firstDayOfMonth;
  final start = today.day >= day
      ? DateTime(today.year, today.month, day)
      : DateTime(today.year, today.month - 1, day);
  final end = DateTime(
    start.year,
    start.month + 1,
    start.day,
  ).subtract(const Duration(milliseconds: 1));
  return (start: start, end: end);
}
