import 'package:flutter/services.dart';

/// Shortcuts into Android's system settings that the plugins don't provide.
abstract interface class SystemSettings {
  /// Opens the battery optimisation list, where the user can let the app run
  /// freely in the background (some phones stop apps to save power).
  Future<void> openBatterySettings();
}

class MethodChannelSystemSettings implements SystemSettings {
  const MethodChannelSystemSettings();

  static const _channel = MethodChannel(
    'com.bytecode.anything_notification/system',
  );

  @override
  Future<void> openBatterySettings() async {
    try {
      await _channel.invokeMethod<void>('openBatterySettings');
    } on PlatformException {
      // Nothing sensible to do: the settings screen is a convenience.
    }
  }
}
