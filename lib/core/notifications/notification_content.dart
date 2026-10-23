import 'dart:typed_data';
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

  /// Alarm-style reminders: loud, on the alarm volume, ringing until the user
  /// responds. A channel's sound and importance cannot change once created,
  /// hence a channel of its own.
  static const alarms = AndroidNotificationChannel(
    'alarms',
    'Alarms',
    description: 'Reminders that ring until you respond',
    importance: Importance.max,
    audioAttributesUsage: AudioAttributesUsage.alarm,
    sound: UriAndroidNotificationSound('content://settings/system/alarm_alert'),
    enableVibration: true,
  );

  static const all = [reminders, alarms];
}

/// Android's FLAG_INSISTENT: repeat the sound until the notification is
/// dismissed or acted on.
const _flagInsistent = 4;

/// How a planned alarm is shown.
NotificationDetails notificationDetailsFor(
  PlannedAlarm alarm, {
  required int snoozeMinutes,
}) {
  final categoryColor = alarm.categoryColor;
  final isAlarm = alarm.delivery == DeliveryMode.alarm;
  // Sticky and alarm notifications stay until the user responds.
  final stays = alarm.delivery != DeliveryMode.standard;
  final channel = isAlarm
      ? NotificationChannels.alarms
      : NotificationChannels.reminders;

  return NotificationDetails(
    android: AndroidNotificationDetails(
      channel.id,
      channel.name,
      channelDescription: channel.description,
      importance: isAlarm ? Importance.max : Importance.high,
      priority: isAlarm ? Priority.max : Priority.high,
      icon: notificationSmallIcon,
      category: isAlarm
          ? AndroidNotificationCategory.alarm
          : AndroidNotificationCategory.reminder,
      subText: alarm.categoryName,
      color: categoryColor == null ? null : Color(categoryColor),
      ongoing: stays,
      autoCancel: !stays,
      // Alarm-style: wake the screen over the lock screen and keep ringing.
      // Without the full-screen permission Android shows it as a heads-up.
      fullScreenIntent: isAlarm,
      audioAttributesUsage: isAlarm
          ? AudioAttributesUsage.alarm
          : AudioAttributesUsage.notification,
      additionalFlags: isAlarm ? Int32List.fromList([_flagInsistent]) : null,
      actions: [
        const AndroidNotificationAction(actionDone, 'Done'),
        AndroidNotificationAction(actionSnooze, 'Snooze ${snoozeMinutes}m'),
      ],
    ),
  );
}
