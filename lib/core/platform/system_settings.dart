import 'package:flutter/services.dart';

/// Shortcuts into Android's system settings that the plugins don't provide.
abstract interface class SystemSettings {
  /// Opens the battery optimisation list, where the user can let the app run
  /// freely in the background (some phones stop apps to save power).
  Future<void> openBatterySettings();

  /// Whether alarm-style reminders may take over the screen. Android 14+ lets
  /// the user turn this off per app; before that it is always allowed.
  Future<bool> canUseFullScreenIntent();

  /// Called when an alarm has been handled: stop showing the app over the
  /// lock screen and, if the phone is still locked, go back to it.
  Future<void> finishAlarm();
}

class MethodChannelSystemSettings implements SystemSettings {
  const MethodChannelSystemSettings();

  static const _channel = MethodChannel(
    'com.bytecode.anything_notification/system',
  );

  @override
  Future<bool> canUseFullScreenIntent() async {
    try {
      return await _channel.invokeMethod<bool>('canUseFullScreenIntent') ??
          true;
    } on PlatformException {
      return true;
    }
  }

  @override
  Future<void> finishAlarm() async {
    try {
      await _channel.invokeMethod<void>('finishAlarm');
    } on PlatformException {
      // Best effort: the alarm itself is already handled.
    }
  }

  @override
  Future<void> openBatterySettings() async {
    try {
      await _channel.invokeMethod<void>('openBatterySettings');
    } on PlatformException {
      // Nothing sensible to do: the settings screen is a convenience.
    }
  }
}
