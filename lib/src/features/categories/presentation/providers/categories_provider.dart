import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/supabase_service.dart';
import '../../data/category_repository.dart';
import '../../domain/category.dart';

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository(ref.watch(supabaseClientProvider));
});

/// Tăng sau mỗi lần thêm/sửa/xoá/sắp xếp danh mục.
final categoryVersionProvider = StateProvider<int>((ref) => 0);

final categoriesListProvider = FutureProvider<List<Category>>((ref) async {
  ref.watch(categoryVersionProvider);
  return ref.read(categoryRepositoryProvider).getCategories();
});

final categoriesByTypeProvider = FutureProvider.family<List<Category>, String>((
  ref,
  type,
) async {
  ref.watch(categoryVersionProvider);
  return ref.read(categoryRepositoryProvider).getCategories(type: type);
});

/// Tra cứu nhanh danh mục theo id khi render danh sách giao dịch.
final categoryMapProvider = FutureProvider<Map<String, Category>>((ref) async {
  final list = await ref.watch(categoriesListProvider.future);
  return {for (final c in list) c.id: c};
});
