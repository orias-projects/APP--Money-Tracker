import 'package:flutter/material.dart';

import '../core/constants/app_palette.dart';

/// Hình tròn chứa icon; màu xám khi chưa chọn, sáng theo color_hex khi chọn.
/// Text tên danh mục ở dưới.
class CategoryGridItem extends StatelessWidget {
  const CategoryGridItem({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.onLongPress,
    this.icon,
    this.colorHex,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final IconData? icon;
  final String? colorHex;

  /// Đổi `#RRGGBB` sang [Color]. Dùng chung với ô chọn danh mục thu gọn.
  static Color parseHex(String? hex, Color fallback) {
    if (hex == null || hex.isEmpty) return fallback;
    final h = hex.startsWith('#') ? hex : '#$hex';
    if (h.length != 7) return fallback;
    return Color(int.parse(h.substring(1), radix: 16) + 0xFF000000);
  }

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? parseHex(colorHex, context.colors.textSecondary)
        : context.colors.textSecondary;
    // Semantics: đọc tên danh mục + trạng thái chọn; InkWell tự khai báo
    // tap/longPress cho trình đọc màn hình.
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            onLongPress: onLongPress,
            borderRadius: BorderRadius.circular(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: color.withValues(
                    alpha: selected ? 0.35 : 0.15,
                  ),
                  child: Icon(icon ?? Icons.category, color: color, size: 28),
                ),
                const SizedBox(height: 8),
                ExcludeSemantics(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: selected
                          ? context.colors.textPrimary
                          : context.colors.textSecondary,
                      fontWeight: selected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
