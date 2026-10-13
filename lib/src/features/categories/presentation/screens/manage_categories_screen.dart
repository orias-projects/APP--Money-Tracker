import '../../domain/category_label.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_palette.dart';
import '../../../../core/errors/error_l10n.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/utils/category_icons.dart';
import '../../../shared/presentation/widgets/async_states.dart';
import '../../domain/category.dart';
import '../providers/categories_provider.dart';
import '../widgets/category_editor_dialog.dart';

/// Quản lý danh mục: sắp xếp bằng kéo thả, sửa, xoá.
///
/// Trước đây chức năng này chỉ tồn tại dưới dạng nhấn-giữ trong màn Thêm giao
/// dịch, không có nơi nào liệt kê đầy đủ và không sắp xếp được.
class ManageCategoriesScreen extends ConsumerStatefulWidget {
  const ManageCategoriesScreen({super.key});

  @override
  ConsumerState<ManageCategoriesScreen> createState() =>
      _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState extends ConsumerState<ManageCategoriesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  /// Thứ tự tạm khi người dùng đang kéo, trước khi lưu xuống server.
  List<Category>? _draftOrder;
  bool _savingOrder = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() => _draftOrder = null);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String get _type => _tabController.index == 0 ? 'expense' : 'income';

  Future<void> _saveOrder(List<Category> ordered) async {
    setState(() {
      _draftOrder = ordered;
      _savingOrder = true;
    });
    final result = await ref.read(categoryRepositoryProvider).reorder(ordered);
    if (!mounted) return;
    setState(() {
      _savingOrder = false;
      _draftOrder = null;
    });
    ref.read(categoryVersionProvider.notifier).state++;
    if (result.isErr && mounted) {
      showResultSnackBar(
        context,
        message:
            result.localizedErrorOrNull(context.l10n) ??
            context.l10n.categoriesReorderFailed,
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: context.colors.background,
        title: Text(context.l10n.categoriesManageTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: context.l10n.commonBack,
          onPressed: () => context.pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: context.colors.primary,
          labelColor: context.colors.primary,
          unselectedLabelColor: context.colors.textSecondary,
          onTap: (_) => setState(() {}),
          tabs: [
            Tab(text: context.l10n.categoriesTabExpense),
            Tab(text: context.l10n.categoriesTabIncome),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => CategoryEditorDialog.show(context, type: _type),
        backgroundColor: context.colors.primary,
        foregroundColor: context.colors.onPrimary,
        icon: const Icon(Icons.add),
        label: Text(context.l10n.categoriesAdd),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _CategoryList(
            type: 'expense',
            draftOrder: _draftOrder,
            savingOrder: _savingOrder,
            onReorder: _saveOrder,
          ),
          _CategoryList(
            type: 'income',
            draftOrder: _draftOrder,
            savingOrder: _savingOrder,
            onReorder: _saveOrder,
          ),
        ],
      ),
    );
  }
}

class _CategoryList extends ConsumerWidget {
  const _CategoryList({
    required this.type,
    required this.draftOrder,
    required this.savingOrder,
    required this.onReorder,
  });

  final String type;
  final List<Category>? draftOrder;
  final bool savingOrder;
  final ValueChanged<List<Category>> onReorder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesByTypeProvider(type));

    return categoriesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => AsyncErrorView(
        error: e,
        onRetry: () => ref.read(categoryVersionProvider.notifier).state++,
      ),
      data: (fromServer) {
        // Trong lúc lưu thứ tự mới, hiện thứ tự người dùng vừa kéo để danh sách
        // không "nhảy" về cũ rồi mới cập nhật.
        final categories = (savingOrder && draftOrder != null)
            ? draftOrder!.where((c) => c.type == type).toList()
            : fromServer;

        if (categories.isEmpty) {
          return AsyncEmptyView(
            icon: Icons.category_outlined,
            title: context.l10n.categoriesEmptyTitle,
            message: type == 'expense'
                ? context.l10n.categoriesEmptyMessageExpense
                : context.l10n.categoriesEmptyMessageIncome,
          );
        }

        final own = categories.where((c) => c.userId != null).toList();
        final system = categories.where((c) => c.userId == null).toList();

        return RefreshIndicator(
          onRefresh: () async {
            ref.read(categoryVersionProvider.notifier).state++;
            await ref.read(categoriesByTypeProvider(type).future);
          },
          child: ListView(
            // Cho phép kéo-làm-mới cả khi danh sách ngắn hơn màn hình.
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 96),
            children: [
              if (own.isNotEmpty) ...[
                _ListLabel(context.l10n.categoriesSectionYours),
                ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  buildDefaultDragHandles: false,
                  itemCount: own.length,
                  onReorder: (oldIndex, newIndex) {
                    final next = List<Category>.from(own);
                    if (newIndex > oldIndex) newIndex--;
                    next.insert(newIndex, next.removeAt(oldIndex));
                    onReorder(next);
                  },
                  itemBuilder: (context, i) {
                    final c = own[i];
                    return _CategoryTile(
                      key: ValueKey(c.id),
                      category: c,
                      index: i,
                      editable: true,
                    );
                  },
                ),
              ],
              if (system.isNotEmpty) ...[
                _ListLabel(context.l10n.categoriesSectionSystem),
                ...system.map(
                  (c) => _CategoryTile(
                    key: ValueKey(c.id),
                    category: c,
                    editable: false,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _ListLabel extends StatelessWidget {
  const _ListLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: context.colors.textTertiary,
          fontSize: 11,
          letterSpacing: 1.1,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _CategoryTile extends ConsumerWidget {
  const _CategoryTile({
    super.key,
    required this.category,
    required this.editable,
    this.index,
  });

  final Category category;
  final bool editable;
  final int? index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = parseHexColor(category.colorHex);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.22),
        child: Icon(iconFromName(category.iconName), color: color, size: 20),
      ),
      title: Text(
        categoryLabel(context.l10n, category.name),
        style: TextStyle(color: context.colors.textPrimary),
      ),
      subtitle: editable
          ? null
          : Text(
              context.l10n.categoriesNotEditable,
              style: TextStyle(
                color: context.colors.textTertiary,
                fontSize: 12,
              ),
            ),
      trailing: editable
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, size: 19),
                  tooltip: context.l10n.actionEdit,
                  onPressed: () => CategoryEditorDialog.show(
                    context,
                    type: category.type,
                    existing: category,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    size: 19,
                    color: context.colors.expense,
                  ),
                  tooltip: context.l10n.actionDelete,
                  onPressed: () =>
                      confirmDeleteCategory(context, ref, category),
                ),
                if (index != null)
                  ReorderableDragStartListener(
                    index: index!,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 4, right: 4),
                      child: Semantics(
                        label: context.l10n.categoriesDragHandle,
                        child: Icon(
                          Icons.drag_handle,
                          color: context.colors.textTertiary,
                        ),
                      ),
                    ),
                  ),
              ],
            )
          : null,
    );
  }
}
