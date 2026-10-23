import 'package:anything_notification/core/notifications/notification_content.dart';
import 'package:anything_notification/core/time/naive_time.dart';
import 'package:anything_notification/features/reminders/domain/alarm_planner.dart';
import 'package:anything_notification/features/reminders/domain/reminder.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

PlannedAlarm _alarm(DeliveryMode delivery, {String? category}) => PlannedAlarm(
  id: 1,
  reminderId: 1,
  kind: AlarmKind.occurrence,
  occurrence: naive(2026, 10, 24, 9),
  fireAt: DateTime.utc(2026, 10, 24, 9),
  title: 'Take pills',
  body: null,
  delivery: delivery,
  revision: 1,
  categoryName: category,
  categoryColor: category == null ? null : 0xFFD6336C,
);

AndroidNotificationDetails _details(PlannedAlarm alarm, {int snooze = 10}) =>
    notificationDetailsFor(alarm, snoozeMinutes: snooze).android!;

void main() {
  group('standard', () {
    final d = _details(_alarm(DeliveryMode.standard));

    test('is a normal, dismissible notification on the reminders channel', () {
      expect(d.channelId, 'reminders');
      expect(d.ongoing, isFalse);
      expect(d.autoCancel, isTrue);
      expect(d.fullScreenIntent, isFalse);
      expect(d.additionalFlags, isNull);
      expect(d.category, AndroidNotificationCategory.reminder);
    });
  });

  group('sticky', () {
    final d = _details(_alarm(DeliveryMode.sticky));

    test('stays until handled but is otherwise normal', () {
      expect(d.channelId, 'reminders');
      expect(d.ongoing, isTrue);
      expect(d.autoCancel, isFalse);
      expect(d.fullScreenIntent, isFalse);
      expect(d.additionalFlags, isNull);
    });
  });

  group('alarm', () {
    final d = _details(_alarm(DeliveryMode.alarm));

    test('uses the loud alarm channel and stays until handled', () {
      expect(d.channelId, 'alarms');
      expect(d.importance, Importance.max);
      expect(d.priority, Priority.max);
      expect(d.ongoing, isTrue);
      expect(d.autoCancel, isFalse);
      expect(d.category, AndroidNotificationCategory.alarm);
    });

    test('asks for a full-screen takeover on the alarm audio stream', () {
      expect(d.fullScreenIntent, isTrue);
      expect(d.audioAttributesUsage, AudioAttributesUsage.alarm);
    });

    test('keeps ringing until acted on (insistent flag)', () {
      expect(d.additionalFlags, isNotNull);
      expect(d.additionalFlags!.toList(), [4]);
    });
  });

  test('every kind has Done and a Snooze button using the setting', () {
    for (final delivery in DeliveryMode.values) {
      final actions = _details(_alarm(delivery), snooze: 15).actions!;

      expect(actions.map((a) => a.id), [actionDone, actionSnooze]);
      expect(actions.last.title, 'Snooze 15m');
    }
  });

  test('the category name and color are carried for every kind', () {
    for (final delivery in DeliveryMode.values) {
      final d = _details(_alarm(delivery, category: 'Health'));

      expect(d.subText, 'Health');
      expect(d.color, isNotNull);
    }
  });

  group('channels', () {
    test('the alarm channel is loud, on the alarm stream, and vibrates', () {
      const c = NotificationChannels.alarms;

      expect(c.id, 'alarms');
      expect(c.importance, Importance.max);
      expect(c.audioAttributesUsage, AudioAttributesUsage.alarm);
      expect(c.enableVibration, isTrue);
      expect(c.sound, isNotNull);
    });

    test('both channels are created at startup and have distinct ids', () {
      expect(NotificationChannels.all, hasLength(2));
      expect(NotificationChannels.all.map((c) => c.id).toSet(), {
        'reminders',
        'alarms',
      });
    });
  });
}
