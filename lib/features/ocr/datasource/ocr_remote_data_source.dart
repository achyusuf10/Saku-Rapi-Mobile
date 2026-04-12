import 'dart:convert';
import 'dart:io';

import 'package:app_saku_rapi/core/logger/app_logger.dart';
import 'package:app_saku_rapi/core/network/supabase_handler.dart';
import 'package:app_saku_rapi/core/state/data_state.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Remote data source untuk panggilan Edge Function OCR.
///
/// Mengirim gambar (base64) langsung ke Vision AI (Gemini) untuk parsing struk.
/// Semua panggilan dibungkus [SupabaseHandler.call] untuk error handling.
class OcrRemoteDataSource {
  OcrRemoteDataSource({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  static const _tag = '[OcrRemoteDataSource]';

  /// Kirim gambar struk ke Edge Function `ai-parse` mode `ocr` (Gemini Vision).
  ///
  /// Gambar diencode sebagai base64 dan dikirim ke Gemini Vision.
  /// [categories] berisi daftar kategori expense user untuk auto-assign oleh AI.
  /// Return [DataState] berisi response map dari AI.
  Future<DataState<Map<String, dynamic>>> callAiParseImage(
    File imageFile, {
    List<Map<String, String>> categories = const [],
  }) {
    return SupabaseHandler.call<Map<String, dynamic>>(
      function: () async {
        AppLogger.call('$_tag Calling ai-parse vision (mode: ocr)');

        // Pastikan session masih valid sebelum invoke Edge Function

        final bytes = await imageFile.readAsBytes();
        final base64Image = base64Encode(bytes);

        final body = <String, dynamic>{
          'mode': 'ocr',
          'image': base64Image,
          'mimeType': 'image/jpeg',
        };
        if (categories.isNotEmpty) {
          body['categories'] = categories;
        }

        final response = await _client.functions.invoke('ai-parse', body: body);

        final data = response.data as Map<String, dynamic>;

        if (data['success'] != true) {
          final error = data['error'] as String? ?? 'Unknown error';
          AppLogger.logError('$_tag AI parse failed: $error');
          throw Exception(error);
        }

        AppLogger.logSuccess(
          'AI Vision OCR success (provider: ${data['provider']})',
          runtimeType: OcrRemoteDataSource,
        );
        return data;
      },
    );
  }
}
