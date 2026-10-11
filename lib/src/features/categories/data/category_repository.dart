import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/result.dart';
import '../domain/category.dart';

class CategoryRepository {
  CategoryRepository(this._client);

  final SupabaseClient _client;

  String? get _userId => _client.auth.currentUser?.id;

  /// Danh mục hệ thống (user_id null) + danh mục riêng của user, chỉ bản active.
  Future<List<Category>> getCategories({String? type}) async {
    final uid = _userId;
    try {
      var query = _client
          .from('categories')
          .select()
          .eq('is_active', true)
          .or('status.is.null,status.eq.active');

      if (type != null) query = query.eq('type', type);
      if (uid != null) {
        query = query.or('user_id.is.null,user_id.eq.$uid');
      } else {
        query = query.isFilter('user_id', null);
      }

      final res = await query.order('order_index').order('name');
      return (res as List)
          .map((e) => Category.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      throw mapError(e, st);
    }
  }

  Future<Result<Category>> addCategory({
    required String name,
    required String type,
    String iconName = 'category',
    String colorHex = '#6B7280',
    int orderIndex = 0,
    String? parentId,
  }) {
    return Result.guard(() async {
      final uid = _userId;
      if (uid == null) {
        throw const AppException(
          'Chưa đăng nhập. Vui lòng đăng nhập lại.',
          kind: AppErrorKind.auth,
          code: AppErrorCode.notLoggedIn,
        );
      }
      if (name.trim().isEmpty) {
        throw const AppException(
          'Tên danh mục không được để trống.',
          kind: AppErrorKind.validation,
          code: AppErrorCode.categoryNameEmpty,
        );
      }
      final res = await _client
          .from('categories')
          .insert({
            'user_id': uid,
            'parent_id': parentId,
            'name': name.trim(),
            'type': type,
            'icon_name': iconName,
            'color_hex': colorHex,
            'order_index': orderIndex,
            'is_active': true,
          })
          .select()
          .single();
      return Category.fromMap(res);
    });
  }

  /// Chỉ sửa được danh mục do chính user tạo. Danh mục hệ thống bất biến.
  Future<Result<Category>> updateCategory(
    String categoryId, {
    String? name,
    String? iconName,
    String? colorHex,
    int? orderIndex,
  }) {
    return Result.guard(() async {
      final uid = _userId;
      if (uid == null) {
        throw const AppException(
          'Chưa đăng nhập.',
          kind: AppErrorKind.auth,
          code: AppErrorCode.notLoggedIn,
        );
      }
      final map = <String, dynamic>{};
      if (name != null) map['name'] = name.trim();
      if (iconName != null) map['icon_name'] = iconName;
      if (colorHex != null) map['color_hex'] = colorHex;
      if (orderIndex != null) map['order_index'] = orderIndex;
      if (map.isEmpty) {
        throw const AppException(
          'Không có thay đổi nào để lưu.',
          code: AppErrorCode.nothingToSave,
        );
      }
      final res = await _client
          .from('categories')
          .update(map)
          .eq('id', categoryId)
          .eq('user_id', uid)
          .select()
          .single();
      return Category.fromMap(res);
    });
  }

  /// Lưu số thứ tự mới sau khi người dùng kéo thả sắp xếp.
  Future<Result<void>> reorder(List<Category> ordered) {
    return Result.guard(() async {
      final uid = _userId;
      if (uid == null) {
        throw const AppException(
          'Chưa đăng nhập.',
          kind: AppErrorKind.auth,
          code: AppErrorCode.notLoggedIn,
        );
      }
      // Gửi song song thay vì chờ từng UPDATE một (tránh N+1 tuần tự).
      final updates = <Future<void>>[];
      for (var i = 0; i < ordered.length; i++) {
        final c = ordered[i];
        if (c.userId != uid) continue; // danh mục hệ thống: bỏ qua
        if (c.orderIndex == i) continue;
        updates.add(
          _client
              .from('categories')
              .update({'order_index': i})
              .eq('id', c.id)
              .eq('user_id', uid),
        );
      }
      await Future.wait(updates);
    });
  }

  /// Xoá mềm. Giao dịch cũ giữ nguyên category_id để lịch sử không mất nhãn.
  Future<Result<void>> softDeleteCategory(String categoryId) {
    return Result.guard(() async {
      final uid = _userId;
      if (uid == null) {
        throw const AppException(
          'Chưa đăng nhập.',
          kind: AppErrorKind.auth,
          code: AppErrorCode.notLoggedIn,
        );
      }
      await _client
          .from('categories')
          .update({'status': 'deleted', 'is_active': false})
          .eq('id', categoryId)
          .eq('user_id', uid);
    });
  }
}
