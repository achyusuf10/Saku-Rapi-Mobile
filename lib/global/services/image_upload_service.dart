import 'dart:convert';
import 'dart:typed_data';

import 'package:app_saku_rapi/core/logger/app_logger.dart';
import 'package:app_saku_rapi/core/network/supabase_handler.dart';
import 'package:app_saku_rapi/core/state/data_state.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service untuk upload gambar via Edge Function 'image-upload'.
///
/// Edge function menangani storage routing otomatis:
/// - Primary: Supabase Storage bucket 'attachments' (signed URL 1 tahun)
/// - Fallback: Google Cloud Storage (public URL permanent) jika Supabase penuh
class ImageUploadService {
  ImageUploadService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  static const _tag = '[ImageUploadService]';

  /// Upload image bytes via edge function.
  ///
  /// Return [DataState] berisi URL gambar yang diupload.
  /// URL bisa dari Supabase Storage (signed) atau GCS (public), tergantung kapasitas.
  Future<DataState<String>> uploadImage({
    required Uint8List imageBytes,
    required String fileName,
  }) {
    return SupabaseHandler.call<String>(
      function: () async {
        AppLogger.call('$_tag Uploading image via edge function: $fileName');

        final base64Image = base64Encode(imageBytes);

        final response = await _client.functions.invoke(
          'image-upload',
          body: {
            'imageBase64': base64Image,
            'fileName': fileName,
            'mimeType': 'image/jpeg',
          },
        );

        final url = response.data['url'] as String;
        final storage = response.data['storage'] as String;

        AppLogger.call('$_tag Upload success via $storage: $fileName');
        return url;
      },
    );
  }
}
