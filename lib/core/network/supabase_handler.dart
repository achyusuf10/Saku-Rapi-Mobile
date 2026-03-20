import 'package:app_saku_rapi/core/logger/app_logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../state/data_state.dart';

class SupabaseHandler {
  /// Fungsi pembungkus untuk menangani error Supabase secara terpusat.
  static Future<DataState<T>> call<T>({
    required Future<T> Function() function,
  }) async {
    try {
      final res = await function();
      return DataState.success(data: res);
    } on AuthException catch (e, stackTrace) {
      AppLogger.logError('AuthException: ${e.message}', stackTrace: stackTrace);
      // Menangkap error autentikasi (misal: token kadaluarsa, login gagal)
      return DataState.error(
        message: e.message,
        stackTrace: stackTrace,
        errorData: e,
        exception: e,
      );
    } on PostgrestException catch (e, stackTrace) {
      AppLogger.logError(
        'PostgrestException: ${e.message}',
        stackTrace: stackTrace,
      );
      // Menangkap error database (misal: query salah, RLS melanggar)
      return DataState.error(
        message: e.message,
        errorData: e.code,
        stackTrace: stackTrace,
        exception: e,
      );
    } catch (e, stackTrace) {
      AppLogger.logError(
        'General Exception: ${e.toString()}',
        stackTrace: stackTrace,
      );
      // Menangkap error umum lainnya
      return DataState.error(
        message: e.toString(),
        stackTrace: stackTrace,
        errorData: e,
        exception: e is Exception ? e : Exception(e.toString()),
      );
    }
  }
}
