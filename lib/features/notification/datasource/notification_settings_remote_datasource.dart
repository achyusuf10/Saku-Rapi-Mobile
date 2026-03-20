import 'package:app_saku_rapi/core/network/supabase_handler.dart';
import 'package:app_saku_rapi/core/state/data_state.dart';
import 'package:app_saku_rapi/features/notification/models/notification_settings_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Remote data source untuk tabel `notification_settings`.
///
/// Semua fungsi dibungkus [SupabaseHandler.call] dan me-return [DataState].
class NotificationSettingsRemoteDataSource {
  NotificationSettingsRemoteDataSource({required this.client});

  final SupabaseClient client;

  /// Ambil settings milik [userId], atau buat baru jika belum ada.
  ///
  /// Menggunakan `upsert` dengan `onConflict: 'user_id'`
  /// sehingga row default tercipta otomatis jika belum ada.
  Future<DataState<NotificationSettingsModel>> getOrCreate(
    String userId,
  ) async {
    return SupabaseHandler.call<NotificationSettingsModel>(
      function: () async {
        // Coba ambil existing row
        final existing = await client
            .from('notification_settings')
            .select()
            .eq('user_id', userId)
            .maybeSingle();

        if (existing != null) {
          return NotificationSettingsModel.fromMap(existing);
        }

        // Belum ada → insert default
        final created = await client
            .from('notification_settings')
            .insert({'user_id': userId})
            .select()
            .single();

        return NotificationSettingsModel.fromMap(created);
      },
    );
  }

  /// Update settings ke Supabase.
  Future<DataState<NotificationSettingsModel>> update({
    required String userId,
    required NotificationSettingsModel settings,
  }) async {
    return SupabaseHandler.call<NotificationSettingsModel>(
      function: () async {
        final result = await client
            .from('notification_settings')
            .update(settings.toUpdateMap())
            .eq('user_id', userId)
            .select()
            .single();

        return NotificationSettingsModel.fromMap(result);
      },
    );
  }
}
