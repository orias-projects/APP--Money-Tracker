import 'package:flutter/material.dart';

/// Màu sắc theo INTERFACE.md — Dark Theme + Yellow accent.
abstract class AppColors {
  static const Color background = Color(0xFF121212);
  static const Color surface = Color(0xFF1E1E1E);

  /// Nền nổi hơn surface một bậc (ô nhập, chip, hàng được chọn).
  static const Color surfaceVariant = Color(0xFF2A2A2A);

  static const Color primary = Color(0xFFFFD700);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFA0A0A0);

  /// Chữ mờ nhất — chú thích, trạng thái rỗng.
  static const Color textTertiary = Color(0xFF6B6B6B);

  static const Color divider = Color(0xFF2F2F2F);

  static const Color expense = Color(0xFFFF4500);
  static const Color income = Color(0xFF22C55E);

  /// Cảnh báo (vượt ngân sách, sắp tới hạn).
  static const Color warning = Color(0xFFF59E0B);

  /// Thông tin (số dư đã cân, ghi chú hệ thống).
  static const Color info = Color(0xFF3B82F6);

  /// Bản HEX của các màu trạng thái, dùng khi cần truyền chuỗi màu
  /// (biểu đồ, danh mục) thay vì đối tượng [Color].
  static const String expenseHex = '#FF4500';
  static const String incomeHex = '#22C55E';
  static const String primaryHex = '#FFD700';

  /// Màu cho số dư công nợ: dương = người khác nợ mình.
  static Color forNet(double net) {
    if (net > 0.5) return income;
    if (net < -0.5) return expense;
    return textSecondary;
  }
}
