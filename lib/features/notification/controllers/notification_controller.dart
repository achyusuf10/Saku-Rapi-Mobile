import 'package:app_saku_rapi/features/notification/models/notification_settings_model.dart';
import 'package:app_saku_rapi/features/notification/repositories/notification_repository.dart';
import 'package:app_saku_rapi/features/notification/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:permission_handler/permission_handler.dart';

// ───────────────── Providers ─────────────────

/// Provider singleton untuk [NotificationRepository].
final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository();
});

/// Provider utama untuk notification settings state.
final notificationControllerProvider =
    StateNotifierProvider<NotificationController, NotificationSettingsState>((
      ref,
    ) {
      final repository = ref.watch(notificationRepositoryProvider);
      return NotificationController(repository);
    });

/// Provider computed: apakah reminder enabled.
final isReminderEnabledProvider = Provider<bool>((ref) {
  return ref.watch(
    notificationControllerProvider.select(
      (s) => s.settings?.reminderEnabled ?? false,
    ),
  );
});

/// Provider computed: apakah budget alert enabled.
final isBudgetAlertEnabledProvider = Provider<bool>((ref) {
  return ref.watch(
    notificationControllerProvider.select(
      (s) => s.settings?.budgetAlertEnabled ?? true,
    ),
  );
});

/// Provider computed: apakah debt reminder enabled.
final isDebtReminderEnabledProvider = Provider<bool>((ref) {
  return ref.watch(
    notificationControllerProvider.select(
      (s) => s.settings?.debtReminderEnabled ?? true,
    ),
  );
});

/// Provider computed: reminder time.
final reminderTimeProvider = Provider<TimeOfDay?>((ref) {
  return ref.watch(
    notificationControllerProvider.select((s) => s.settings?.reminderTime),
  );
});

/// Provider computed: debt reminder days before.
final debtReminderDaysProvider = Provider<int>((ref) {
  return ref.watch(
    notificationControllerProvider.select(
      (s) => s.settings?.debtReminderDaysBefore ?? 3,
    ),
  );
});

/// Provider computed: permission status.
final notifPermissionStatusProvider = Provider<PermissionStatus?>((ref) {
  return ref.watch(
    notificationControllerProvider.select((s) => s.permissionStatus),
  );
});

// ───────────────── State ─────────────────

enum NotificationSettingsStatus { initial, loading, loaded, saving, error }

class NotificationSettingsState {
  const NotificationSettingsState({
    this.status = NotificationSettingsStatus.initial,
    this.settings,
    this.errorMessage,
    this.permissionStatus,
  });

  final NotificationSettingsStatus status;
  final NotificationSettingsModel? settings;
  final String? errorMessage;
  final PermissionStatus? permissionStatus;

  bool get isLoading => status == NotificationSettingsStatus.loading;
  bool get isSaving => status == NotificationSettingsStatus.saving;

  NotificationSettingsState copyWith({
    NotificationSettingsStatus? status,
    NotificationSettingsModel? settings,
    String? errorMessage,
    PermissionStatus? permissionStatus,
  }) {
    return NotificationSettingsState(
      status: status ?? this.status,
      settings: settings ?? this.settings,
      errorMessage: errorMessage,
      permissionStatus: permissionStatus ?? this.permissionStatus,
    );
  }
}

// ───────────────── Controller ─────────────────

class NotificationController extends StateNotifier<NotificationSettingsState> {
  NotificationController(this._repository)
    : super(const NotificationSettingsState());

  final NotificationRepository _repository;

  /// Load settings dari server (atau cache).
  Future<void> loadSettings() async {
    state = state.copyWith(status: NotificationSettingsStatus.loading);

    final result = await _repository.getSettings();

    if (result.isSuccess()) {
      final settings = result.dataSuccess()!;
      state = state.copyWith(
        status: NotificationSettingsStatus.loaded,
        settings: settings,
      );
    } else {
      final (message, _, _, _) = result.dataError()!;
      state = state.copyWith(
        status: NotificationSettingsStatus.error,
        errorMessage: message,
      );
    }
  }

  /// Check dan set permission status.
  Future<void> checkPermission() async {
    final status = await NotificationService.instance.isPermissionGranted();
    state = state.copyWith(
      permissionStatus: status
          ? PermissionStatus.granted
          : PermissionStatus.denied,
    );
  }

  /// Request permission.
  Future<PermissionStatus> requestPermission() async {
    final status = await NotificationService.instance.requestPermission();
    state = state.copyWith(permissionStatus: status);
    return status;
  }

  // ───────────────── Toggle methods ─────────────────

  /// Toggle daily reminder on/off.
  void toggleReminder(bool enabled) {
    final current = state.settings;
    if (current == null) return;
    state = state.copyWith(
      settings: current.copyWith(reminderEnabled: enabled),
    );
  }

  /// Set reminder time.
  void setReminderTime(TimeOfDay time) {
    final current = state.settings;
    if (current == null) return;
    state = state.copyWith(settings: current.copyWith(reminderTime: time));
  }

  /// Toggle budget alert on/off.
  void toggleBudgetAlert(bool enabled) {
    final current = state.settings;
    if (current == null) return;
    state = state.copyWith(
      settings: current.copyWith(budgetAlertEnabled: enabled),
    );
  }

  /// Toggle debt reminder on/off.
  void toggleDebtReminder(bool enabled) {
    final current = state.settings;
    if (current == null) return;
    state = state.copyWith(
      settings: current.copyWith(debtReminderEnabled: enabled),
    );
  }

  /// Set debt reminder days before.
  void setDebtReminderDaysBefore(int days) {
    final current = state.settings;
    if (current == null) return;
    state = state.copyWith(
      settings: current.copyWith(debtReminderDaysBefore: days),
    );
  }

  // ───────────────── Save ─────────────────

  /// Simpan settings ke server dan sinkronkan jadwal.
  Future<bool> saveSettings({
    required String reminderTitle,
    required String reminderBody,
  }) async {
    final current = state.settings;
    if (current == null) return false;

    state = state.copyWith(status: NotificationSettingsStatus.saving);

    final result = await _repository.saveSettings(
      current,
      reminderTitle: reminderTitle,
      reminderBody: reminderBody,
    );

    if (result.isSuccess()) {
      state = state.copyWith(
        status: NotificationSettingsStatus.loaded,
        settings: result.dataSuccess(),
      );
      return true;
    } else {
      final (message, _, _, _) = result.dataError()!;
      state = state.copyWith(
        status: NotificationSettingsStatus.error,
        errorMessage: message,
      );
      return false;
    }
  }
}
