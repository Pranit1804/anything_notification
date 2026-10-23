import 'package:equatable/equatable.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../platform/system_settings.dart';

class PermissionSnapshot extends Equatable {
  const PermissionSnapshot({
    required this.notificationsEnabled,
    required this.exactAlarmsAllowed,
    this.fullScreenIntentAllowed = true,
  });

  /// Android 13+ asks at runtime; the user can also switch them off in
  /// system settings.
  final bool notificationsEnabled;

  /// Without this, reminders are still delivered but may be a few minutes late.
  final bool exactAlarmsAllowed;

  /// Without this, alarm-style reminders still ring but show as an ordinary
  /// heads-up instead of taking over the screen.
  final bool fullScreenIntentAllowed;

  @override
  List<Object> get props => [
    notificationsEnabled,
    exactAlarmsAllowed,
    fullScreenIntentAllowed,
  ];
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

  /// Opens the system screen where full-screen alerts can be allowed.
  Future<void> requestFullScreenIntent();
}

class PluginNotificationPermissions implements NotificationPermissions {
  PluginNotificationPermissions(this._plugin, this._system);

  final FlutterLocalNotificationsPlugin _plugin;
  final SystemSettings _system;

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  @override
  Future<PermissionSnapshot> status() async => PermissionSnapshot(
    notificationsEnabled: await _android?.areNotificationsEnabled() ?? false,
    exactAlarmsAllowed:
        await _android?.canScheduleExactNotifications() ?? false,
    fullScreenIntentAllowed: await _system.canUseFullScreenIntent(),
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

  @override
  Future<void> requestFullScreenIntent() async {
    await _android?.requestFullScreenIntentPermission();
  }
}
