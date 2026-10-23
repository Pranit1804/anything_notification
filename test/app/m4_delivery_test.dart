import 'package:anything_notification/core/notifications/alarm_payload.dart';
import 'package:anything_notification/core/time/naive_time.dart';
import 'package:anything_notification/features/reminders/domain/alarm_planner.dart';
import 'package:anything_notification/features/reminders/domain/reminder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_dependencies.dart';
import '../helpers/pump_app.dart';

AlarmPayload _tap(int id, DateTime occurrence) => AlarmPayload(
  reminderId: id,
  kind: AlarmKind.occurrence,
  occurrence: occurrence,
  fireAt: DateTime.utc(2026, 10, 23, 12),
  revision: 1,
  exact: true,
);

Future<Reminder> _seedWithDelivery(
  TestEnvironment env,
  DeliveryMode delivery, {
  String title = 'Take pills',
}) => env.service.create(
  ReminderDraft(
    title: title,
    note: 'With food',
    start: naive(2026, 10, 23, 12),
    delivery: delivery,
  ),
);

void main() {
  group('delivery selector in the editor', () {
    testWidgets('defaults to standard and explains each choice', (
      tester,
    ) async {
      useTallWindow(tester);
      await pumpApp(tester);
      await openEditor(tester);

      expect(find.text('How it notifies you'), findsOneWidget);
      expect(
        find.text('A normal notification you can swipe away.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Sticky'));
      await settle(tester);
      expect(
        find.text(
          'Stays in your notifications until you mark it done or snooze it.',
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Alarm'));
      await settle(tester);
      expect(
        find.text('Wakes the screen and rings until you respond.'),
        findsOneWidget,
      );
    });

    for (final delivery in [DeliveryMode.sticky, DeliveryMode.alarm]) {
      testWidgets('saves a ${delivery.name} reminder', (tester) async {
        useTallWindow(tester);
        final env = await pumpApp(tester);
        await openEditor(tester);

        await tester.enterText(find.byType(TextField).first, 'Take pills');
        await tester.tap(
          find.text(delivery == DeliveryMode.sticky ? 'Sticky' : 'Alarm'),
        );
        await settle(tester);
        await tester.tap(find.text('Save'));
        await settle(tester);

        final saved = (await tester.runAsync(env.repository.getAll))!.single;
        expect(saved.delivery, delivery);
      });
    }

    testWidgets('shows what a saved reminder uses and can change it', (
      tester,
    ) async {
      useTallWindow(tester);
      final env = await pumpApp(
        tester,
        seed: (env) => _seedWithDelivery(env, DeliveryMode.sticky),
      );

      await tester.tap(find.text('Take pills'));
      await settle(tester);
      expect(
        tester
            .widget<SegmentedButton<DeliveryMode>>(
              find.byType(SegmentedButton<DeliveryMode>),
            )
            .selected,
        {DeliveryMode.sticky},
      );

      await tester.tap(find.text('Standard'));
      await settle(tester);
      await tester.tap(find.text('Save'));
      await settle(tester);

      final saved = (await tester.runAsync(env.repository.getAll))!.single;
      expect(saved.delivery, DeliveryMode.standard);
    });

    testWidgets('alarm-style warns when full-screen alerts are not allowed', (
      tester,
    ) async {
      useTallWindow(tester);
      final permissions = FakePermissions(fullScreenIntentAllowed: false);
      await pumpApp(tester, permissions: permissions);
      await openEditor(tester);
      expect(find.text('Full-screen alarms need permission'), findsNothing);

      await tester.tap(find.text('Alarm'));
      await settle(tester);
      expect(find.text('Full-screen alarms need permission'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Allow'));
      await settle(tester);
      expect(permissions.fullScreenRequests, 1);
    });

    testWidgets('no warning when it is allowed, or for other kinds', (
      tester,
    ) async {
      useTallWindow(tester);
      await pumpApp(tester);
      await openEditor(tester);

      await tester.tap(find.text('Alarm'));
      await settle(tester);

      expect(find.text('Full-screen alarms need permission'), findsNothing);
    });
  });

  testWidgets('cards show a pin for sticky and an alarm for alarm-style', (
    tester,
  ) async {
    await pumpApp(
      tester,
      seed: (env) async {
        await _seedWithDelivery(env, DeliveryMode.sticky, title: 'Sticky one');
        await _seedWithDelivery(env, DeliveryMode.alarm, title: 'Alarm one');
        await _seedWithDelivery(env, DeliveryMode.standard, title: 'Plain');
      },
    );

    expect(find.byIcon(Icons.push_pin_rounded), findsOneWidget);
    expect(find.byIcon(Icons.alarm_on_rounded), findsOneWidget);
  });

  group('reliability', () {
    testWidgets('lists full-screen alerts with a fix when not allowed', (
      tester,
    ) async {
      useTallWindow(tester);
      final permissions = FakePermissions(fullScreenIntentAllowed: false);
      await pumpApp(tester, permissions: permissions);
      await tester.tap(navLabel('Settings'));
      await settle(tester);

      expect(find.text('Full-screen alerts'), findsOneWidget);
      expect(find.text('Not allowed'), findsOneWidget);

      await tester.tap(find.text('Fix'));
      await settle(tester);
      expect(permissions.fullScreenRequests, 1);
    });

    testWidgets('mentions that sticky can be swiped away on Android 14+', (
      tester,
    ) async {
      useTallWindow(tester);
      await pumpApp(tester);
      await tester.tap(navLabel('Settings'));
      await settle(tester);

      await tester.tap(find.text("Reminder didn't show up?"));
      await settle(tester);

      expect(find.textContaining('sticky notification away'), findsOneWidget);
    });
  });

  group('tapping a notification', () {
    testWidgets('a standard reminder opens the editor', (tester) async {
      useTallWindow(tester);
      late Reminder reminder;
      final env = await pumpApp(
        tester,
        seed: (env) async =>
            reminder = await _seedWithDelivery(env, DeliveryMode.standard),
      );

      env.notificationTaps.add(_tap(reminder.id, reminder.start));
      await settle(tester);

      expect(find.text('Edit reminder'), findsOneWidget);
    });

    testWidgets('an alarm-style reminder opens the full-screen alarm', (
      tester,
    ) async {
      late Reminder reminder;
      final env = await pumpApp(
        tester,
        seed: (env) async =>
            reminder = await _seedWithDelivery(env, DeliveryMode.alarm),
      );

      env.notificationTaps.add(_tap(reminder.id, reminder.start));
      await settle(tester);

      expect(find.text('Take pills'), findsWidgets);
      expect(find.text('With food'), findsOneWidget);
      expect(find.text('Due 12:00 PM'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);
      expect(find.text('Snooze 10 min'), findsOneWidget);
      expect(find.text('Edit reminder'), findsNothing);
    });

    testWidgets('a paused alarm reminder opens the editor instead', (
      tester,
    ) async {
      useTallWindow(tester);
      late Reminder reminder;
      final env = await pumpApp(
        tester,
        seed: (env) async {
          reminder = await _seedWithDelivery(env, DeliveryMode.alarm);
          await env.service.setPaused(reminder, paused: true);
        },
      );

      env.notificationTaps.add(_tap(reminder.id, reminder.start));
      await settle(tester);

      expect(find.text('Edit reminder'), findsOneWidget);
    });

    testWidgets('a reminder that no longer exists opens nothing', (
      tester,
    ) async {
      final env = await pumpApp(tester);

      env.notificationTaps.add(_tap(999, naive(2026, 10, 23, 12)));
      await settle(tester);

      expect(find.text('Edit reminder'), findsNothing);
      expect(find.text('Nothing coming up'), findsOneWidget);
    });
  });

  group('alarm screen', () {
    Future<(TestEnvironment, Reminder)> ring(WidgetTester tester) async {
      late Reminder reminder;
      final env = await pumpApp(
        tester,
        seed: (env) async =>
            reminder = await _seedWithDelivery(env, DeliveryMode.alarm),
      );
      env.notificationTaps.add(_tap(reminder.id, reminder.start));
      await settle(tester);
      return (env, reminder);
    }

    testWidgets('Done completes the reminder and leaves the alarm', (
      tester,
    ) async {
      final (env, reminder) = await ring(tester);

      await tester.tap(find.text('Done'));
      await settle(tester);

      final saved = (await tester.runAsync(
        () => env.repository.getById(reminder.id),
      ))!;
      expect(saved.status, ReminderStatus.completed);
      expect(env.systemSettings.alarmsFinished, 1);
      expect(find.text('Done'), findsNothing); // back on the list
      expect(env.scheduler.dismissed, [(reminder.id, reminder.start)]);
    });

    testWidgets('Snooze uses the snooze setting and leaves the alarm', (
      tester,
    ) async {
      final (env, reminder) = await ring(tester);

      await tester.tap(find.text('Snooze 10 min'));
      await settle(tester);

      final saved = (await tester.runAsync(
        () => env.repository.getById(reminder.id),
      ))!;
      expect(saved.snoozedUntil, testNow.add(const Duration(minutes: 10)));
      expect(saved.status, ReminderStatus.active);
      expect(env.systemSettings.alarmsFinished, 1);
      expect(find.text('Snooze 10 min'), findsNothing);
    });

    testWidgets('the snooze button follows the setting', (tester) async {
      late Reminder reminder;
      final env = await pumpApp(
        tester,
        prefs: {'settings.snooze_minutes': 30},
        seed: (env) async =>
            reminder = await _seedWithDelivery(env, DeliveryMode.alarm),
      );
      env.notificationTaps.add(_tap(reminder.id, reminder.start));
      await settle(tester);

      expect(find.text('Snooze 30 min'), findsOneWidget);
    });

    testWidgets('a tap for an already finished reminder opens nothing', (
      tester,
    ) async {
      late Reminder reminder;
      final env = await pumpApp(
        tester,
        seed: (env) async {
          reminder = await _seedWithDelivery(env, DeliveryMode.alarm);
          await env.service.markDone(reminder.id, reminder.start);
        },
      );

      env.notificationTaps.add(_tap(reminder.id, reminder.start));
      await settle(tester);

      expect(find.text('Snooze 10 min'), findsNothing);
      expect(find.text('Nothing coming up'), findsOneWidget);
    });
  });
}
