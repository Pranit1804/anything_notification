import 'package:anything_notification/app/app.dart';
import 'package:anything_notification/core/time/naive_time.dart';
import 'package:anything_notification/features/reminders/domain/recurrence_rule.dart';
import 'package:anything_notification/features/reminders/domain/reminder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_dependencies.dart';

/// Pumps the whole app on an in-memory environment. [seed] runs first, on the
/// real async zone (the database needs it).
Future<TestEnvironment> pumpApp(
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
  await settle(tester);
  return env;
}

/// Lets database streams and animations finish.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
  }
}

Finder navLabel(String label) =>
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label));

Future<void> seedReminder(
  TestEnvironment env, {
  String title = 'Water plants',
  DateTime? start,
  RecurrenceRule? recurrence,
  int? categoryId,
}) async {
  await env.service.create(
    ReminderDraft(
      title: title,
      start: start ?? naive(2026, 10, 23, 18),
      recurrence: recurrence,
      categoryId: categoryId,
    ),
  );
}

/// A taller window, for screens that need scrolling otherwise.
void useTallWindow(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// Opens the full editor: the button opens quick-add, whose "More options"
/// leads there (carrying along whatever was typed).
Future<void> openEditor(WidgetTester tester) async {
  await tester.tap(find.text('New reminder'));
  await settle(tester);
  await tester.tap(find.text('More options'));
  await settle(tester);
}
