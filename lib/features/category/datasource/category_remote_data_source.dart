import 'package:app_saku_rapi/core/logger/app_logger.dart';
import 'package:app_saku_rapi/core/network/supabase_handler.dart';
import 'package:app_saku_rapi/core/state/data_state.dart';
import 'package:app_saku_rapi/features/category/models/category_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Remote data source untuk operasi CRUD kategori via Supabase.
///
/// Bertanggung jawab atas:
/// - Fetch semua kategori user berdasarkan type
/// - Insert kategori baru (parent / child)
/// - Update kategori
/// - Delete kategori (soft: hide, hard: delete)
/// - Toggle visibility (hide/show)
///
/// Semua operasi dibungkus dengan [SupabaseHandler.call].
class CategoryRemoteDataSource {
  CategoryRemoteDataSource({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  /// Fetch semua kategori milik user saat ini.
  ///
  /// RLS `categories_select_own_and_system` memastikan hanya
  /// kategori milik user atau system (user_id IS NULL) yang dikembalikan.
  /// Hasil diurutkan berdasarkan `sort_order` lalu `name`.
  Future<DataState<List<CategoryModel>>> getCategories() async {
    return SupabaseHandler.call<List<CategoryModel>>(
      function: () async {
        AppLogger.call(
          '[Category] [CategoryRemoteDataSource] Fetching all categories',
          colorLog: ColorLog.blue,
        );

        final response = await _client
            .from('categories')
            .select()
            .order('sort_order', ascending: true)
            .order('name', ascending: true);

        final categories = (response as List)
            .map((e) => CategoryModel.fromMap(e))
            .toList();

        AppLogger.logSuccess(
          'Fetched ${categories.length} categories',
          runtimeType: CategoryRemoteDataSource,
        );

        return categories;
      },
    );
  }

  /// Fetch kategori berdasarkan [type] (income/expense/system).
  Future<DataState<List<CategoryModel>>> getCategoriesByType(
    CategoryType type,
  ) async {
    return SupabaseHandler.call<List<CategoryModel>>(
      function: () async {
        AppLogger.call(
          '[Category] [CategoryRemoteDataSource] Fetching ${type.value} categories',
          colorLog: ColorLog.blue,
        );

        final response = await _client
            .from('categories')
            .select()
            .eq('type', type.value)
            .order('sort_order', ascending: true)
            .order('name', ascending: true);

        final categories = (response as List)
            .map((e) => CategoryModel.fromMap(e))
            .toList();

        AppLogger.logSuccess(
          'Fetched ${categories.length} ${type.value} categories',
          runtimeType: CategoryRemoteDataSource,
        );

        return categories;
      },
    );
  }

  /// Insert kategori baru ke Supabase.
  ///
  /// Validasi parent-child constraint:
  /// - Jika [parentId] diberikan, parent harus memiliki `type` yang sama.
  /// - Maksimal 2 level (child tidak boleh punya child lagi).
  Future<DataState<CategoryModel>> createCategory({
    required String name,
    required String icon,
    required String color,
    required CategoryType type,
    String? parentId,
  }) async {
    return SupabaseHandler.call<CategoryModel>(
      function: () async {
        AppLogger.call(
          '[Category] [CategoryRemoteDataSource] Creating category: $name',
          colorLog: ColorLog.blue,
        );

        final userId = _client.auth.currentUser?.id;
        if (userId == null) {
          throw Exception('User belum login');
        }

        final data = {
          'user_id': userId,
          'name': name,
          'icon': icon,
          'color': color,
          'type': type.value,
          'parent_id': parentId,
          'is_default': false,
        };

        final response = await _client
            .from('categories')
            .insert(data)
            .select()
            .single();

        final category = CategoryModel.fromMap(response);

        AppLogger.logSuccess(
          'Category created: ${category.name}',
          runtimeType: CategoryRemoteDataSource,
        );

        return category;
      },
    );
  }

  /// Update kategori existing.
  ///
  /// Hanya kategori non-default milik user yang bisa diupdate (RLS).
  Future<DataState<CategoryModel>> updateCategory({
    required String categoryId,
    String? name,
    String? icon,
    String? color,
    bool? isHidden,
    int? sortOrder,
  }) async {
    return SupabaseHandler.call<CategoryModel>(
      function: () async {
        AppLogger.call(
          '[Category] [CategoryRemoteDataSource] Updating category: $categoryId',
          colorLog: ColorLog.blue,
        );

        final updateData = <String, dynamic>{};
        if (name != null) updateData['name'] = name;
        if (icon != null) updateData['icon'] = icon;
        if (color != null) updateData['color'] = color;
        if (isHidden != null) updateData['is_hidden'] = isHidden;
        if (sortOrder != null) updateData['sort_order'] = sortOrder;

        final response = await _client
            .from('categories')
            .update(updateData)
            .eq('id', categoryId)
            .select()
            .single();

        final category = CategoryModel.fromMap(response);

        AppLogger.logSuccess(
          'Category updated: ${category.name}',
          runtimeType: CategoryRemoteDataSource,
        );

        return category;
      },
    );
  }

  /// Hapus kategori (hard delete).
  ///
  /// RLS `categories_delete_own` memastikan hanya kategori
  /// non-default milik user yang bisa dihapus.
  /// Cascade delete: child categories juga akan terhapus.
  Future<DataState<void>> deleteCategory(String categoryId) async {
    return SupabaseHandler.call<void>(
      function: () async {
        AppLogger.call(
          '[Category] [CategoryRemoteDataSource] Deleting category: $categoryId',
          colorLog: ColorLog.yellow,
        );

        await _client.from('categories').delete().eq('id', categoryId);

        AppLogger.logSuccess(
          'Category deleted: $categoryId',
          runtimeType: CategoryRemoteDataSource,
        );
      },
    );
  }

  /// Toggle visibility kategori (hide/show).
  ///
  /// Menggunakan RPC `toggle_category_hidden` (SECURITY DEFINER) agar
  /// kategori default (is_default = true) juga bisa di-hide per user,
  /// tanpa melanggar RLS policy `categories_update_own`.
  Future<DataState<CategoryModel>> toggleHidden({
    required String categoryId,
    required bool isHidden,
  }) async {
    return SupabaseHandler.call<CategoryModel>(
      function: () async {
        AppLogger.call(
          '[Category] [CategoryRemoteDataSource] toggleHidden $categoryId → $isHidden',
          colorLog: ColorLog.blue,
        );

        final response = await _client
            .rpc(
              'toggle_category_hidden',
              params: {'p_category_id': categoryId, 'p_is_hidden': isHidden},
            )
            .select()
            .single();

        final category = CategoryModel.fromMap(response);

        AppLogger.logSuccess(
          'Category hidden toggled: ${category.name} → isHidden=$isHidden',
          runtimeType: CategoryRemoteDataSource,
        );

        return category;
      },
    );
  }
}
