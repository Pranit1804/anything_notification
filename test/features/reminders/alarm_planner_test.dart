import 'package:anything_notification/core/time/naive_time.dart';
import 'package:anything_notification/core/time/zoned_clock.dart';
import 'package:anything_notification/features/categories/domain/category.dart';
import 'package:anything_notification/features/reminders/domain/alarm_planner.dart';
import 'package:anything_notification/features/reminders/domain/recurrence_rule.dart';
import 'package:anything_notification/features/reminders/domain/reminder.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

void main() {
  setUpAll(tz_data.initializeTimeZones);

  // Fri 2026-10-23 10:00 in New York (EDT).
  final clock = ZonedClock(
    now: () => DateTime.utc(2026, 10, 23, 14),
    location: () => tz.getLocation('America/New_York'),
  );
  const planner = AlarmPlanner();

  Reminder reminder(
    int id, {
    required DateTime start,
    RecurrenceRule? recurrence,
    ReminderStatus status = ReminderStatus.active,
    DateTime? resolvedThrough,
    DateTime? snoozedUntil,
    int? categoryId,
  }) => Reminder(
    id: id,
    title: 'Reminder $id',
    start: start,
    categoryId: categoryId,
    recurrence: recurrence,
    status: status,
    resolvedThrough: resolvedThrough,
    snoozedUntil: snoozedUntil,
  );

  test('arms a one-time reminder at the right instant', () {
    final plan = planner.plan([
      reminder(1, start: naive(2026, 10, 24, 9)),
    ], clock);

    expect(plan, hasLength(1));
    expect(plan.single.fireAt, DateTime.utc(2026, 10, 24, 13));
    expect(plan.single.kind, AlarmKind.occurrence);
    expect(plan.single.occurrence, naive(2026, 10, 24, 9));
  });

  test('always arms the next occurrence, however far away', () {
    final plan = planner.plan([
      reminder(1, start: naive(2027, 8, 1, 9)),
    ], clock);

    expect(plan, hasLength(1));
  });

  test('skips past, paused and completed reminders', () {
    final plan = planner.plan([
      reminder(1, start: naive(2026, 10, 23, 9)),
      reminder(2, start: naive(2026, 10, 25, 9), status: ReminderStatus.paused),
      reminder(
        3,
        start: naive(2026, 10, 25, 9),
        status: ReminderStatus.completed,
      ),
    ], clock);

    expect(plan, isEmpty);
  });

  test('does not re-arm an occurrence that was already handled', () {
    final plan = planner.plan([
      reminder(
        1,
        start: naive(2026, 10, 24, 9),
        resolvedThrough: naive(2026, 10, 24, 9),
      ),
    ], clock);

    expect(plan, isEmpty);
  });

  test('a daily reminder keeps its next 12 occurrences armed', () {
    final plan = planner.plan([
      reminder(
        1,
        start: naive(2026, 10, 1, 9),
        recurrence: const RecurrenceRule(unit: RepeatUnit.day),
      ),
    ], clock);

    expect(plan, hasLength(12));
    expect(plan.first.occurrence, naive(2026, 10, 24, 9));
    expect(plan.last.occurrence, naive(2026, 11, 4, 9));
  });

  test('a weekly reminder is armed only inside the 14 day horizon', () {
    final plan = planner.plan([
      reminder(
        1,
        start: naive(2026, 10, 1, 9),
        recurrence: const RecurrenceRule(unit: RepeatUnit.week),
      ),
    ], clock);

    // Thu 29 Oct and Thu 5 Nov; Thu 12 Nov is beyond now + 14 days.
    expect(plan.map((a) => a.occurrence), [
      naive(2026, 10, 29, 9),
      naive(2026, 11, 5, 9),
    ]);
  });

  test('sub-hour intervals get the larger window', () {
    final plan = planner.plan([
      reminder(
        1,
        start: naive(2026, 10, 23, 8),
        recurrence: const RecurrenceRule(unit: RepeatUnit.minute, interval: 15),
      ),
    ], clock);

    expect(plan, hasLength(24));
    expect(plan.first.occurrence, naive(2026, 10, 23, 10, 15));
  });

  test('arms a snooze alarm for the overdue occurrence', () {
    final plan = planner.plan([
      reminder(
        1,
        start: naive(2026, 10, 23, 9),
        snoozedUntil: DateTime.utc(2026, 10, 23, 14, 10),
      ),
    ], clock);

    expect(plan, hasLength(1));
    expect(plan.single.kind, AlarmKind.snooze);
    expect(plan.single.fireAt, DateTime.utc(2026, 10, 23, 14, 10));
    expect(plan.single.occurrence, naive(2026, 10, 23, 9));
  });

  test('ignores a snooze time that already passed', () {
    final plan = planner.plan([
      reminder(
        1,
        start: naive(2026, 10, 23, 9),
        snoozedUntil: DateTime.utc(2026, 10, 23, 13, 50),
      ),
    ], clock);

    expect(plan, isEmpty);
  });

  test('the global cap keeps every reminder\'s next occurrence first', () {
    const capped = AlarmPlanner(globalLimit: 4);
    final plan = capped.plan([
      for (var id = 1; id <= 3; id++)
        reminder(
          id,
          start: naive(2026, 10, 24, 9 + id),
          recurrence: const RecurrenceRule(unit: RepeatUnit.day),
        ),
    ], clock);

    expect(plan, hasLength(4));
    // All three "next" alarms survive, plus the earliest extra.
    expect(
      plan.where((a) => a.occurrence.day == 24).map((a) => a.reminderId),
      unorderedEquals([1, 2, 3]),
    );
    expect(plan.last.occurrence, naive(2026, 10, 25, 10));
  });

  group('categories', () {
    const bills = Category(
      id: 4,
      name: 'Bills',
      colorValue: 0xFFE8590C,
      iconKey: 'bills',
      sortOrder: 3,
    );

    test('their name and color go onto the alarm', () {
      final plan = planner.plan(
        [reminder(1, start: naive(2026, 10, 24, 9), categoryId: 4)],
        clock,
        categories: {4: bills},
      );

      expect(plan.single.categoryName, 'Bills');
      expect(plan.single.categoryColor, 0xFFE8590C);
    });

    test('also reach the snooze alarm', () {
      final plan = planner.plan(
        [
          reminder(
            1,
            start: naive(2026, 10, 23, 9),
            categoryId: 4,
            snoozedUntil: DateTime.utc(2026, 10, 23, 14, 10),
          ),
        ],
        clock,
        categories: {4: bills},
      );

      expect(plan.single.kind, AlarmKind.snooze);
      expect(plan.single.categoryName, 'Bills');
    });

    test('a reminder without one, or whose category is gone, has none', () {
      final plan = planner.plan(
        [
          reminder(1, start: naive(2026, 10, 24, 9)),
          reminder(2, start: naive(2026, 10, 24, 9), categoryId: 99),
        ],
        clock,
        categories: {4: bills},
      );

      expect(plan.map((a) => a.categoryName), [null, null]);
    });
  });

  group('notification ids', () {
    test('are stable for the same occurrence', () {
      final a = AlarmPlanner.notificationId(
        7,
        AlarmKind.occurrence,
        naive(2026, 10, 24, 9),
      );
      final b = AlarmPlanner.notificationId(
        7,
        AlarmKind.occurrence,
        naive(2026, 10, 24, 9),
      );

      expect(a, b);
      expect(a, isNonNegative);
      expect(a, lessThanOrEqualTo(0x7fffffff));
    });

    test('differ per reminder, kind and occurrence', () {
      final base = naive(2026, 10, 24, 9);
      final ids = {
        AlarmPlanner.notificationId(7, AlarmKind.occurrence, base),
        AlarmPlanner.notificationId(8, AlarmKind.occurrence, base),
        AlarmPlanner.notificationId(7, AlarmKind.snooze, base),
        AlarmPlanner.notificationId(
          7,
          AlarmKind.occurrence,
          base.add(const Duration(days: 1)),
        ),
      };

      expect(ids, hasLength(4));
    });

    test('are unique within a plan', () {
      final plan = planner.plan([
        for (var id = 1; id <= 40; id++)
          reminder(
            id,
            start: naive(2026, 10, 24, 9),
            recurrence: const RecurrenceRule(unit: RepeatUnit.day),
          ),
      ], clock);

      expect(plan.map((a) => a.id).toSet(), hasLength(plan.length));
    });
  });
}
