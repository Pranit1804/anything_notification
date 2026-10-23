import 'package:anything_notification/core/time/naive_time.dart';
import 'package:anything_notification/features/reminders/domain/recurrence_rule.dart';
import 'package:anything_notification/features/reminders/domain/reminder.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_dependencies.dart';

void main() {
  late TestEnvironment env;
  final now = DateTime.utc(2026, 10, 23, 14);

  setUp(() async => env = await TestEnvironment.create());
  tearDown(() => env.dispose());

  ReminderDraft draft({
    String title = 'Pay rent',
    DateTime? start,
    RecurrenceRule? recurrence,
    int? categoryId,
  }) => ReminderDraft(
    title: title,
    note: 'Landlord',
    start: start ?? naive(2026, 11, 1, 9),
    recurrence: recurrence,
    categoryId: categoryId,
  );

  test('create then read keeps the naive wall-clock time exact', () async {
    final created = await env.repository.create(draft(), now: now);
    final loaded = await env.repository.getById(created.id);

    expect(loaded, created);
    expect(loaded!.start, naive(2026, 11, 1, 9));
    expect(loaded.start.hour, 9); // not shifted by the device time zone
    expect(loaded.revision, 1);
    expect(loaded.status, ReminderStatus.active);
  });

  test('recurrence rules round-trip', () async {
    const rule = RecurrenceRule(
      unit: RepeatUnit.week,
      interval: 2,
      weekdays: {1, 3},
      count: 10,
    );
    final created = await env.repository.create(
      draft(recurrence: rule),
      now: now,
    );

    expect((await env.repository.getById(created.id))!.recurrence, rule);
  });

  test('the category link round-trips and can be cleared', () async {
    final created = await env.repository.create(draft(categoryId: 3), now: now);
    expect((await env.repository.getById(created.id))!.categoryId, 3);

    await env.repository.update(created.copyWith(clearCategory: true));

    expect((await env.repository.getById(created.id))!.categoryId, isNull);
  });

  test('update bumps the revision and persists every field', () async {
    final created = await env.repository.create(draft(), now: now);

    final saved = await env.repository.update(
      created.copyWith(
        title: 'Pay rent online',
        resolvedThrough: naive(2026, 11, 1, 9),
        snoozedUntil: DateTime.utc(2026, 11, 1, 14, 10),
        status: ReminderStatus.paused,
        clearNote: true,
      ),
    );
    final loaded = await env.repository.getById(created.id);

    expect(saved.revision, 2);
    expect(loaded, saved);
    expect(loaded!.note, isNull);
    expect(loaded.resolvedThrough, naive(2026, 11, 1, 9));
    expect(loaded.snoozedUntil, DateTime.utc(2026, 11, 1, 14, 10));
    expect(loaded.status, ReminderStatus.paused);
  });

  test('update can leave the revision alone', () async {
    final created = await env.repository.create(draft(), now: now);

    final saved = await env.repository.update(
      created.copyWith(resolvedThrough: naive(2026, 11, 1, 9)),
      bumpRevision: false,
    );

    expect(saved.revision, 1);
    expect((await env.repository.getById(created.id))!.revision, 1);
  });

  test('delete removes the reminder and restore brings it back', () async {
    final created = await env.repository.create(draft(), now: now);

    await env.repository.delete(created.id);
    expect(await env.repository.getById(created.id), isNull);

    await env.repository.restore(created, createdAt: now);
    expect(await env.repository.getById(created.id), created);
  });

  test('watchAll emits in start order and re-emits on change', () async {
    final later = await env.repository.create(
      draft(title: 'Later', start: naive(2026, 12, 1, 9)),
      now: now,
    );
    await env.repository.create(
      draft(title: 'Sooner', start: naive(2026, 11, 1, 9)),
      now: now,
    );

    final stream = env.repository.watchAll();
    expect(await stream.first.then((l) => l.map((r) => r.title)), [
      'Sooner',
      'Later',
    ]);

    final next = expectLater(
      stream.skip(1),
      emits(predicate<List<Reminder>>((l) => l.length == 1)),
    );
    await env.repository.delete(later.id);
    await next;
  });
}
