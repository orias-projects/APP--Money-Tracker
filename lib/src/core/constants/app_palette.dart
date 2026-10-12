import 'package:flutter/material.dart';

/// Bảng màu ngữ nghĩa của app, đổi theo theme sáng/tối.
///
/// Widget KHÔNG dùng `AppColors` (bảng tối cố định) nữa mà đọc qua
/// `context.colors` — nhờ đó chọn "Giao diện sáng" trong Cài đặt mới thực sự
/// đổi màu toàn app. Hai bộ giá trị nằm ở [AppPalette.dark]/[AppPalette.light]
/// và được đăng ký vào [ThemeData.extensions] trong `app_theme.dart`.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.primary,
    required this.onPrimary,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.divider,
    required this.expense,
    required this.income,
    required this.warning,
    required this.info,
  });

  final Color background;
  final Color surface;

  /// Nền nổi hơn surface một bậc (ô nhập, chip, hàng được chọn).
  final Color surfaceVariant;

  final Color primary;

  /// Chữ/icon đặt trên nền [primary].
  final Color onPrimary;

  final Color textPrimary;
  final Color textSecondary;

  /// Chữ mờ nhất — chú thích, trạng thái rỗng.
  final Color textTertiary;

  final Color divider;
  final Color expense;
  final Color income;

  /// Cảnh báo (vượt ngân sách, sắp tới hạn).
  final Color warning;

  /// Thông tin (số dư đã cân, ghi chú hệ thống).
  final Color info;

  /// Màu cho số dư công nợ: dương = người khác nợ mình.
  Color forNet(double net) {
    if (net > 0.5) return income;
    if (net < -0.5) return expense;
    return textSecondary;
  }

  static const dark = AppPalette(
    background: Color(0xFF121212),
    surface: Color(0xFF1E1E1E),
    surfaceVariant: Color(0xFF2A2A2A),
    primary: Color(0xFFFFD700),
    onPrimary: Colors.black,
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFA0A0A0),
    textTertiary: Color(0xFF6B6B6B),
    divider: Color(0xFF2F2F2F),
    expense: Color(0xFFFF4500),
    income: Color(0xFF22C55E),
    warning: Color(0xFFF59E0B),
    info: Color(0xFF3B82F6),
  );

  /// Không phải đảo ngược máy móc bảng tối — nền trắng cần chữ đậm hơn và
  /// vàng/cam/xanh đậm hơn để còn đủ tương phản.
  static const light = AppPalette(
    background: Color(0xFFF7F7F5),
    surface: Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFFEFEFEC),
    primary: Color(0xFFB8860B),
    onPrimary: Colors.white,
    textPrimary: Color(0xFF16181A),
    textSecondary: Color(0xFF5A6169),
    textTertiary: Color(0xFF8A9199),
    divider: Color(0xFFE2E2DF),
    expense: Color(0xFFD23A0E),
    income: Color(0xFF15803D),
    warning: Color(0xFFB45309),
    info: Color(0xFF1D4ED8),
  );

  @override
  AppPalette copyWith({
    Color? background,
    Color? surface,
    Color? surfaceVariant,
    Color? primary,
    Color? onPrimary,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? divider,
    Color? expense,
    Color? income,
    Color? warning,
    Color? info,
  }) {
    return AppPalette(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceVariant: surfaceVariant ?? this.surfaceVariant,
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      divider: divider ?? this.divider,
      expense: expense ?? this.expense,
      income: income ?? this.income,
      warning: warning ?? this.warning,
      info: info ?? this.info,
    );
  }

  @override
  AppPalette lerp(AppPalette? other, double t) {
    if (other == null) return this;
    return AppPalette(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceVariant: Color.lerp(surfaceVariant, other.surfaceVariant, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      expense: Color.lerp(expense, other.expense, t)!,
      income: Color.lerp(income, other.income, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      info: Color.lerp(info, other.info, t)!,
    );
  }
}

/// Lối tắt đọc bảng màu theo theme hiện hành: `context.colors.expense`.
///
/// Fallback về bảng tối khi theme chưa đăng ký extension (widget test dựng
/// `MaterialApp` trần) để không phải sửa hàng loạt test cũ.
extension AppPaletteX on BuildContext {
  AppPalette get colors =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.dark;
}
