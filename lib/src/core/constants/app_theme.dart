import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_palette.dart';

const double _inputBorderRadius = 28;
const double _inputBorderWidth = 0.8;

const Color _darkInputBorder = Color(0xFF505050);
const Color _lightInputBorder = Color(0xFFD4D4D4);

/// Bảng màu cho giao diện sáng. Không phải đảo ngược máy móc bảng tối —
/// nền trắng cần chữ đậm hơn và vàng đậm hơn để còn đọc được.
abstract class LightColors {
  static const background = Color(0xFFF7F7F5);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceVariant = Color(0xFFEFEFEC);
  static const primary = Color(
    0xFFB8860B,
  ); // vàng đậm, đủ tương phản trên nền trắng
  static const textPrimary = Color(0xFF16181A);
  static const textSecondary = Color(0xFF5A6169);
  static const textTertiary = Color(0xFF8A9199);
  static const divider = Color(0xFFE2E2DF);
  static const expense = Color(0xFFD23A0E);
  static const income = Color(0xFF15803D);
}

abstract class AppTheme {
  static ThemeData get dark => _build(
    palette: AppPalette.dark,
    brightness: Brightness.dark,
    background: AppColors.background,
    surface: AppColors.surface,
    surfaceVariant: AppColors.surfaceVariant,
    primary: AppColors.primary,
    onPrimary: Colors.black,
    textPrimary: AppColors.textPrimary,
    textSecondary: AppColors.textSecondary,
    divider: AppColors.divider,
    error: AppColors.expense,
    inputBorder: _darkInputBorder,
  );

  static ThemeData get light => _build(
    palette: AppPalette.light,
    brightness: Brightness.light,
    background: LightColors.background,
    surface: LightColors.surface,
    surfaceVariant: LightColors.surfaceVariant,
    primary: LightColors.primary,
    onPrimary: Colors.white,
    textPrimary: LightColors.textPrimary,
    textSecondary: LightColors.textSecondary,
    divider: LightColors.divider,
    error: LightColors.expense,
    inputBorder: _lightInputBorder,
  );

  static ThemeData _build({
    required AppPalette palette,
    required Brightness brightness,
    required Color background,
    required Color surface,
    required Color surfaceVariant,
    required Color primary,
    required Color onPrimary,
    required Color textPrimary,
    required Color textSecondary,
    required Color divider,
    required Color error,
    required Color inputBorder,
  }) {
    OutlineInputBorder border(Color color, [double width = _inputBorderWidth]) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(_inputBorderRadius),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      extensions: [palette],
      scaffoldBackgroundColor: background,
      dividerColor: divider,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: primary,
        onPrimary: onPrimary,
        secondary: primary,
        onSecondary: onPrimary,
        surface: surface,
        onSurface: textPrimary,
        error: error,
        onError: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: background,
        foregroundColor: textPrimary,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      listTileTheme: ListTileThemeData(
        textColor: textPrimary,
        iconColor: textSecondary,
      ),
      dividerTheme: DividerThemeData(color: divider, thickness: 1),
      inputDecorationTheme: InputDecorationTheme(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        labelStyle: TextStyle(color: textSecondary),
        hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.6)),
        filled: true,
        fillColor: surface,
        border: border(inputBorder),
        enabledBorder: border(inputBorder),
        focusedBorder: border(primary, _inputBorderWidth + 0.2),
        errorBorder: border(error),
        focusedErrorBorder: border(error, _inputBorderWidth + 0.2),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          minimumSize: const Size(0, 56),
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: primary),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: onPrimary,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceVariant,
        contentTextStyle: TextStyle(color: textPrimary),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: primary),
    );
  }
}
