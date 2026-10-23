import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../features/categories/data/category_repository.dart';
import '../../features/reminders/data/reminder_repository.dart';
import '../../features/reminders/domain/alarm_planner.dart';
import '../../features/settings/domain/reminder_preferences.dart';
import '../time/time_zone_service.dart';
import '../time/zoned_clock.dart';
import 'alarm_payload.dart';
import 'notification_content.dart';

/// Keeps the notifications armed with Android in step with the reminders in
/// the database.
abstract interface class AlarmScheduler {
  /// Arms what should be armed and disarms what should not.
  ///
  /// Normally only differences are applied. [rearmAll] re-arms everything
  /// (idempotent): use it after anything that can silently clear alarms, such
  /// as a reboot, a force stop, or a time or time zone change.
  Future<void> reconcile({bool rearmAll = false});

  /// Removes the notification already showing for an occurrence (and its
  /// snooze), e.g. when it was marked done inside the app.
  Future<void> dismissShown(int reminderId, DateTime occurrence);
}

class NotificationAlarmScheduler implements AlarmScheduler {
  NotificationAlarmScheduler({
    required this._plugin,
    required this._repository,
    required this._categories,
    required this._preferences,
    required this._clock,
    this._timeZones,
    this._planner = const AlarmPlanner(),
  });

  final FlutterLocalNotificationsPlugin _plugin;
  final ReminderRepository _repository;
  final CategoryRepository _categories;
  final ReminderPreferences _preferences;
  final ZonedClock _clock;
  final TimeZoneService? _timeZones;
  final AlarmPlanner _planner;

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  @override
  Future<void> reconcile({bool rearmAll = false}) async {
    await _timeZones?.refresh();

    final reminders = await _repository.getAll();
    final categories = {
      for (final category in await _categories.getAll()) category.id: category,
    };
    final planned = _planner.plan(reminders, _clock, categories: categories);
    final exact = await _android?.canScheduleExactNotifications() ?? false;
    final snoozeMinutes = _preferences.snoozeMinutes;

    final desired = {
      for (final alarm in planned)
        alarm.id: AlarmPayload.fromAlarm(
          alarm,
          exact: exact,
          snoozeMinutes: snoozeMinutes,
        ).encode(),
    };
    final armed = {
      for (final request in await _plugin.pendingNotificationRequests())
        request.id: request.payload,
    };

    for (final id in armed.keys) {
      if (id == testNotificationId) continue;
      if (!desired.containsKey(id)) await _plugin.cancel(id: id);
    }

    for (final alarm in planned) {
      final payload = desired[alarm.id]!;
      if (!rearmAll && armed[alarm.id] == payload) continue;
      try {
        await _plugin.zonedSchedule(
          id: alarm.id,
          title: alarm.title,
          body: alarm.body,
          scheduledDate: tz.TZDateTime.from(alarm.fireAt, tz.local),
          notificationDetails: notificationDetailsFor(
            alarm,
            snoozeMinutes: snoozeMinutes,
          ),
          androidScheduleMode: exact
              ? AndroidScheduleMode.exactAllowWhileIdle
              : AndroidScheduleMode.inexactAllowWhileIdle,
          payload: payload,
        );
      } on Object catch (error) {
        // One bad alarm must not stop the others from being armed.
        debugPrint('Could not arm alarm ${alarm.id}: $error');
      }
    }
  }

  @override
  Future<void> dismissShown(int reminderId, DateTime occurrence) async {
    for (final kind in AlarmKind.values) {
      await _plugin.cancel(
        id: AlarmPlanner.notificationId(reminderId, kind, occurrence),
      );
    }
  }
}
