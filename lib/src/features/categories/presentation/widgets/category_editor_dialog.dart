import '../../domain/category_label.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_palette.dart';
import '../../../../core/errors/error_l10n.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/utils/category_icons.dart';
import '../../../shared/presentation/widgets/async_states.dart';
import '../../domain/category.dart';
import '../providers/categories_provider.dart';

/// Hộp thoại thêm/sửa danh mục: tên, biểu tượng, màu.
///
/// Trước đây logic này nằm lẫn trong màn Thêm giao dịch và không cho chọn biểu
/// tượng. Tách ra để màn Quản lý danh mục dùng lại cùng một hộp thoại.
class CategoryEditorDialog extends ConsumerStatefulWidget {
  const CategoryEditorDialog({
    super.key,
    required this.type,
    this.existing,
    this.orderIndex = 0,
  });

  /// 'income' hoặc 'expense'.
  final String type;

  /// Null = tạo mới.
  final Category? existing;

  final int orderIndex;

  static Future<Category?> show(
    BuildContext context, {
    required String type,
    Category? existing,
    int orderIndex = 0,
  }) {
    return showDialog<Category>(
      context: context,
      builder: (_) => CategoryEditorDialog(
        type: type,
        existing: existing,
        orderIndex: orderIndex,
      ),
    );
  }

  @override
  ConsumerState<CategoryEditorDialog> createState() =>
      _CategoryEditorDialogState();
}

class _CategoryEditorDialogState extends ConsumerState<CategoryEditorDialog> {
  late final TextEditingController _nameController;
  late String _colorHex;
  late String _iconName;
  bool _saving = false;
  String? _error;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existing?.name ?? '');
    _colorHex = widget.existing?.colorHex ?? kPickableColors.first;
    _iconName = widget.existing?.iconName ?? 'category';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = context.l10n.categoriesNameRequired);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });

    final repo = ref.read(categoryRepositoryProvider);
    final result = _isEdit
        ? await repo.updateCategory(
            widget.existing!.id,
            name: name,
            colorHex: _colorHex,
            iconName: _iconName,
          )
        : await repo.addCategory(
            name: name,
            type: widget.type,
            colorHex: _colorHex,
            iconName: _iconName,
            orderIndex: widget.orderIndex,
          );

    if (!mounted) return;
    setState(() => _saving = false);

    final category = result.valueOrNull;
    if (category == null) {
      setState(() => _error = result.localizedErrorOrNull(context.l10n));
      return;
    }

    ref.read(categoryVersionProvider.notifier).state++;
    if (mounted) Navigator.of(context).pop(category);
  }

  @override
  Widget build(BuildContext context) {
    final accent = parseHexColor(_colorHex, fallback: context.colors.primary);

    return AlertDialog(
      backgroundColor: context.colors.surface,
      // Cuộn được khi bàn phím che bớt chiều cao, tránh khuất ô đang gõ.
      scrollable: true,
      title: Text(
        _isEdit ? context.l10n.categoriesEditTitle : context.l10n.categoriesAdd,
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: accent.withValues(alpha: 0.25),
                    child: Icon(iconFromName(_iconName), color: accent),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _nameController,
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: context.l10n.categoriesNameLabel,
                        hintText: context.l10n.categoriesNameHint,
                      ),
                      onSubmitted: (_) => _save(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _SectionLabel(context.l10n.categoriesColorLabel),
              const SizedBox(height: 8),
              // Spacing 4 + lề trong 3px mỗi bên của ô 40px = khoảng hở nhìn
              // thấy vẫn là 10px như cũ, nhưng vùng chạm đạt tối thiểu 40x40.
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  for (final hex in kPickableColors)
                    _ColorSwatch(
                      hex: hex,
                      selected: _colorHex == hex,
                      onTap: () => setState(() => _colorHex = hex),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              _SectionLabel(context.l10n.categoriesIconLabel),
              const SizedBox(height: 8),
              SizedBox(
                height: 168,
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: pickableIconNames.length,
                  itemBuilder: (_, i) {
                    final name = pickableIconNames[i];
                    final selected = name == _iconName;
                    return InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => setState(() => _iconName = name),
                      child: Container(
                        decoration: BoxDecoration(
                          color: selected
                              ? accent.withValues(alpha: 0.25)
                              : context.colors.surfaceVariant,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: selected ? accent : Colors.transparent,
                          ),
                        ),
                        child: Icon(
                          iconFromName(name),
                          size: 20,
                          color: selected
                              ? accent
                              : context.colors.textSecondary,
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: TextStyle(color: context.colors.expense, fontSize: 13),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: Text(context.l10n.actionCancel),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          style: FilledButton.styleFrom(
            backgroundColor: context.colors.primary,
            foregroundColor: context.colors.onPrimary,
          ),
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(
                  _isEdit ? context.l10n.actionSave : context.l10n.actionAdd,
                ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: context.colors.textSecondary,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({
    required this.hex,
    required this.selected,
    required this.onTap,
  });

  final String hex;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = parseHexColor(hex);
    // Vùng chạm 40x40 (chuẩn truy cập), hình tròn 34px giữ nguyên như cũ.
    // Nhãn đọc lên là chính mã màu vì bảng màu không có tên riêng.
    return Semantics(
      button: true,
      selected: selected,
      label: hex,
      child: SizedBox(
        width: 40,
        height: 40,
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Center(
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected
                        ? context.colors.textPrimary
                        : Colors.transparent,
                    width: 2.5,
                  ),
                ),
                child: selected
                    ? Icon(
                        Icons.check,
                        color: context.colors.textPrimary,
                        size: 18,
                      )
                    : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Xác nhận xoá mềm một danh mục. Trả về true nếu đã xoá.
Future<bool> confirmDeleteCategory(
  BuildContext context,
  WidgetRef ref,
  Category category,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: context.colors.surface,
      title: Text(context.l10n.categoriesDeleteTitle),
      content: Text(
        context.l10n.categoriesDeleteConfirm(
          categoryLabel(context.l10n, category.name),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(context.l10n.actionCancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: context.colors.expense,
            foregroundColor: Colors.white,
          ),
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(context.l10n.actionDelete),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return false;

  final result = await ref
      .read(categoryRepositoryProvider)
      .softDeleteCategory(category.id);
  ref.read(categoryVersionProvider.notifier).state++;

  if (context.mounted) {
    showResultSnackBar(
      context,
      message: result.errorOrNull ?? context.l10n.categoriesDeleted,
      isError: result.isErr,
    );
  }
  return result.isOk;
}
