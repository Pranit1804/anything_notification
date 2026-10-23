import 'package:anything_notification/core/time/naive_time.dart';
import 'package:anything_notification/features/reminders/domain/recurrence_rule.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('validate', () {
    test('accepts a plain daily rule', () {
      expect(const RecurrenceRule(unit: RepeatUnit.day).validate(), isNull);
    });

    test('rejects intervals below one', () {
      expect(
        const RecurrenceRule(unit: RepeatUnit.day, interval: 0).validate(),
        RecurrenceRuleError.intervalTooSmall,
      );
    });

    test('enforces the 15 minute minimum', () {
      expect(
        const RecurrenceRule(unit: RepeatUnit.minute, interval: 10).validate(),
        RecurrenceRuleError.minuteIntervalTooSmall,
      );
      expect(
        const RecurrenceRule(unit: RepeatUnit.minute, interval: 15).validate(),
        isNull,
      );
    });

    test('rejects an end date together with an end count', () {
      expect(
        RecurrenceRule(
          unit: RepeatUnit.day,
          until: naive(2027, 1, 1),
          count: 3,
        ).validate(),
        RecurrenceRuleError.twoEndings,
      );
    });
  });

  group('json', () {
    test('round-trips every field', () {
      final rule = RecurrenceRule(
        unit: RepeatUnit.week,
        interval: 2,
        weekdays: const {5, 1, 3},
        lastDayOfMonth: true,
        until: naive(2027, 6, 30),
      );

      expect(RecurrenceRule.fromJson(rule.toJson()), rule);
    });

    test('round-trips a count-limited rule', () {
      const rule = RecurrenceRule(unit: RepeatUnit.month, count: 6);

      expect(RecurrenceRule.fromJson(rule.toJson()), rule);
    });

    test('weekday order does not matter for equality', () {
      expect(
        const RecurrenceRule(unit: RepeatUnit.week, weekdays: {1, 3}),
        const RecurrenceRule(unit: RepeatUnit.week, weekdays: {3, 1}),
      );
    });
  });
}
