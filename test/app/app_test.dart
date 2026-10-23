import 'package:anything_notification/app/app.dart';
import 'package:anything_notification/core/time/naive_time.dart';
import 'package:anything_notification/features/reminders/domain/recurrence_rule.dart';
import 'package:anything_notification/features/reminders/domain/reminder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

import '../helpers/fake_dependencies.dart';
import '../helpers/pump_app.dart' show openEditor;

Future<TestEnvironment> _pumpApp(
  WidgetTester tester, {
  Map<String, Object> prefs = const {},
  FakePermissions? permissions,
  Future<void> Function(TestEnvironment env)? seed,
}) async {
  final env = (await tester.runAsync(
    () => TestEnvironment.create(prefs: prefs, permissions: permissions),
  ))!;
  if (seed != null) await tester.runAsync(() => seed(env));
  addTearDown(() async {
    // Unmount first so cubits stop listening before the database closes.
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(env.dispose);
  });

  await tester.pumpWidget(App(dependencies: env.dependencies));
  await _settle(tester);
  return env;
}

/// Lets database streams and animations finish. Drift runs on real async, so
/// it needs `runAsync` in between frames.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
  }
}

Finder _navLabel(String label) =>
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label));

ThemeMode _themeMode(WidgetTester tester) =>
    tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode!;

Future<void> _seedReminder(
  TestEnvironment env, {
  String title = 'Water plants',
  DateTime? start,
  RecurrenceRule? recurrence,
}) async {
  await env.service.create(
    ReminderDraft(
      title: title,
      start: start ?? naive(2026, 10, 23, 18),
      recurrence: recurrence,
    ),
  );
}

void main() {
  group('shell', () {
    testWidgets('opens on Upcoming with its empty state and primary action', (
      tester,
    ) async {
      await _pumpApp(tester);

      expect(find.text('Nothing coming up'), findsOneWidget);
      expect(find.text('New reminder'), findsOneWidget);
      expect(_navLabel('Upcoming'), findsOneWidget);
    });

    testWidgets("titles Upcoming with today's date", (tester) async {
      await _pumpApp(tester);

      final today = DateFormat('EEE d MMM').format(DateTime.now());
      // SliverAppBar.large lays the title out twice (expanded + collapsed).
      expect(find.text('Today, $today'), findsWidgets);
    });

    testWidgets('switches between the three tabs', (tester) async {
      await _pumpApp(tester);

      await tester.tap(_navLabel('History'));
      await tester.pumpAndSettle();
      expect(find.text('No history yet'), findsOneWidget);

      await tester.tap(_navLabel('Settings'));
      await tester.pumpAndSettle();
      expect(find.text('Appearance'), findsOneWidget);

      await tester.tap(_navLabel('Upcoming'));
      await tester.pumpAndSettle();
      expect(find.text('Nothing coming up'), findsOneWidget);
    });

    testWidgets('changing the theme in Settings applies and persists it', (
      tester,
    ) async {
      final env = await _pumpApp(tester);
      expect(_themeMode(tester), ThemeMode.system);

      await tester.tap(_navLabel('Settings'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();

      expect(_themeMode(tester), ThemeMode.dark);
      expect(
        env.dependencies.settingsRepository.load().themeMode,
        ThemeMode.dark,
      );
    });

    testWidgets('restores the saved theme on launch', (tester) async {
      await _pumpApp(tester, prefs: {'settings.theme_mode': 'light'});

      expect(_themeMode(tester), ThemeMode.light);
    });
  });

  group('reminders', () {
    testWidgets('lists reminders under the right headings', (tester) async {
      await _pumpApp(
        tester,
        seed: (env) async {
          await _seedReminder(env, title: 'Call dentist');
          await _seedReminder(
            env,
            title: 'Pay rent',
            start: naive(2026, 10, 24, 9),
          );
          await _seedReminder(
            env,
            title: 'Gym',
            start: naive(2026, 10, 23, 7),
            recurrence: const RecurrenceRule(unit: RepeatUnit.day),
          );
        },
      );

      expect(find.text('Overdue'), findsOneWidget);
      expect(find.text('Gym'), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Call dentist'), findsOneWidget);
      expect(find.text('Tomorrow'), findsOneWidget);
      expect(find.text('Pay rent'), findsOneWidget);
      expect(find.text('Nothing coming up'), findsNothing);
    });

    testWidgets('shows when and how often a reminder happens', (tester) async {
      await _pumpApp(
        tester,
        seed: (env) => _seedReminder(
          env,
          recurrence: const RecurrenceRule(
            unit: RepeatUnit.week,
            weekdays: {1, 3, 5},
          ),
        ),
      );

      expect(
        find.text('Today, 6:00 PM · Every week on Mon, Wed, Fri'),
        findsOneWidget,
      );
    });

    testWidgets('creates a reminder from the editor', (tester) async {
      final env = await _pumpApp(tester);

      await openEditor(tester);
      expect(find.text('What should I remind you about?'), findsOneWidget);

      await tester.enterText(find.byType(TextField).first, 'Book flights');
      await tester.tap(find.text('Save'));
      await _settle(tester);

      expect(find.text('Book flights'), findsOneWidget);
      expect(env.scheduler.reconciles, greaterThan(0));
      final saved = await tester.runAsync(env.repository.getAll);
      expect(saved!.single.title, 'Book flights');
      expect(saved.single.start, naive(2026, 10, 23, 11)); // next full hour
    });

    testWidgets('refuses to save without a title', (tester) async {
      final env = await _pumpApp(tester);

      await openEditor(tester);
      await tester.tap(find.text('Save'));
      await _settle(tester);

      expect(find.text('Give your reminder a title'), findsOneWidget);
      final saved = await tester.runAsync(env.repository.getAll);
      expect(saved, isEmpty);
    });

    testWidgets('edits an existing reminder', (tester) async {
      final env = await _pumpApp(
        tester,
        seed: (env) => _seedReminder(env, title: 'Old title'),
      );

      await tester.tap(find.text('Old title'));
      await _settle(tester);
      await tester.enterText(find.byType(TextField).first, 'New title');
      await tester.tap(find.text('Save'));
      await _settle(tester);

      expect(find.text('New title'), findsOneWidget);
      expect(find.text('Old title'), findsNothing);
      final saved = await tester.runAsync(env.repository.getAll);
      expect(saved!.single.revision, 2);
    });

    testWidgets('marking a one-time reminder done removes it', (tester) async {
      final env = await _pumpApp(
        tester,
        seed: (env) => _seedReminder(env, title: 'Call dentist'),
      );

      await tester.tap(find.byTooltip('Mark done'));
      await _settle(tester);

      expect(find.text('Call dentist'), findsNothing);
      expect(find.text('Nothing coming up'), findsOneWidget);
      final saved = await tester.runAsync(env.repository.getAll);
      expect(saved!.single.status, ReminderStatus.completed);
    });

    testWidgets('marking a recurring reminder done moves it to its next day', (
      tester,
    ) async {
      await _pumpApp(
        tester,
        seed: (env) => _seedReminder(
          env,
          title: 'Gym',
          recurrence: const RecurrenceRule(unit: RepeatUnit.day),
        ),
      );
      expect(find.text('Today'), findsOneWidget);

      await tester.tap(find.byTooltip('Mark done'));
      await _settle(tester);

      expect(find.text('Gym'), findsOneWidget);
      expect(find.text('Today'), findsNothing);
      expect(find.text('Tomorrow'), findsOneWidget);
    });

    testWidgets('swiping deletes with an Undo that restores it', (
      tester,
    ) async {
      await _pumpApp(
        tester,
        seed: (env) => _seedReminder(env, title: 'Call dentist'),
      );

      await tester.drag(find.byType(Dismissible), const Offset(-600, 0));
      await _settle(tester);
      expect(find.text('Call dentist'), findsNothing);
      expect(find.text('Reminder deleted'), findsOneWidget);

      await tester.tap(find.text('Undo'));
      await _settle(tester);
      expect(find.text('Call dentist'), findsOneWidget);
    });

    testWidgets('deleting from the editor asks first', (tester) async {
      // Tall enough to show the whole editor without scrolling.
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await _pumpApp(
        tester,
        seed: (env) => _seedReminder(env, title: 'Call dentist'),
      );

      await tester.tap(find.text('Call dentist'));
      await _settle(tester);
      await tester.tap(find.text('Delete reminder'));
      await tester.pumpAndSettle();
      expect(find.text('Delete this reminder?'), findsOneWidget);

      await tester.tap(find.text('Delete'));
      await _settle(tester);

      expect(find.text('Call dentist'), findsNothing);
      expect(find.text('Reminder deleted'), findsOneWidget);
    });
  });

  group('permissions', () {
    testWidgets('shows a banner when notifications are off and opens '
        'settings once the dialog is exhausted', (tester) async {
      final permissions = FakePermissions(notificationsEnabled: false);
      await _pumpApp(
        tester,
        permissions: permissions,
        seed: (env) => _seedReminder(env),
      );

      expect(find.text('Notifications are off'), findsOneWidget);

      await tester.tap(find.text('Turn on'));
      await _settle(tester);

      expect(permissions.notificationRequests, 1);
      expect(permissions.settingsOpened, 1);
    });

    testWidgets('offers exact alarms when they are not allowed', (
      tester,
    ) async {
      final permissions = FakePermissions(exactAlarmsAllowed: false);
      await _pumpApp(
        tester,
        permissions: permissions,
        seed: (env) => _seedReminder(env),
      );

      expect(
        find.text('Reminders may arrive a few minutes late'),
        findsOneWidget,
      );

      await tester.tap(find.text('Allow'));
      await _settle(tester);

      expect(permissions.exactAlarmRequests, 1);
    });

    testWidgets('does not nag before any reminder exists', (tester) async {
      await _pumpApp(
        tester,
        permissions: FakePermissions(notificationsEnabled: false),
      );

      expect(find.text('Notifications are off'), findsNothing);
    });

    testWidgets('asks for notification permission and explains exact alarms '
        'when the first reminder is saved', (tester) async {
      final permissions = FakePermissions(
        notificationsEnabled: false,
        exactAlarmsAllowed: false,
      );
      await _pumpApp(tester, permissions: permissions);

      await openEditor(tester);
      await tester.enterText(find.byType(TextField).first, 'Book flights');
      await tester.tap(find.text('Save'));
      await _settle(tester);

      expect(permissions.notificationRequests, 1);
      expect(find.text('Allow exact alarms?'), findsOneWidget);

      await tester.tap(find.text('Allow').last);
      await _settle(tester);

      expect(permissions.exactAlarmRequests, 1);
      expect(find.text('Book flights'), findsOneWidget);
    });
  });
}
