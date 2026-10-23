import 'package:flutter/foundation.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Keeps the `timezone` package's local location in sync with the device.
class TimeZoneService {
  static var _databaseLoaded = false;

  /// Loads the time zone database and reads the device's zone.
  Future<void> initialize() async {
    if (!_databaseLoaded) {
      tz_data.initializeTimeZones();
      _databaseLoaded = true;
    }
    await refresh();
  }

  /// Re-reads the device's zone. Call it before any scheduling: the user may
  /// have travelled since the process started.
  Future<void> refresh() async {
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } on Object catch (error) {
      // Keep whatever zone we had (UTC at worst) rather than failing to
      // schedule at all.
      debugPrint('Could not read the device time zone: $error');
    }
  }
}
