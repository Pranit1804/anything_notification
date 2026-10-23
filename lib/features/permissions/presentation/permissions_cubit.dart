import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/notifications/notification_permissions.dart';
import '../../settings/data/settings_repository.dart';

/// What the app is currently allowed to do, refreshed whenever the app comes
/// back to the foreground (the user may have changed system settings).
/// The state is null until first read.
class PermissionsCubit extends Cubit<PermissionSnapshot?> {
  PermissionsCubit(this._permissions, this._settings) : super(null);

  final NotificationPermissions _permissions;
  final SettingsRepository _settings;

  Future<void> refresh() async {
    final snapshot = await _permissions.status();
    if (!isClosed) emit(snapshot);
  }

  /// Asks for the notification permission if it is missing (the system dialog
  /// appears at most a couple of times). Returns whether it is granted.
  Future<bool> ensureNotifications() async {
    var snapshot = state ?? await _permissions.status();
    if (!snapshot.notificationsEnabled) {
      await _permissions.requestNotifications();
      snapshot = await _permissions.status();
    }
    if (!isClosed) emit(snapshot);
    return snapshot.notificationsEnabled;
  }

  /// For the banner button: the permission dialog if the system will still
  /// show it, otherwise the app's notification settings.
  Future<void> turnOnNotifications() async {
    if (!await ensureNotifications()) {
      await _permissions.openNotificationSettings();
    }
  }

  /// True once, the first time a reminder is saved while exact alarms are not
  /// allowed: the moment to explain why they are worth allowing.
  Future<bool> shouldExplainExactAlarms() async {
    final snapshot = state ?? await _permissions.status();
    if (snapshot.exactAlarmsAllowed || _settings.exactAlarmPromptShown) {
      return false;
    }
    await _settings.markExactAlarmPromptShown();
    return true;
  }

  Future<void> requestExactAlarms() => _permissions.requestExactAlarms();

  Future<void> openNotificationSettings() =>
      _permissions.openNotificationSettings();
}
