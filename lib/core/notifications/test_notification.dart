import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../time/zoned_clock.dart';
import 'notification_content.dart';

/// Sends a notification a few seconds from now, so the user can check that
/// reminders reach them (lock the phone, wait, see it appear).
abstract interface class TestNotificationSender {
  Future<void> send({Duration delay = const Duration(seconds: 10)});
}

class PluginTestNotificationSender implements TestNotificationSender {
  PluginTestNotificationSender(this._plugin, this._clock);

  final FlutterLocalNotificationsPlugin _plugin;
  final ZonedClock _clock;

  @override
  Future<void> send({Duration delay = const Duration(seconds: 10)}) async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    // The same delivery path as a real reminder, so a late test shows what a
    // late reminder would look like.
    final exact = await android?.canScheduleExactNotifications() ?? false;

    await _plugin.zonedSchedule(
      id: testNotificationId,
      title: 'Test notification',
      body: 'If you can see this, your reminders can reach you.',
      scheduledDate: tz.TZDateTime.from(_clock.nowInstant.add(delay), tz.local),
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          NotificationChannels.reminders.id,
          NotificationChannels.reminders.name,
          channelDescription: NotificationChannels.reminders.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: notificationSmallIcon,
        ),
      ),
      androidScheduleMode: exact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }
}
