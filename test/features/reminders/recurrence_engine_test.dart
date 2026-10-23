import 'package:anything_notification/core/time/naive_time.dart';
import 'package:anything_notification/features/reminders/domain/recurrence_engine.dart';
import 'package:anything_notification/features/reminders/domain/recurrence_rule.dart';
import 'package:flutter_test/flutter_test.dart';

const engine = RecurrenceEngine();

List<DateTime> next(
  DateTime start,
  RecurrenceRule? rule,
  DateTime after, [
  int take = 5,
]) => engine.occurrencesAfter(start, rule, after).take(take).toList();

void main() {
  group('one-time', () {
    final start = naive(2026, 10, 23, 9);

    test('fires once at the start', () {
      expect(next(start, null, naive(2026, 10, 23, 8, 59)), [start]);
    });

    test('has no occurrence at or after the start has passed', () {
      expect(next(start, null, start), isEmpty);
      expect(next(start, null, naive(2026, 10, 24)), isEmpty);
    });
  });

  group('daily and custom day intervals', () {
    final start = naive(2026, 10, 23, 9);

    test('every day', () {
      const rule = RecurrenceRule(unit: RepeatUnit.day);
      expect(next(start, rule, start, 3), [
        naive(2026, 10, 24, 9),
        naive(2026, 10, 25, 9),
        naive(2026, 10, 26, 9),
      ]);
    });

    test('includes the start when asked from before it', () {
      const rule = RecurrenceRule(unit: RepeatUnit.day);
      expect(next(start, rule, naive(2026, 10, 23, 8, 59), 1), [start]);
    });

    test('every 2 days, across a month end', () {
      const rule = RecurrenceRule(unit: RepeatUnit.day, interval: 2);
      expect(next(naive(2026, 10, 29, 7), rule, naive(2026, 10, 29, 7), 3), [
        naive(2026, 10, 31, 7),
        naive(2026, 11, 2, 7),
        naive(2026, 11, 4, 7),
      ]);
    });
  });

  group('minute and hour intervals', () {
    test('every 15 minutes', () {
      const rule = RecurrenceRule(unit: RepeatUnit.minute, interval: 15);
      expect(
        next(naive(2026, 10, 23, 8), rule, naive(2026, 10, 23, 8, 20), 3),
        [
          naive(2026, 10, 23, 8, 30),
          naive(2026, 10, 23, 8, 45),
          naive(2026, 10, 23, 9),
        ],
      );
    });

    test('every 2 hours stays anchored to the start time', () {
      const rule = RecurrenceRule(unit: RepeatUnit.hour, interval: 2);
      expect(
        next(naive(2026, 10, 23, 8), rule, naive(2026, 10, 23, 11, 30), 3),
        [
          naive(2026, 10, 23, 12),
          naive(2026, 10, 23, 14),
          naive(2026, 10, 23, 16),
        ],
      );
    });
  });

  group('weekly', () {
    test('defaults to the weekday of the start', () {
      const rule = RecurrenceRule(unit: RepeatUnit.week);
      // 2026-10-23 is a Friday.
      expect(next(naive(2026, 10, 23, 18), rule, naive(2026, 10, 23, 18), 2), [
        naive(2026, 10, 30, 18),
        naive(2026, 11, 6, 18),
      ]);
    });

    test('Mon/Wed/Fri skips weekdays before the start', () {
      const rule = RecurrenceRule(unit: RepeatUnit.week, weekdays: {1, 3, 5});
      // Start on Wednesday 2026-10-21: the Monday of that week is excluded.
      expect(next(naive(2026, 10, 21, 7), rule, naive(2026, 10, 21, 6), 5), [
        naive(2026, 10, 21, 7),
        naive(2026, 10, 23, 7),
        naive(2026, 10, 26, 7),
        naive(2026, 10, 28, 7),
        naive(2026, 10, 30, 7),
      ]);
    });

    test('every 2 weeks on Mon and Wed skips the off week', () {
      const rule = RecurrenceRule(
        unit: RepeatUnit.week,
        interval: 2,
        weekdays: {1, 3},
      );
      expect(next(naive(2026, 10, 19, 9), rule, naive(2026, 10, 19, 8), 4), [
        naive(2026, 10, 19, 9),
        naive(2026, 10, 21, 9),
        naive(2026, 11, 2, 9),
        naive(2026, 11, 4, 9),
      ]);
    });
  });

  group('monthly and yearly', () {
    test('the 31st clamps to the last day of shorter months', () {
      const rule = RecurrenceRule(unit: RepeatUnit.month);
      expect(next(naive(2026, 1, 31, 9), rule, naive(2026, 1, 31, 9), 4), [
        naive(2026, 2, 28, 9),
        naive(2026, 3, 31, 9),
        naive(2026, 4, 30, 9),
        naive(2026, 5, 31, 9),
      ]);
    });

    test('last day of month rule', () {
      const rule = RecurrenceRule(unit: RepeatUnit.month, lastDayOfMonth: true);
      expect(next(naive(2026, 1, 15, 9), rule, naive(2026, 1, 1), 4), [
        naive(2026, 1, 31, 9),
        naive(2026, 2, 28, 9),
        naive(2026, 3, 31, 9),
        naive(2026, 4, 30, 9),
      ]);
    });

    test('every 3 months', () {
      const rule = RecurrenceRule(unit: RepeatUnit.month, interval: 3);
      expect(next(naive(2026, 11, 1, 9), rule, naive(2026, 11, 1, 9), 3), [
        naive(2027, 2, 1, 9),
        naive(2027, 5, 1, 9),
        naive(2027, 8, 1, 9),
      ]);
    });

    test('yearly on 29 Feb falls back to 28 Feb in non-leap years', () {
      const rule = RecurrenceRule(unit: RepeatUnit.year);
      expect(next(naive(2028, 2, 29, 9), rule, naive(2028, 2, 29, 9), 4), [
        naive(2029, 2, 28, 9),
        naive(2030, 2, 28, 9),
        naive(2031, 2, 28, 9),
        naive(2032, 2, 29, 9),
      ]);
    });
  });

  group('endings', () {
    final start = naive(2026, 10, 23, 9);

    test('count limits the total including the first', () {
      const rule = RecurrenceRule(unit: RepeatUnit.day, count: 3);
      expect(next(start, rule, naive(2026, 10, 1), 10), [
        naive(2026, 10, 23, 9),
        naive(2026, 10, 24, 9),
        naive(2026, 10, 25, 9),
      ]);
    });

    test('count is respected when asking from the middle of the series', () {
      const rule = RecurrenceRule(unit: RepeatUnit.day, count: 3);
      expect(next(start, rule, start, 10), [
        naive(2026, 10, 24, 9),
        naive(2026, 10, 25, 9),
      ]);
    });

    test('count is respected after a long gap (fast-forward)', () {
      const rule = RecurrenceRule(unit: RepeatUnit.day, count: 3);
      expect(next(start, rule, naive(2028, 1, 1), 10), isEmpty);
    });

    test('count works for weekly rules with several weekdays', () {
      const rule = RecurrenceRule(
        unit: RepeatUnit.week,
        weekdays: {1, 3, 5},
        count: 4,
      );
      expect(next(naive(2026, 10, 21, 7), rule, naive(2026, 10, 21, 6), 10), [
        naive(2026, 10, 21, 7),
        naive(2026, 10, 23, 7),
        naive(2026, 10, 26, 7),
        naive(2026, 10, 28, 7),
      ]);
    });

    test('until is inclusive of the whole last day', () {
      final rule = RecurrenceRule(
        unit: RepeatUnit.day,
        until: naive(2026, 10, 25),
      );
      expect(next(start, rule, start, 10), [
        naive(2026, 10, 24, 9),
        naive(2026, 10, 25, 9),
      ]);
    });

    test('nextAfter is null once the series has ended', () {
      const rule = RecurrenceRule(unit: RepeatUnit.month, count: 2);
      expect(engine.nextAfter(start, rule, naive(2026, 11, 23, 9)), isNull);
    });
  });

  group('fast-forward matches brute force', () {
    final start = naive(2026, 1, 31, 9, 30);
    final rules = <String, RecurrenceRule>{
      'every 15 min': const RecurrenceRule(
        unit: RepeatUnit.minute,
        interval: 15,
      ),
      'every 5 hours': const RecurrenceRule(unit: RepeatUnit.hour, interval: 5),
      'every 3 days': const RecurrenceRule(unit: RepeatUnit.day, interval: 3),
      'weekly': const RecurrenceRule(unit: RepeatUnit.week),
      'every 3 weeks Tue/Sat': const RecurrenceRule(
        unit: RepeatUnit.week,
        interval: 3,
        weekdays: {2, 6},
      ),
      'monthly on 31st': const RecurrenceRule(unit: RepeatUnit.month),
      'every 5 months': const RecurrenceRule(
        unit: RepeatUnit.month,
        interval: 5,
      ),
      'last day monthly': const RecurrenceRule(
        unit: RepeatUnit.month,
        lastDayOfMonth: true,
      ),
      'yearly': const RecurrenceRule(unit: RepeatUnit.year),
      'daily count 400': const RecurrenceRule(unit: RepeatUnit.day, count: 400),
      'weekly M/W/F count 50': const RecurrenceRule(
        unit: RepeatUnit.week,
        weekdays: {1, 3, 5},
        count: 50,
      ),
    };
    final probes = [
      naive(2026, 1, 1),
      naive(2026, 2, 1, 9, 30),
      naive(2026, 6, 15, 12, 7),
      naive(2027, 3, 14, 2, 30),
      naive(2028, 2, 29, 23, 59),
      naive(2031, 12, 31, 9, 30),
    ];

    for (final entry in rules.entries) {
      test(entry.key, () {
        final from = start.subtract(const Duration(minutes: 1));
        for (final probe in probes) {
          final expected = engine
              .occurrencesAfter(start, entry.value, from)
              .where((t) => t.isAfter(probe))
              .take(4)
              .toList();
          final actual = engine
              .occurrencesAfter(start, entry.value, probe)
              .take(4)
              .toList();
          expect(actual, expected, reason: 'after $probe');
        }
      });
    }
  });
}
