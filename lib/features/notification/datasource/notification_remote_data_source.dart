import 'package:app_saku_rapi/core/logger/app_logger.dart';
import 'package:app_saku_rapi/core/network/supabase_handler.dart';
import 'package:app_saku_rapi/core/state/data_state.dart';
import 'package:app_saku_rapi/features/notification/models/notification_settings_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Remote data source untuk CRUD notification_settings di Supabase.
class NotificationRemoteDataSource {
  NotificationRemoteDataSource({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const _table = 'notification_settings';
  static const _tag = '[Notification] [NotificationRemoteDataSource]';

  String get _userId => _client.auth.currentUser!.id;

  /// Ambil notification settings milik user.
  Future<DataState<NotificationSettingsModel>> getSettings() {
    return SupabaseHandler.call<NotificationSettingsModel>(
      function: () async {
        AppLogger.call('$_tag getSettings');
        final response = await _client
            .from(_table)
            .select()
            .eq('user_id', _userId)
            .single();

        return NotificationSettingsModel.fromMap(response);
      },
    );
  }

  /// Update notification settings.
  Future<DataState<NotificationSettingsModel>> updateSettings(
    NotificationSettingsModel settings,
  ) {
    return SupabaseHandler.call<NotificationSettingsModel>(
      function: () async {
        AppLogger.call('$_tag updateSettings: ${settings.id}');
        final response = await _client
            .from(_table)
            .update(settings.toUpdateMap())
            .eq('id', settings.id)
            .select()
            .single();

        return NotificationSettingsModel.fromMap(response);
      },
    );
  }

  /// Update flag notification_sent_50 / notification_sent_80 / notification_sent_100 pada budget.
  Future<DataState<void>> markBudgetNotificationSent({
    required String budgetId,
    required String field,
  }) {
    return SupabaseHandler.call<void>(
      function: () async {
        AppLogger.call('$_tag markBudgetNotificationSent: $budgetId ($field)');
        await _client.from('budgets').update({field: true}).eq('id', budgetId);
      },
    );
  }
}
