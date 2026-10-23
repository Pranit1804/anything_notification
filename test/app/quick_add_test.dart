import 'package:anything_notification/core/time/naive_time.dart';
import 'package:anything_notification/features/reminders/domain/recurrence_rule.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_app.dart';

Future<void> _openQuickAdd(WidgetTester tester) async {
  await tester.tap(find.text('New reminder'));
  await settle(tester);
}

Future<void> _type(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  await tester.pumpAndSettle();
}

Finder _chip(String label) => find.widgetWithText(ActionChip, label);

void main() {
  // The test clock is Fri 2026-10-23 10:00.

  group('quick-add sheet', () {
    testWidgets('the button opens it with a hint', (tester) async {
      await pumpApp(tester);

      await _openQuickAdd(tester);

      expect(find.text('Try "Pay rent every 1st at 9am"'), findsOneWidget);
      expect(find.text('Add'), findsOneWidget);
      expect(find.text('More options'), findsOneWidget);
    });

    testWidgets('shows what it understood as chips while you type', (
      tester,
    ) async {
      await pumpApp(tester);
      await _openQuickAdd(tester);

      await _type(tester, 'Gym every mon wed fri 7am #health');

      expect(_chip('Mon, 7:00 AM'), findsNothing); // not the format
      expect(find.textContaining('Mon 26 Oct, 7:00 AM'), findsOneWidget);
      expect(find.text('Every week on Mon, Wed, Fri'), findsOneWidget);
      expect(find.text('Health'), findsOneWidget);
    });

    testWidgets('adds the reminder with what was understood', (tester) async {
      final env = await pumpApp(tester);
      await _openQuickAdd(tester);

      await _type(tester, 'Call mom tomorrow at 6pm');
      await tester.tap(find.text('Add'));
      await settle(tester);

      final saved = (await tester.runAsync(env.repository.getAll))!.single;
      expect(saved.title, 'Call mom');
      expect(saved.start, naive(2026, 10, 24, 18));
      expect(saved.recurrence, isNull);
      expect(saved.categoryId, isNull);
      // The sheet is gone and the new reminder is listed.
      expect(find.text('Add'), findsNothing);
      expect(find.text('Call mom'), findsOneWidget);
      expect(env.scheduler.reconciles, greaterThan(0));
    });

    testWidgets('keeps the repeat and the category', (tester) async {
      final env = await pumpApp(tester);
      await _openQuickAdd(tester);

      await _type(tester, 'Gym every mon wed fri 7am #health');
      await tester.tap(find.text('Add'));
      await settle(tester);

      final health = (await tester.runAsync(env.categories.getAll))![2];
      final saved = (await tester.runAsync(env.repository.getAll))!.single;
      expect(saved.title, 'Gym');
      expect(
        saved.recurrence,
        const RecurrenceRule(unit: RepeatUnit.week, weekdays: {1, 3, 5}),
      );
      expect(saved.categoryId, health.id);
    });

    testWidgets('a tag that matches no category is ignored', (tester) async {
      final env = await pumpApp(tester);
      await _openQuickAdd(tester);

      await _type(tester, 'Buy milk tomorrow #groceries');
      await tester.tap(find.text('Add'));
      await settle(tester);

      final saved = (await tester.runAsync(env.repository.getAll))!.single;
      expect(saved.title, 'Buy milk');
      expect(saved.categoryId, isNull);
    });

    testWidgets('asks for a time when the text has none', (tester) async {
      final env = await pumpApp(tester);
      await _openQuickAdd(tester);
      await _type(tester, 'Buy milk');
      expect(find.text('Pick a time'), findsOneWidget);

      await tester.tap(find.text('Add'));
      await settle(tester);
      // The date picker, then the time picker.
      await tester.tap(find.text('OK'));
      await settle(tester);
      await tester.tap(find.text('OK'));
      await settle(tester);

      final saved = (await tester.runAsync(env.repository.getAll))!.single;
      expect(saved.title, 'Buy milk');
      expect(saved.start.isAfter(naive(2026, 10, 23, 10)), isTrue);
    });

    testWidgets('does not save when the time picker is dismissed', (
      tester,
    ) async {
      final env = await pumpApp(tester);
      await _openQuickAdd(tester);
      await _type(tester, 'Buy milk');

      await tester.tap(find.text('Add'));
      await settle(tester);
      await tester.tap(find.text('Cancel'));
      await settle(tester);

      expect((await tester.runAsync(env.repository.getAll))!, isEmpty);
      expect(find.text('Add'), findsOneWidget); // still in the sheet
    });

    testWidgets('needs something to remind you about', (tester) async {
      final env = await pumpApp(tester);
      await _openQuickAdd(tester);

      await _type(tester, '6pm');
      await tester.tap(find.text('Add'));
      await settle(tester);

      expect(find.text('Add what to remind you about'), findsOneWidget);
      expect((await tester.runAsync(env.repository.getAll))!, isEmpty);
    });

    testWidgets('refuses an interval below the minimum', (tester) async {
      final env = await pumpApp(tester);
      await _openQuickAdd(tester);

      await _type(tester, 'Stretch every 5 minutes');
      await tester.tap(find.text('Add'));
      await settle(tester);

      expect(find.text("This repeat isn't valid"), findsOneWidget);
      expect((await tester.runAsync(env.repository.getAll))!, isEmpty);
    });

    testWidgets('refuses a time in the past', (tester) async {
      final env = await pumpApp(tester);
      await _openQuickAdd(tester);

      await _type(tester, 'Call back today 8am');
      await tester.tap(find.text('Add'));
      await settle(tester);

      expect(find.text('Pick a time in the future'), findsOneWidget);
      expect((await tester.runAsync(env.repository.getAll))!, isEmpty);
    });

    testWidgets('the category can be changed by hand', (tester) async {
      useTallWindow(tester);
      final env = await pumpApp(tester);
      await _openQuickAdd(tester);
      await _type(tester, 'Review budget tomorrow 5pm #work');
      expect(find.text('Work'), findsOneWidget);

      await tester.tap(find.text('Work'));
      await settle(tester);
      await tester.tap(find.text('Bills'));
      await settle(tester);
      await tester.tap(find.text('Add'));
      await settle(tester);

      final bills = (await tester.runAsync(env.categories.getAll))![3];
      final saved = (await tester.runAsync(env.repository.getAll))!.single;
      expect(saved.categoryId, bills.id);
    });

    testWidgets('a hand-picked repeat wins over the text', (tester) async {
      final env = await pumpApp(tester);
      await _openQuickAdd(tester);
      await _type(tester, 'Pay rent tomorrow 9am');

      await tester.tap(find.text("Doesn't repeat"));
      await settle(tester);
      await tester.tap(find.text('Every month'));
      await settle(tester);
      await tester.tap(find.text('Add'));
      await settle(tester);

      final saved = (await tester.runAsync(env.repository.getAll))!.single;
      expect(saved.recurrence, const RecurrenceRule(unit: RepeatUnit.month));
    });

    testWidgets('More options opens the editor with what was typed', (
      tester,
    ) async {
      useTallWindow(tester);
      await pumpApp(tester);
      await _openQuickAdd(tester);
      await _type(tester, 'Gym every mon wed fri 7am #health');

      await tester.tap(find.text('More options'));
      await settle(tester);

      expect(find.text('New reminder'), findsOneWidget); // the editor's title
      expect(find.text('Gym'), findsOneWidget); // in the title field
      expect(find.text('Every week on Mon, Wed, Fri'), findsOneWidget);
      expect(find.text('7:00 AM'), findsOneWidget);
      expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Health'))
            .selected,
        isTrue,
      );
    });
  });

  group('empty state examples', () {
    testWidgets('are offered when there is nothing yet', (tester) async {
      await pumpApp(tester);

      expect(find.text('Drink water every 2 hours'), findsOneWidget);
      expect(find.text('Pay rent every 1st at 9am'), findsOneWidget);
      expect(find.text('Call mom tomorrow at 6pm'), findsOneWidget);
    });

    testWidgets('tapping one fills quick-add with it', (tester) async {
      await pumpApp(tester);

      await tester.tap(find.text('Pay rent every 1st at 9am'));
      await settle(tester);

      expect(
        find.widgetWithText(TextField, 'Pay rent every 1st at 9am'),
        findsOneWidget,
      );
      expect(find.text('Every month'), findsOneWidget);
    });

    testWidgets('are not shown once a reminder exists', (tester) async {
      await pumpApp(tester, seed: seedReminder);

      expect(find.text('Try typing'), findsNothing);
    });
  });

  group('default reminder time', () {
    testWidgets('is what a day without a time gets', (tester) async {
      await pumpApp(
        tester,
        // 18:30, as minutes after midnight.
        prefs: {'settings.default_reminder_minutes': 18 * 60 + 30},
      );
      await _openQuickAdd(tester);

      await _type(tester, 'Call mom tomorrow');

      expect(find.textContaining('6:30 PM'), findsOneWidget);
    });

    testWidgets('shows in Settings and defaults to 9:00 AM', (tester) async {
      useTallWindow(tester);
      await pumpApp(tester);

      await tester.tap(navLabel('Settings'));
      await settle(tester);

      expect(find.text('Default reminder time'), findsOneWidget);
      expect(find.text('9:00 AM'), findsOneWidget);
    });
  });
}
