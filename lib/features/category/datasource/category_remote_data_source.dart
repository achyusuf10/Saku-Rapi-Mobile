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
  /// RPC [get_user_categories] menggabungkan kategori global + milik user
  /// dan menyetel `is_hidden` hanya dari tabel [user_category_hidden] (bukan
  /// kolom di `categories` setelah migrasi).
  /// Hasil diurutkan di sisi server (`sort_order`, `name`).
  Future<DataState<List<CategoryModel>>> getCategories() async {
    return SupabaseHandler.call<List<CategoryModel>>(
      function: () async {
        AppLogger.call(
          '[Category] [CategoryRemoteDataSource] Fetching all categories',
          colorLog: ColorLog.blue,
        );

        // `p_type` null = semua tipe; parameter opsional di postgres.
        final response = await _client.rpc('get_user_categories', params: {});

        final categories = (response as List)
            .map((e) => CategoryModel.fromMap(e as Map<String, dynamic>))
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
  /// Tetap lewat [get_user_categories] agar `is_hidden` konsisten dengan merge
  /// `user_category_hidden` (bukan baca tabel [categories] mentah).
  Future<DataState<List<CategoryModel>>> getCategoriesByType(
    CategoryType type,
  ) async {
    return SupabaseHandler.call<List<CategoryModel>>(
      function: () async {
        AppLogger.call(
          '[Category] [CategoryRemoteDataSource] Fetching ${type.value} categories',
          colorLog: ColorLog.blue,
        );

        final response = await _client.rpc(
          'get_user_categories',
          params: {'p_type': type.value},
        );

        final categories = (response as List)
            .map((e) => CategoryModel.fromMap(e as Map<String, dynamic>))
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
    required String backgroundColor,
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
          'background_color': backgroundColor,
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
  /// Sembunyikan/tampilkan: gunakan [toggleHidden] (bukan kolom `is_hidden` di
  /// tabel, setelah migrasi).
  Future<DataState<CategoryModel>> updateCategory({
    required String categoryId,
    String? name,
    String? icon,
    String? color,
    String? backgroundColor,
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
        if (backgroundColor != null) {
          updateData['background_color'] = backgroundColor;
        }
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

        final res = await _client.rpc(
          'toggle_category_hidden',
          params: {'p_category_id': categoryId, 'p_is_hidden': isHidden},
        );
        // PostgREST: SETOF satu baris sering tiba sebagai List satu elemen.
        final Object row;
        if (res is List && res.isNotEmpty) {
          row = res.first;
        } else if (res is Map) {
          row = res;
        } else {
          throw Exception('toggle_category_hidden: respon tak terduga: $res');
        }
        final category = CategoryModel.fromMap(
          Map<String, dynamic>.from(row as Map),
        );

        AppLogger.logSuccess(
          'Category hidden toggled: ${category.name} → isHidden=$isHidden',
          runtimeType: CategoryRemoteDataSource,
        );

        return category;
      },
    );
  }
}
