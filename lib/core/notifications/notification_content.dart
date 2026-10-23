import 'dart:ui';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../features/reminders/domain/alarm_planner.dart';
import '../../features/reminders/domain/reminder.dart';

/// Drawable (res/drawable/ic_stat_reminder.xml) used as the status-bar icon.
const notificationSmallIcon = 'ic_stat_reminder';

const actionDone = 'done';
const actionSnooze = 'snooze';

/// Reserved id for the "send test notification" button. `reconcile` leaves it
/// alone; planned alarms use ids from a hash and are told apart by payload.
const testNotificationId = 0x7fffff00;

abstract final class NotificationChannels {
  static const reminders = AndroidNotificationChannel(
    'reminders',
    'Reminders',
    description: 'Notifications for your reminders',
    importance: Importance.high,
  );
}

/// How a planned alarm is shown.
NotificationDetails notificationDetailsFor(
  PlannedAlarm alarm, {
  required int snoozeMinutes,
}) {
  final sticky = alarm.delivery == DeliveryMode.sticky;
  final categoryColor = alarm.categoryColor;

  return NotificationDetails(
    android: AndroidNotificationDetails(
      NotificationChannels.reminders.id,
      NotificationChannels.reminders.name,
      channelDescription: NotificationChannels.reminders.description,
      importance: Importance.high,
      priority: Priority.high,
      icon: notificationSmallIcon,
      category: AndroidNotificationCategory.reminder,
      subText: alarm.categoryName,
      color: categoryColor == null ? null : Color(categoryColor),
      ongoing: sticky,
      autoCancel: !sticky,
      actions: [
        const AndroidNotificationAction(actionDone, 'Done'),
        AndroidNotificationAction(actionSnooze, 'Snooze ${snoozeMinutes}m'),
      ],
    ),
  );
}
