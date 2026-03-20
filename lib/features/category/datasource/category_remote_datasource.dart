import 'package:app_saku_rapi/core/network/supabase_handler.dart';
import 'package:app_saku_rapi/core/state/data_state.dart';
import 'package:app_saku_rapi/features/category/models/category_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Remote data source untuk operasi CRUD kategori ke Supabase.
///
/// Semua fungsi dibungkus [SupabaseHandler.call] dan
/// mengembalikan [DataState<T>] sesuai aturan arsitektur.
class CategoryRemoteDataSource {
  CategoryRemoteDataSource({required SupabaseClient client}) : _client = client;

  final SupabaseClient _client;

  static const String _table = 'categories';
  static const String _itemTable = 'transaction_items';

  // ─────────────────────────────────────────────────────────────
  // Read
  // ─────────────────────────────────────────────────────────────

  /// Mengambil daftar kategori yang tersedia untuk user.
  ///
  /// Mengembalikan kategori default (user_id IS NULL)
  /// dan kategori custom milik user.
  /// Jika [type] diberikan, filter berdasarkan type (+ 'system').
  /// Jika [includeHidden] true, kategori tersembunyi juga disertakan.
  Future<DataState<List<CategoryModel>>> getCategories({
    required String userId,
    String? type,
    bool includeHidden = true,
  }) {
    return SupabaseHandler.call<List<CategoryModel>>(
      function: () async {
        var query = _client
            .from(_table)
            .select()
            .or('user_id.eq.$userId,user_id.is.null');

        if (!includeHidden) {
          query = query.eq('is_hidden', false);
        }

        if (type != null) {
          query = query.or('type.eq.$type,type.eq.system');
        }

        final data = await query.order('sort_order');

        return (data as List)
            .map((e) => CategoryModel.fromMap(e as Map<String, dynamic>))
            .toList();
      },
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Create
  // ─────────────────────────────────────────────────────────────

  /// Membuat kategori baru. Mengembalikan kategori yang baru dibuat.
  Future<DataState<CategoryModel>> createCategory(CategoryModel category) {
    return SupabaseHandler.call<CategoryModel>(
      function: () async {
        final response = await _client
            .from(_table)
            .insert(category.toMap())
            .select()
            .single();

        return CategoryModel.fromMap(response);
      },
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Update
  // ─────────────────────────────────────────────────────────────

  /// Memperbarui data kategori. Mengembalikan kategori yang sudah diperbarui.
  Future<DataState<CategoryModel>> updateCategory(CategoryModel category) {
    return SupabaseHandler.call<CategoryModel>(
      function: () async {
        final response = await _client
            .from(_table)
            .update(category.toMap())
            .eq('id', category.id)
            .select()
            .single();

        return CategoryModel.fromMap(response);
      },
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Delete
  // ─────────────────────────────────────────────────────────────

  /// Menghapus kategori berdasarkan [categoryId].
  ///
  /// Caller harus memastikan `isDefault == false` sebelum memanggil ini.
  Future<DataState<void>> deleteCategory(String categoryId) {
    return SupabaseHandler.call<void>(
      function: () async {
        await _client.from(_table).delete().eq('id', categoryId);
      },
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Toggle Hide
  // ─────────────────────────────────────────────────────────────

  /// Toggle visibility kategori (hide/show).
  ///
  /// Digunakan terutama untuk menyembunyikan kategori default
  /// yang tidak bisa dihapus.
  Future<DataState<void>> toggleHideCategory(String categoryId, bool isHidden) {
    return SupabaseHandler.call<void>(
      function: () async {
        await _client
            .from(_table)
            .update({'is_hidden': isHidden})
            .eq('id', categoryId);
      },
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Check Usage
  // ─────────────────────────────────────────────────────────────

  /// Mengecek apakah kategori ini digunakan oleh transaksi.
  ///
  /// Return `true` jika ada `transaction_items` yang mereferensikan
  /// kategori ini.
  Future<DataState<bool>> isCategoryUsed(String categoryId) {
    return SupabaseHandler.call<bool>(
      function: () async {
        final data = await _client
            .from(_itemTable)
            .select('id')
            .eq('category_id', categoryId)
            .limit(1);

        return (data as List).isNotEmpty;
      },
    );
  }
}
