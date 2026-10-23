import 'package:anything_notification/core/time/naive_time.dart';
import 'package:anything_notification/features/reminders/domain/recurrence_rule.dart';
import 'package:anything_notification/features/reminders/domain/reminder.dart';
import 'package:anything_notification/features/reminders/domain/reminder_timeline.dart';
import 'package:flutter_test/flutter_test.dart';

Reminder reminder({
  required DateTime start,
  RecurrenceRule? recurrence,
  DateTime? resolvedThrough,
  ReminderStatus status = ReminderStatus.active,
}) => Reminder(
  id: 1,
  title: 'Test',
  start: start,
  recurrence: recurrence,
  resolvedThrough: resolvedThrough,
  status: status,
);

void main() {
  final now = naive(2026, 10, 23, 10);

  group('one-time', () {
    test('upcoming when in the future', () {
      final r = reminder(start: naive(2026, 10, 23, 18));

      expect(dueOf(r, now), Due(naive(2026, 10, 23, 18), isOverdue: false));
    });

    test('overdue when it fired and was not handled', () {
      final r = reminder(start: naive(2026, 10, 23, 9));

      expect(dueOf(r, now), Due(naive(2026, 10, 23, 9), isOverdue: true));
    });

    test('nothing due once handled', () {
      final r = reminder(
        start: naive(2026, 10, 23, 9),
        resolvedThrough: naive(2026, 10, 23, 9),
      );

      expect(dueOf(r, now), isNull);
    });

    test('completed reminders have nothing due', () {
      final r = reminder(
        start: naive(2026, 10, 24),
        status: ReminderStatus.completed,
      );

      expect(dueOf(r, now), isNull);
    });
  });

  group('recurring', () {
    const daily = RecurrenceRule(unit: RepeatUnit.day);

    test('only the latest unhandled occurrence is overdue', () {
      final r = reminder(start: naive(2026, 10, 20, 9), recurrence: daily);

      expect(dueOf(r, now), Due(naive(2026, 10, 23, 9), isOverdue: true));
    });

    test('moves on to the next occurrence once the latest is handled', () {
      final r = reminder(
        start: naive(2026, 10, 20, 9),
        recurrence: daily,
        resolvedThrough: naive(2026, 10, 23, 9),
      );

      expect(dueOf(r, now), Due(naive(2026, 10, 24, 9), isOverdue: false));
    });

    test('marking a future occurrence done skips it', () {
      final r = reminder(
        start: naive(2026, 10, 23, 18),
        recurrence: daily,
        resolvedThrough: naive(2026, 10, 23, 18),
      );

      expect(dueOf(r, now), Due(naive(2026, 10, 24, 18), isOverdue: false));
    });

    test('nothing due after the last occurrence is handled', () {
      const twice = RecurrenceRule(unit: RepeatUnit.day, count: 2);
      final r = reminder(
        start: naive(2026, 10, 22, 9),
        recurrence: twice,
        resolvedThrough: naive(2026, 10, 23, 9),
      );

      expect(dueOf(r, now), isNull);
    });
  });
}
