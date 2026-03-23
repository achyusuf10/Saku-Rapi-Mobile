import 'dart:typed_data';

import 'package:app_saku_rapi/core/logger/app_logger.dart';
import 'package:app_saku_rapi/core/network/supabase_handler.dart';
import 'package:app_saku_rapi/core/state/data_state.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service untuk upload gambar ke Supabase Storage bucket 'attachments'.
///
/// File disimpan dalam folder per user: `{userId}/{fileName}`.
/// Menggunakan [SupabaseHandler] untuk error handling terpusat.
class ImageUploadService {
  ImageUploadService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  static const _bucket = 'attachments';
  static const _tag = '[ImageUploadService]';

  /// Upload image bytes ke Supabase Storage.
  ///
  /// Return [DataState] berisi public URL dari file yang diupload.
  /// File disimpan di path: `{userId}/{timestamp}_{fileName}`.
  Future<DataState<String>> uploadImage({
    required Uint8List imageBytes,
    required String fileName,
  }) {
    return SupabaseHandler.call<String>(
      function: () async {
        final userId = _client.auth.currentUser!.id;
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final path = '$userId/${timestamp}_$fileName';

        AppLogger.call('$_tag Uploading image: $path');

        await _client.storage
            .from(_bucket)
            .uploadBinary(
              path,
              imageBytes,
              fileOptions: const FileOptions(
                contentType: 'image/jpeg',
                upsert: true,
              ),
            );

        // Gunakan createSignedUrl untuk RLS-protected bucket
        final signedUrl = await _client.storage
            .from(_bucket)
            .createSignedUrl(path, 60 * 60 * 24 * 365); // 1 tahun

        AppLogger.call('$_tag Upload success: $path');
        return signedUrl;
      },
    );
  }
}
