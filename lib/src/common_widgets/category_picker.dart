import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_palette.dart';
import '../core/l10n/l10n.dart';
import '../core/utils/category_icons.dart';
import '../features/categories/domain/category.dart';
import '../features/categories/domain/category_label.dart';
import 'category_grid_item.dart';

/// Icon và màu của lựa chọn "Chưa phân loại".
const _kUncategorizedIcon = Icons.help_outline;
const _kUncategorizedColorHex = '#78909C';

/// Ô chọn danh mục ở dạng thu gọn, cùng kiểu với ô "Số tiền".
///
/// Lưới danh mục có 25 mục mặc định cộng mục người dùng tự thêm, mở ra là
/// chiếm gần trọn màn hình và đẩy ví / ngày / ghi chú xuống dưới. Ô này chỉ
/// hiện danh mục đang chọn; bấm vào mới bung lưới, chọn xong thì thu lại.
///
/// `selected == null` nghĩa là **chưa phân loại** — một lựa chọn hợp lệ chứ
/// không phải trạng thái thiếu dữ liệu: `transactions.category_id` cho phép
/// null, và màn Giao dịch / Biểu đồ / CSV đều đã có nhãn riêng cho nó.
class CategoryField extends StatelessWidget {
  const CategoryField({
    super.key,
    required this.selected,
    required this.expanded,
    required this.onTap,
  });

  final Category? selected;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final category = selected;
    final color = CategoryGridItem.parseHex(
      category?.colorHex ?? _kUncategorizedColorHex,
      colors.textSecondary,
    );
    final label = category == null
        ? l10n.categoryUncategorized
        : categoryLabel(l10n, category.name);

    return Semantics(
      button: true,
      expanded: expanded,
      label: '${l10n.txCategoryLabel}: $label',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(28),
          child: InputDecorator(
            decoration: InputDecoration(labelText: l10n.txCategoryLabel),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: color.withValues(alpha: 0.22),
                  child: Icon(
                    category == null
                        ? _kUncategorizedIcon
                        : iconFromName(category.iconName),
                    color: color,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  expanded ? Icons.expand_less : Icons.expand_more,
                  color: colors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Lưới danh mục: ô đầu là "Chưa phân loại", ô cuối là nút thêm mới.
class CategorySelectorGrid extends StatelessWidget {
  const CategorySelectorGrid({
    super.key,
    required this.categories,
    required this.selected,
    required this.onSelect,
    required this.onAdd,
    this.onLongPress,
  });

  final List<Category> categories;
  final Category? selected;

  /// null = chưa phân loại.
  final ValueChanged<Category?> onSelect;
  final VoidCallback onAdd;
  final ValueChanged<Category>? onLongPress;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.85,
        crossAxisSpacing: 8,
        mainAxisSpacing: 16,
      ),
      itemCount: categories.length + 2,
      itemBuilder: (_, i) {
        if (i == 0) {
          return CategoryGridItem(
            label: context.l10n.categoryUncategorized,
            selected: selected == null,
            colorHex: _kUncategorizedColorHex,
            icon: _kUncategorizedIcon,
            onTap: () => onSelect(null),
          );
        }
        if (i == categories.length + 1) {
          return CategoryGridItem(
            label: context.l10n.actionAdd,
            selected: false,
            colorHex: AppColors.primaryHex,
            icon: Icons.add,
            onTap: onAdd,
          );
        }
        final c = categories[i - 1];
        // Chỉ danh mục do người dùng tạo mới sửa/xoá được; 25 danh mục mặc định
        // có user_id = null nên RLS chặn.
        final isOwn = c.userId != null && c.userId!.isNotEmpty;
        return CategoryGridItem(
          label: categoryLabel(context.l10n, c.name),
          selected: selected?.id == c.id,
          colorHex: c.colorHex,
          icon: iconFromName(c.iconName),
          onTap: () => onSelect(c),
          onLongPress: isOwn && onLongPress != null
              ? () => onLongPress!(c)
              : null,
        );
      },
    );
  }
}
