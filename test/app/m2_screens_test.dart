import 'package:anything_notification/core/time/naive_time.dart';
import 'package:anything_notification/features/reminders/domain/occurrence_outcome.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_dependencies.dart';
import '../helpers/pump_app.dart';

Future<void> _openSettings(WidgetTester tester) async {
  useTallWindow(tester); // Settings is a long list.
  await tester.tap(navLabel('Settings'));
  await settle(tester);
}

Future<void> _openCategories(WidgetTester tester) async {
  await _openSettings(tester);
  await tester.tap(find.text('Categories'));
  await settle(tester);
}

void main() {
  group('categories', () {
    testWidgets('are listed with the defaults', (tester) async {
      await pumpApp(tester);
      await _openCategories(tester);

      for (final name in ['Personal', 'Work', 'Health', 'Bills']) {
        expect(find.text(name), findsOneWidget);
      }
    });

    testWidgets('can be created', (tester) async {
      final env = await pumpApp(tester);
      await _openCategories(tester);

      await tester.tap(find.text('New category'));
      await settle(tester);
      await tester.enterText(find.byType(TextField), 'Garden');
      await tester.tap(find.text('Save'));
      await settle(tester);

      expect(find.text('Garden'), findsOneWidget);
      final all = await tester.runAsync(env.categories.getAll);
      expect(all!.last.name, 'Garden');
    });

    testWidgets('need a name', (tester) async {
      final env = await pumpApp(tester);
      await _openCategories(tester);

      await tester.tap(find.text('New category'));
      await settle(tester);
      await tester.tap(find.text('Save'));
      await settle(tester);

      expect(find.text('Give your category a name'), findsOneWidget);
      expect((await tester.runAsync(env.categories.getAll))!, hasLength(4));
    });

    testWidgets('can be renamed', (tester) async {
      final env = await pumpApp(tester);
      await _openCategories(tester);

      await tester.tap(find.text('Work'));
      await settle(tester);
      await tester.enterText(find.byType(TextField), 'Office');
      await tester.tap(find.text('Save'));
      await settle(tester);

      expect(find.text('Office'), findsOneWidget);
      expect(find.text('Work'), findsNothing);
      final all = await tester.runAsync(env.categories.getAll);
      expect(all![1].name, 'Office');
    });

    testWidgets('can be deleted after confirming, and its reminders keep '
        'existing without a category', (tester) async {
      useTallWindow(tester);
      late int workId;
      final env = await pumpApp(
        tester,
        seed: (env) async {
          workId = (await env.categories.getAll())[1].id;
          await seedReminder(env, title: 'Standup', categoryId: workId);
        },
      );
      await _openCategories(tester);

      await tester.tap(find.text('Work'));
      await settle(tester);
      await tester.tap(find.text('Delete category'));
      await settle(tester);
      expect(find.text('Delete "Work"?'), findsOneWidget);
      await tester.tap(find.text('Delete'));
      await settle(tester);

      expect(find.text('Work'), findsNothing);
      final reminder = (await tester.runAsync(env.repository.getAll))!.single;
      expect(reminder.title, 'Standup');
      expect(reminder.categoryId, isNull);
    });

    testWidgets('can be cancelled out of deleting', (tester) async {
      useTallWindow(tester);
      await pumpApp(tester);
      await _openCategories(tester);

      await tester.tap(find.text('Work'));
      await settle(tester);
      await tester.tap(find.text('Delete category'));
      await settle(tester);
      await tester.tap(find.text('Cancel'));
      await settle(tester);

      expect(find.text('Work'), findsWidgets);
    });
  });

  group('categories in the editor and the list', () {
    testWidgets('a reminder can be given a category', (tester) async {
      useTallWindow(tester);
      final env = await pumpApp(tester);

      await openEditor(tester);
      await tester.enterText(find.byType(TextField).first, 'Standup');
      await tester.tap(find.widgetWithText(ChoiceChip, 'Work'));
      await settle(tester);
      await tester.tap(find.text('Save'));
      await settle(tester);

      final workId = (await tester.runAsync(env.categories.getAll))![1].id;
      final saved = (await tester.runAsync(env.repository.getAll))!.single;
      expect(saved.categoryId, workId);
    });

    testWidgets('a new category can be made on the spot and is picked', (
      tester,
    ) async {
      useTallWindow(tester);
      final env = await pumpApp(tester);

      await openEditor(tester);
      await tester.enterText(find.byType(TextField).first, 'Mow lawn');
      await tester.tap(find.widgetWithText(ActionChip, 'New'));
      await settle(tester);
      await tester.enterText(find.byType(TextField).last, 'Garden');
      await tester.tap(find.text('Save').last);
      await settle(tester);

      expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Garden'))
            .selected,
        isTrue,
      );
      await tester.tap(find.text('Save').first);
      await settle(tester);

      final garden = (await tester.runAsync(env.categories.getAll))!.last;
      final saved = (await tester.runAsync(env.repository.getAll))!.single;
      expect(garden.name, 'Garden');
      expect(saved.categoryId, garden.id);
    });

    testWidgets('filter chips narrow Upcoming to one category', (tester) async {
      await pumpApp(
        tester,
        seed: (env) async {
          final all = await env.categories.getAll();
          await seedReminder(env, title: 'Standup', categoryId: all[1].id);
          await seedReminder(env, title: 'Gym', categoryId: all[2].id);
          await seedReminder(env, title: 'Loose end');
        },
      );
      expect(find.text('Standup'), findsOneWidget);
      expect(find.text('Gym'), findsOneWidget);
      expect(find.text('Loose end'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilterChip, 'Work'));
      await settle(tester);
      expect(find.text('Standup'), findsOneWidget);
      expect(find.text('Gym'), findsNothing);
      expect(find.text('Loose end'), findsNothing);

      await tester.tap(find.widgetWithText(FilterChip, 'All'));
      await settle(tester);
      expect(find.text('Gym'), findsOneWidget);
      expect(find.text('Loose end'), findsOneWidget);
    });

    testWidgets('an empty filter says so', (tester) async {
      await pumpApp(
        tester,
        seed: (env) async {
          final all = await env.categories.getAll();
          await seedReminder(env, title: 'Standup', categoryId: all[1].id);
        },
      );

      await tester.tap(find.widgetWithText(FilterChip, 'Bills'));
      await settle(tester);

      expect(find.text('Nothing in Bills'), findsOneWidget);
      expect(find.text('Standup'), findsNothing);
    });

    testWidgets('no filter chips before there is anything to filter', (
      tester,
    ) async {
      await pumpApp(tester);

      expect(find.byType(FilterChip), findsNothing);
    });
  });

  group('history', () {
    Future<void> seedHistory(TestEnvironment env) async {
      await env.history.log(
        reminderId: 1,
        title: 'Pay rent',
        scheduledLocal: naive(2026, 10, 23, 9),
        outcome: OccurrenceOutcome.done,
        at: testNow,
        categoryId: 4,
        categoryName: 'Bills',
        categoryColor: 0xFFE8590C,
      );
      await env.history.log(
        reminderId: 2,
        title: 'Water plants',
        scheduledLocal: naive(2026, 10, 22, 9),
        outcome: OccurrenceOutcome.missed,
        at: testNow.subtract(const Duration(days: 1)),
      );
      await env.history.log(
        reminderId: 3,
        title: 'Call mom',
        scheduledLocal: naive(2026, 10, 20, 9),
        outcome: OccurrenceOutcome.snoozed,
        at: testNow.subtract(const Duration(days: 3)),
      );
    }

    Future<void> openHistory(WidgetTester tester) async {
      useTallWindow(tester);
      await tester.tap(navLabel('History'));
      await settle(tester);
    }

    testWidgets('is empty at first', (tester) async {
      await pumpApp(tester);
      await openHistory(tester);

      expect(find.text('No history yet'), findsOneWidget);
    });

    testWidgets('lists entries by day with what happened', (tester) async {
      await pumpApp(tester, seed: seedHistory);
      await openHistory(tester);

      expect(find.text('Pay rent'), findsOneWidget);
      expect(find.text('Done · due 9:00 AM'), findsOneWidget);
      expect(find.text('Missed · due 9:00 AM'), findsOneWidget);
      expect(find.text('Snoozed · due 9:00 AM'), findsOneWidget);
      expect(find.text('Yesterday'), findsOneWidget);
      expect(find.text('Bills'), findsWidgets);
    });

    testWidgets('summarises what was done in the last 7 days', (tester) async {
      await pumpApp(tester, seed: seedHistory);
      await openHistory(tester);

      expect(find.text('1 done in the last 7 days'), findsOneWidget);
    });

    testWidgets('can be filtered by outcome', (tester) async {
      await pumpApp(tester, seed: seedHistory);
      await openHistory(tester);

      await tester.tap(find.widgetWithText(FilterChip, 'Missed'));
      await settle(tester);

      expect(find.text('Water plants'), findsOneWidget);
      expect(find.text('Pay rent'), findsNothing);
      expect(find.text('Call mom'), findsNothing);
    });

    testWidgets('can be filtered by category', (tester) async {
      await pumpApp(tester, seed: seedHistory);
      await openHistory(tester);

      // "Bills" appears as a filter chip and as a tag on the entry.
      await tester.tap(find.widgetWithText(FilterChip, 'Bills'));
      await settle(tester);

      expect(find.text('Pay rent'), findsOneWidget);
      expect(find.text('Water plants'), findsNothing);
    });

    testWidgets('says so when the filters match nothing', (tester) async {
      await pumpApp(tester, seed: seedHistory);
      await openHistory(tester);

      await tester.tap(find.widgetWithText(FilterChip, 'Snoozed'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilterChip, 'Bills'));
      await settle(tester);

      expect(find.text('Nothing matches these filters'), findsOneWidget);
    });

    testWidgets('can be cleared from the menu, after confirming', (
      tester,
    ) async {
      final env = await pumpApp(tester, seed: seedHistory);
      await openHistory(tester);

      await tester.tap(find.byType(PopupMenuButton<void>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Clear history'));
      await settle(tester);
      expect(find.text('Clear all history?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Clear history'));
      await settle(tester);

      expect(find.text('No history yet'), findsOneWidget);
      expect(find.text('History cleared'), findsOneWidget);
      final left = await tester.runAsync(() => env.history.watchAll().first);
      expect(left, isEmpty);
    });
  });

  group('settings', () {
    testWidgets('snooze length can be changed and re-arms notifications', (
      tester,
    ) async {
      useTallWindow(tester);
      final env = await pumpApp(tester);
      await _openSettings(tester);
      final before = env.scheduler.reconciles;
      expect(find.text('10 minutes'), findsOneWidget);

      await tester.tap(find.text('Snooze for'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('30 minutes'));
      await settle(tester);

      expect(find.text('30 minutes'), findsOneWidget);
      expect(env.settings.snoozeMinutes, 30);
      // Notifications showing "Snooze 10m" must be re-armed with the new label.
      expect(env.scheduler.reconciles, greaterThan(before));
    });

    testWidgets('history retention can be changed', (tester) async {
      useTallWindow(tester);
      final env = await pumpApp(tester);
      await _openSettings(tester);
      expect(find.text('90 days'), findsOneWidget);

      await tester.tap(find.text('Keep history for'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Forever'));
      await settle(tester);

      expect(find.text('Forever'), findsOneWidget);
      expect(env.settings.historyRetentionDays, 0);
    });

    testWidgets('history can be cleared from settings', (tester) async {
      useTallWindow(tester);
      final env = await pumpApp(
        tester,
        seed: (env) => env.history.log(
          reminderId: 1,
          title: 'Old',
          scheduledLocal: naive(2026, 10, 1, 9),
          outcome: OccurrenceOutcome.done,
          at: testNow,
        ),
      );
      await _openSettings(tester);

      await tester.tap(find.widgetWithText(ListTile, 'Clear history'));
      await settle(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Clear history'));
      await settle(tester);

      expect(find.text('History cleared'), findsOneWidget);
      expect(
        await tester.runAsync(() => env.history.watchAll().first),
        isEmpty,
      );
    });

    testWidgets('reliability shows everything is fine when it is', (
      tester,
    ) async {
      useTallWindow(tester);
      await pumpApp(tester);
      await _openSettings(tester);

      expect(find.text('On'), findsOneWidget);
      expect(find.text('Allowed'), findsNWidgets(2)); // exact + full-screen
      expect(find.text('Fix'), findsNothing);
    });

    testWidgets('reliability offers a fix for each thing that is off', (
      tester,
    ) async {
      useTallWindow(tester);
      final permissions = FakePermissions(
        notificationsEnabled: false,
        exactAlarmsAllowed: false,
      );
      await pumpApp(tester, permissions: permissions);
      await _openSettings(tester);

      expect(find.text('Off'), findsOneWidget);
      expect(find.text('Not allowed'), findsOneWidget);
      expect(find.text('Fix'), findsNWidgets(2));

      await tester.tap(find.text('Fix').last);
      await settle(tester);
      expect(permissions.exactAlarmRequests, 1);

      await tester.tap(find.text('Fix').first);
      await settle(tester);
      // The dialog cannot be shown any more (it is a fake that stays denied),
      // so the app's notification settings open instead.
      expect(permissions.settingsOpened, 1);
    });

    testWidgets('sends a test notification', (tester) async {
      useTallWindow(tester);
      final env = await pumpApp(tester);
      await _openSettings(tester);

      await tester.tap(find.text('Send test notification'));
      await settle(tester);

      expect(env.testNotifications.sent, 1);
      expect(
        find.text('Sent. It should appear in about 10 seconds.'),
        findsOneWidget,
      );
    });

    testWidgets('the guide explains why reminders go missing and opens '
        'battery settings', (tester) async {
      useTallWindow(tester);
      final env = await pumpApp(tester);
      await _openSettings(tester);

      await tester.tap(find.text("Reminder didn't show up?"));
      await settle(tester);
      expect(find.textContaining('Force-stopping the app'), findsOneWidget);

      await tester.tap(find.text('Open battery settings'));
      await settle(tester);
      expect(env.systemSettings.batterySettingsOpened, 1);
    });
  });
}
