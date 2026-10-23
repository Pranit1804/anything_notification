import 'package:equatable/equatable.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class PermissionSnapshot extends Equatable {
  const PermissionSnapshot({
    required this.notificationsEnabled,
    required this.exactAlarmsAllowed,
  });

  /// Android 13+ asks at runtime; the user can also switch them off in
  /// system settings.
  final bool notificationsEnabled;

  /// Without this, reminders are still delivered but may be a few minutes late.
  final bool exactAlarmsAllowed;

  @override
  List<Object> get props => [notificationsEnabled, exactAlarmsAllowed];
}

abstract interface class NotificationPermissions {
  Future<PermissionSnapshot> status();

  /// Shows the system permission dialog when it can. Returns whether
  /// notifications are enabled afterwards.
  Future<bool> requestNotifications();

  /// Opens the system screen where exact alarms can be allowed.
  Future<void> requestExactAlarms();

  /// Opens the app's notification settings (for when the dialog can no longer
  /// be shown).
  Future<void> openNotificationSettings();
}

class PluginNotificationPermissions implements NotificationPermissions {
  PluginNotificationPermissions(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  @override
  Future<PermissionSnapshot> status() async => PermissionSnapshot(
    notificationsEnabled: await _android?.areNotificationsEnabled() ?? false,
    exactAlarmsAllowed:
        await _android?.canScheduleExactNotifications() ?? false,
  );

  @override
  Future<bool> requestNotifications() async {
    await _android?.requestNotificationsPermission();
    return (await status()).notificationsEnabled;
  }

  @override
  Future<void> requestExactAlarms() async {
    await _android?.requestExactAlarmsPermission();
  }

  @override
  Future<void> openNotificationSettings() async {
    await _android?.openAppNotificationSettings();
  }
}
