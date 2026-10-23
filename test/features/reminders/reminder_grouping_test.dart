import 'package:anything_notification/core/time/naive_time.dart';
import 'package:anything_notification/features/reminders/domain/recurrence_rule.dart';
import 'package:anything_notification/features/reminders/domain/reminder.dart';
import 'package:anything_notification/features/reminders/domain/reminder_grouping.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Fri 2026-10-23 10:00.
  final nowNaive = naive(2026, 10, 23, 10);
  final nowInstant = DateTime.utc(2026, 10, 23, 14);

  Reminder reminder(
    int id,
    DateTime start, {
    RecurrenceRule? recurrence,
    ReminderStatus status = ReminderStatus.active,
    DateTime? snoozedUntil,
    DateTime? resolvedThrough,
  }) => Reminder(
    id: id,
    title: 'R$id',
    start: start,
    recurrence: recurrence,
    status: status,
    snoozedUntil: snoozedUntil,
    resolvedThrough: resolvedThrough,
  );

  GroupedReminders group(List<Reminder> reminders) =>
      groupReminders(reminders, nowNaive: nowNaive, nowInstant: nowInstant);

  Map<ReminderSection, List<int>> ids(GroupedReminders g) => {
    for (final group in g.groups)
      group.section: [for (final i in group.items) i.reminder.id],
  };

  test('sorts reminders into sections by how soon they are due', () {
    final grouped = group([
      reminder(1, naive(2026, 10, 23, 9)), // fired, unhandled
      reminder(2, naive(2026, 10, 23, 18)),
      reminder(3, naive(2026, 10, 24, 9)),
      reminder(4, naive(2026, 10, 27, 9)),
      reminder(5, naive(2026, 10, 30, 9)), // 7 days away
      reminder(6, naive(2027, 1, 1, 9)),
    ]);

    expect(ids(grouped), {
      ReminderSection.overdue: [1],
      ReminderSection.today: [2],
      ReminderSection.tomorrow: [3],
      ReminderSection.thisWeek: [4],
      ReminderSection.later: [5, 6],
    });
  });

  test('orders items inside a section by time', () {
    final grouped = group([
      reminder(1, naive(2026, 10, 23, 20)),
      reminder(2, naive(2026, 10, 23, 12)),
    ]);

    expect(ids(grouped)[ReminderSection.today], [2, 1]);
  });

  test('omits empty sections', () {
    final grouped = group([reminder(1, naive(2026, 10, 24, 9))]);

    expect(grouped.groups.map((g) => g.section), [ReminderSection.tomorrow]);
  });

  test('a recurring reminder appears once, at its current occurrence', () {
    final grouped = group([
      reminder(
        1,
        naive(2026, 10, 20, 9),
        recurrence: const RecurrenceRule(unit: RepeatUnit.day),
      ),
    ]);

    expect(ids(grouped), {
      ReminderSection.overdue: [1], // today's 09:00 occurrence, unhandled
    });
  });

  test('paused reminders are listed separately', () {
    final grouped = group([
      reminder(1, naive(2026, 10, 24, 9), status: ReminderStatus.paused),
    ]);

    expect(grouped.groups, isEmpty);
    expect(grouped.paused.map((i) => i.reminder.id), [1]);
  });

  test('completed reminders and finished series are left out', () {
    final grouped = group([
      reminder(1, naive(2026, 10, 24, 9), status: ReminderStatus.completed),
      reminder(
        2,
        naive(2026, 10, 22, 9),
        resolvedThrough: naive(2026, 10, 22, 9),
      ),
    ]);

    expect(grouped.isEmpty, isTrue);
  });

  test('exposes a running snooze but not an expired one', () {
    final grouped = group([
      reminder(
        1,
        naive(2026, 10, 23, 9),
        snoozedUntil: DateTime.utc(2026, 10, 23, 14, 10),
      ),
      reminder(
        2,
        naive(2026, 10, 23, 9),
        snoozedUntil: DateTime.utc(2026, 10, 23, 13, 50),
      ),
    ]);

    final items = grouped.groups.single.items;
    expect(items.firstWhere((i) => i.reminder.id == 1).snoozedUntil, isNotNull);
    expect(items.firstWhere((i) => i.reminder.id == 2).snoozedUntil, isNull);
  });
}
