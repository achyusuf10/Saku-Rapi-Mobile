import 'dart:io';

import 'package:app_saku_rapi/core/logger/app_logger.dart';
import 'package:app_saku_rapi/core/network/supabase_handler.dart';
import 'package:app_saku_rapi/core/state/data_state.dart';
import 'package:app_saku_rapi/features/transaction/models/category_model.dart';
import 'package:app_saku_rapi/features/transaction/models/transaction_form_state.dart';
import 'package:app_saku_rapi/features/transaction/models/transaction_item_model.dart';
import 'package:app_saku_rapi/features/transaction/models/transaction_model.dart';
import 'package:app_saku_rapi/utils/function/compress_image_func.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Remote data source untuk semua operasi Supabase terkait transaksi.
///
/// Semua metode dibungkus [SupabaseHandler.call] dan me-return [DataState].
class TransactionRemoteDataSource {
  TransactionRemoteDataSource({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const String _txTable = 'transactions';
  static const String _itemTable = 'transaction_items';
  static const String _categoryTable = 'categories';
  static const String _storageBucket = 'transaction-attachments';

  // ─────────────────────────────────────────────────────────────
  // Save (Atomic via RPC)
  // ─────────────────────────────────────────────────────────────

  /// Menyimpan transaksi beserta semua item-nya secara atomik via Supabase RPC.
  ///
  /// Jika ada [formState.attachmentLocalPath], file di-upload ke Storage
  /// terlebih dahulu dan hasilnya dimasukkan sebagai [attachment_url].
  Future<DataState<TransactionModel>> saveTransaction({
    required TransactionFormState formState,
    required String userId,
  }) {
    return SupabaseHandler.call<TransactionModel>(
      function: () async {
        // 1. Upload attachment jika ada
        String? attachmentUrl;
        if (formState.attachmentLocalPath != null) {
          attachmentUrl = await _uploadAttachment(
            userId: userId,
            localPath: formState.attachmentLocalPath!,
          );
          AppLogger.call(
            '[Transaction] Attachment uploaded: $attachmentUrl',
            colorLog: ColorLog.green,
          );
        }

        // 2. Build items JSON untuk RPC
        final itemsJson = formState.items.asMap().entries.map((entry) {
          final idx = entry.key;
          final item = entry.value;
          return {
            'category_id': item.categoryId ?? '',
            'amount': item.amount ?? 0.0,
            'note': item.note ?? '',
            'sort_order': idx,
          };
        }).toList();

        // 3. Panggil RPC save_transaction (atomic insert transaction + items)
        final result = await _client.rpc(
          'save_transaction',
          params: {
            'p_user_id': userId,
            'p_wallet_id': formState.walletId,
            'p_type': formState.type,
            'p_total_amount': formState.totalAmount,
            'p_date': formState.date.toIso8601String(),
            'p_items': itemsJson,
            'p_destination_wallet_id': formState.destinationWalletId,
            'p_merchant_name': formState.merchantName,
            'p_note': formState.note,
            'p_attachment_url': attachmentUrl,
            'p_with_person': formState.withPerson,
            'p_status': formState.isDebtOrLoan
                ? (formState.status ?? 'unpaid')
                : null,
            'p_due_date': formState.dueDate?.toIso8601String(),
            'p_is_multi_item': formState.isMultiItem,
          },
        );

        return TransactionModel.fromMap((result as Map<String, dynamic>));
      },
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Read
  // ─────────────────────────────────────────────────────────────

  /// Mengambil daftar transaksi dengan filter dan pagination.
  Future<DataState<List<TransactionModel>>> getTransactions({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
    String? walletId,
    int page = 0,
    int limit = 20,
  }) {
    return SupabaseHandler.call<List<TransactionModel>>(
      function: () async {
        var query = _client
            .from(_txTable)
            .select()
            .eq('user_id', userId)
            .gte('date', startDate.toIso8601String())
            .lte('date', endDate.toIso8601String());

        if (walletId != null) {
          query = query.eq('wallet_id', walletId);
        }

        final data = await query
            .order('date', ascending: false)
            .range(page * limit, (page + 1) * limit - 1);

        return (data as List)
            .map((e) => TransactionModel.fromMap(e as Map<String, dynamic>))
            .toList();
      },
    );
  }

  /// Mengambil semua item dari satu transaksi.
  Future<DataState<List<TransactionItemModel>>> getTransactionItems(
    String transactionId,
  ) {
    return SupabaseHandler.call<List<TransactionItemModel>>(
      function: () async {
        final data = await _client
            .from(_itemTable)
            .select()
            .eq('transaction_id', transactionId)
            .order('sort_order');

        return (data as List)
            .map((e) => TransactionItemModel.fromMap(e as Map<String, dynamic>))
            .toList();
      },
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Delete
  // ─────────────────────────────────────────────────────────────

  /// Menghapus transaksi berdasarkan ID.
  ///
  /// Items terkait akan terhapus otomatis via CASCADE di database.
  Future<DataState<bool>> deleteTransaction(String transactionId) {
    return SupabaseHandler.call<bool>(
      function: () async {
        await _client.from(_txTable).delete().eq('id', transactionId);
        return true;
      },
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Update
  // ─────────────────────────────────────────────────────────────

  /// Memperbarui transaksi dan item-itemnya.
  ///
  /// Items lama dihapus semua, lalu items baru diinsert ulang.
  Future<DataState<TransactionModel>> updateTransaction({
    required TransactionModel transaction,
    required List<TransactionItemModel> items,
  }) {
    return SupabaseHandler.call<TransactionModel>(
      function: () async {
        // Update header transaksi
        final updated = await _client
            .from(_txTable)
            .update(transaction.toMap())
            .eq('id', transaction.id)
            .select()
            .single();

        // Hapus items lama
        await _client
            .from(_itemTable)
            .delete()
            .eq('transaction_id', transaction.id);

        // Insert items baru
        final itemMaps = items
            .asMap()
            .entries
            .map(
              (e) => e.value
                  .copyWith(transactionId: transaction.id, sortOrder: e.key)
                  .toMap(),
            )
            .toList();
        await _client.from(_itemTable).insert(itemMaps);

        return TransactionModel.fromMap(updated);
      },
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Categories
  // ─────────────────────────────────────────────────────────────

  /// Mengambil daftar kategori yang tersedia untuk user.
  ///
  /// Mengembalikan kategori default (user_id IS NULL)
  /// dan kategori custom milik user.
  Future<DataState<List<CategoryModel>>> getCategories({
    required String userId,
    String? type,
  }) {
    return SupabaseHandler.call<List<CategoryModel>>(
      function: () async {
        var query = _client
            .from(_categoryTable)
            .select()
            .or('user_id.eq.$userId,user_id.is.null')
            .eq('is_hidden', false);

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
  // Storage
  // ─────────────────────────────────────────────────────────────

  /// Upload file lampiran ke Supabase Storage.
  ///
  /// Return URL publik file yang sudah diupload.
  Future<String> _uploadAttachment({
    required String userId,
    required String localPath,
  }) async {
    final extension = localPath.split('.').last;
    final fileName =
        '$userId/${DateTime.now().millisecondsSinceEpoch}.$extension';
    var tempPath = await getTemporaryDirectory();
    var tempFile = File('${tempPath.path}/$fileName');
    var resCompress = await CompressImageFunc.call(filePath: localPath);
    if (resCompress != null) {
      await tempFile.writeAsBytes(resCompress);
    } else {
      // Kalau compress gagal, fallback pakai file asli
      tempFile = File(localPath);
    }

    await _client.storage.from(_storageBucket).upload(fileName, tempFile);

    return _client.storage.from(_storageBucket).getPublicUrl(fileName);
  }
}
