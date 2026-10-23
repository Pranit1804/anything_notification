import 'package:anything_notification/core/time/naive_time.dart';
import 'package:anything_notification/features/categories/domain/category.dart';
import 'package:anything_notification/features/reminders/application/reminder_service.dart';
import 'package:anything_notification/features/reminders/domain/occurrence_outcome.dart';
import 'package:anything_notification/features/reminders/domain/recurrence_rule.dart';
import 'package:anything_notification/features/reminders/domain/reminder.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_dependencies.dart';

void main() {
  late TestEnvironment env;
  late ReminderService service;
  late FakeScheduler scheduler;

  // The test clock is Fri 2026-10-23 10:00 (UTC, so wall-clock == instant).
  setUp(() async {
    env = await TestEnvironment.create();
    service = env.service;
    scheduler = env.scheduler;
  });
  tearDown(() => env.dispose());

  const daily = RecurrenceRule(unit: RepeatUnit.day);

  ReminderDraft draft({
    RecurrenceRule? recurrence,
    DateTime? start,
    int? categoryId,
  }) => ReminderDraft(
    title: 'Water plants',
    start: start ?? naive(2026, 10, 23, 9),
    recurrence: recurrence,
    categoryId: categoryId,
  );

  Future<Reminder> reload(Reminder r) async =>
      (await env.repository.getById(r.id))!;

  test('create, update and delete each re-arm the notifications', () async {
    final created = await service.create(draft());
    expect(scheduler.reconciles, 1);

    await service.update(created.copyWith(title: 'Water the plants'));
    expect(scheduler.reconciles, 2);

    await service.delete(created);
    expect(scheduler.reconciles, 3);
    expect(await env.repository.getById(created.id), isNull);
  });

  test('restore brings a deleted reminder back', () async {
    final created = await service.create(draft());
    await service.delete(created);

    await service.restore(created);

    expect(await env.repository.getById(created.id), created);
  });

  group('markDone', () {
    test('completes a one-time reminder and logs it', () async {
      final created = await service.create(draft());

      await service.markDone(created.id, created.start);

      final saved = await reload(created);
      expect(saved.status, ReminderStatus.completed);
      expect(saved.resolvedThrough, created.start);
      final history = await env.history.entriesFor(created.id);
      expect(history.single.outcome, OccurrenceOutcome.done);
      expect(history.single.title, 'Water plants');
      expect(scheduler.dismissed, [(created.id, created.start)]);
    });

    test('keeps a recurring reminder going', () async {
      final created = await service.create(draft(recurrence: daily));

      await service.markDone(created.id, created.start);

      final saved = await reload(created);
      expect(saved.status, ReminderStatus.active);
      expect(saved.resolvedThrough, created.start);
    });

    test('completes a series when its last occurrence is done', () async {
      final created = await service.create(
        draft(recurrence: const RecurrenceRule(unit: RepeatUnit.day, count: 2)),
      );

      await service.markDone(created.id, created.start);
      expect((await reload(created)).status, ReminderStatus.active);

      await service.markDone(created.id, naive(2026, 10, 24, 9));
      expect((await reload(created)).status, ReminderStatus.completed);
    });

    test('clears a pending snooze', () async {
      final created = await service.create(draft());
      await service.snooze(
        created.id,
        created.start,
        const Duration(minutes: 10),
      );

      await service.markDone(created.id, created.start);

      expect((await reload(created)).snoozedUntil, isNull);
    });

    test('never moves the handled point backwards', () async {
      final created = await service.create(draft(recurrence: daily));
      await service.markDone(created.id, naive(2026, 10, 25, 9));

      await service.markDone(created.id, created.start);

      expect((await reload(created)).resolvedThrough, naive(2026, 10, 25, 9));
    });

    test('ignores a reminder that no longer exists', () async {
      await service.markDone(999, naive(2026, 10, 23, 9));

      expect(scheduler.reconciles, 0);
    });

    test('logs earlier unhandled occurrences as missed', () async {
      // Daily since 20 Oct; 20, 21 and 22 passed unhandled, 23 09:00 is due.
      final created = await service.create(
        draft(recurrence: daily, start: naive(2026, 10, 20, 9)),
      );

      await service.markDone(created.id, naive(2026, 10, 23, 9));

      final history = await env.history.entriesFor(created.id);
      expect(history.map((e) => (e.outcome, e.scheduledLocal)), [
        (OccurrenceOutcome.missed, naive(2026, 10, 20, 9)),
        (OccurrenceOutcome.missed, naive(2026, 10, 21, 9)),
        (OccurrenceOutcome.missed, naive(2026, 10, 22, 9)),
        (OccurrenceOutcome.done, naive(2026, 10, 23, 9)),
      ]);
    });

    test(
      'files each missed occurrence under when the next one fired',
      () async {
        final created = await service.create(
          draft(recurrence: daily, start: naive(2026, 10, 20, 9)),
        );

        await service.markDone(created.id, naive(2026, 10, 23, 9));

        final missed = (await env.history.entriesFor(
          created.id,
        )).where((e) => e.outcome == OccurrenceOutcome.missed).toList();
        expect(missed.map((e) => e.at), [
          DateTime.utc(
            2026,
            10,
            21,
            9,
          ), // 20 Oct was superseded by 21 Oct 09:00
          DateTime.utc(2026, 10, 22, 9),
          DateTime.utc(2026, 10, 23, 9),
        ]);
      },
    );

    test('does not bump the revision (notifications stay as armed)', () async {
      final created = await service.create(draft(recurrence: daily));

      await service.markDone(created.id, created.start);

      expect((await reload(created)).revision, created.revision);
    });
  });

  group('snooze', () {
    test('arms a snooze for the given duration and logs it', () async {
      final created = await service.create(draft());

      await service.snooze(
        created.id,
        created.start,
        const Duration(minutes: 10),
      );

      final saved = await reload(created);
      expect(saved.snoozedUntil, testNow.add(const Duration(minutes: 10)));
      expect(saved.status, ReminderStatus.active);
      expect(saved.resolvedThrough, isNull); // still unhandled
      final history = await env.history.entriesFor(created.id);
      expect(history.single.outcome, OccurrenceOutcome.snoozed);
    });

    test('does nothing for a paused reminder', () async {
      final created = await service.create(draft());
      await service.setPaused(created, paused: true);

      await service.snooze(
        created.id,
        created.start,
        const Duration(minutes: 10),
      );

      expect((await reload(created)).snoozedUntil, isNull);
    });
  });

  group('pause and resume', () {
    test('flips the status', () async {
      final created = await service.create(draft());

      await service.setPaused(created, paused: true);
      final paused = await reload(created);
      expect(paused.status, ReminderStatus.paused);

      await service.setPaused(paused, paused: false);
      expect((await reload(created)).status, ReminderStatus.active);
    });

    test('resuming skips occurrences that passed while paused', () async {
      final created = await service.create(
        draft(recurrence: daily, start: naive(2026, 10, 20, 9)),
      );
      await service.setPaused(created, paused: true);

      await service.setPaused(await reload(created), paused: false);

      final resumed = await reload(created);
      expect(resumed.resolvedThrough, naive(2026, 10, 23, 9));
      // Nothing was invented as "missed" for the paused days.
      expect(await env.history.entriesFor(created.id), isEmpty);
    });
  });

  group('settleMissed', () {
    test('records superseded occurrences once and keeps the latest', () async {
      final created = await service.create(
        draft(recurrence: daily, start: naive(2026, 10, 20, 9)),
      );

      await service.settleMissed();
      await service.settleMissed(); // again: nothing new

      final history = await env.history.entriesFor(created.id);
      expect(history.map((e) => e.scheduledLocal), [
        naive(2026, 10, 20, 9),
        naive(2026, 10, 21, 9),
        naive(2026, 10, 22, 9),
      ]);
      expect(
        history.every((e) => e.outcome == OccurrenceOutcome.missed),
        isTrue,
      );
      // 23 Oct 09:00 is still awaiting the user.
      expect((await reload(created)).resolvedThrough, naive(2026, 10, 22, 9));
    });

    test('never touches a one-time reminder', () async {
      final created = await service.create(draft(start: naive(2026, 10, 1, 9)));

      await service.settleMissed();

      expect(await env.history.entriesFor(created.id), isEmpty);
      expect((await reload(created)).status, ReminderStatus.active);
    });

    test('ignores paused reminders', () async {
      final created = await service.create(
        draft(recurrence: daily, start: naive(2026, 10, 20, 9)),
      );
      await service.setPaused(created, paused: true);

      await service.settleMissed();

      expect(await env.history.entriesFor(created.id), isEmpty);
    });

    test('caps how many missed entries one run writes', () async {
      // Every 15 minutes since 1 Oct: thousands of occurrences have passed.
      final created = await service.create(
        draft(
          recurrence: const RecurrenceRule(
            unit: RepeatUnit.minute,
            interval: 15,
          ),
          start: naive(2026, 10, 1, 9),
        ),
      );

      await service.settleMissed();

      final history = await env.history.entriesFor(created.id);
      expect(history, hasLength(ReminderService.maxMissedPerRun));
      // The most recent ones are kept.
      expect(history.last.scheduledLocal, naive(2026, 10, 23, 9, 45));
    });

    test('purges history older than the retention setting', () async {
      await env.history.log(
        reminderId: 1,
        title: 'Old',
        scheduledLocal: naive(2026, 1, 1, 9),
        outcome: OccurrenceOutcome.done,
        at: testNow.subtract(const Duration(days: 120)),
      );
      await env.history.log(
        reminderId: 1,
        title: 'Recent',
        scheduledLocal: naive(2026, 10, 1, 9),
        outcome: OccurrenceOutcome.done,
        at: testNow.subtract(const Duration(days: 10)),
      );

      await service.settleMissed(); // default retention: 90 days

      final titles = (await env.history.entriesFor(1)).map((e) => e.title);
      expect(titles, ['Recent']);
    });

    test('keeps everything when retention is forever', () async {
      await env.settings.save(
        env.settings.load().copyWith(historyRetentionDays: 0),
      );
      await env.history.log(
        reminderId: 1,
        title: 'Ancient',
        scheduledLocal: naive(2020, 1, 1, 9),
        outcome: OccurrenceOutcome.done,
        at: testNow.subtract(const Duration(days: 2000)),
      );

      await service.settleMissed();

      expect(await env.history.entriesFor(1), hasLength(1));
    });
  });

  group('history snapshots', () {
    test('copy the category so history survives its deletion', () async {
      final category = await env.categories.create(
        const CategoryDraft(
          name: 'Garden',
          colorValue: 0xFF2F9E44,
          iconKey: 'home',
        ),
      );
      final created = await service.create(draft(categoryId: category.id));

      await service.markDone(created.id, created.start);
      await env.categories.delete(category.id);

      final entry = (await env.history.entriesFor(created.id)).single;
      expect(entry.categoryName, 'Garden');
      expect(entry.categoryColor, 0xFF2F9E44);
      expect(entry.categoryId, category.id);
    });

    test('have no category when the reminder has none', () async {
      final created = await service.create(draft());

      await service.markDone(created.id, created.start);

      final entry = (await env.history.entriesFor(created.id)).single;
      expect(entry.categoryName, isNull);
      expect(entry.categoryId, isNull);
    });
  });
}
