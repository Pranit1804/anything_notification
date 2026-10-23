import 'package:anything_notification/core/time/naive_time.dart';
import 'package:anything_notification/features/quick_add/domain/quick_add_parser.dart';
import 'package:anything_notification/features/reminders/domain/recurrence_rule.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Friday 2026-10-23, 10:00.
  final now = naive(2026, 10, 23, 10);
  const parser = QuickAddParser();

  QuickAddResult parse(String text, {DateTime? at}) =>
      parser.parse(text, now: at ?? now);

  group('PRD appendix examples', () {
    final cases = <String, (String, DateTime?, RecurrenceRule?, String?)>{
      'Call mom tomorrow at 6pm': (
        'Call mom',
        naive(2026, 10, 24, 18),
        null,
        null,
      ),
      'Pay rent every 1st at 9am': (
        'Pay rent',
        naive(2026, 11, 1, 9),
        const RecurrenceRule(unit: RepeatUnit.month),
        null,
      ),
      'Water plants every 2 days': (
        'Water plants',
        naive(2026, 10, 24, 9),
        const RecurrenceRule(unit: RepeatUnit.day, interval: 2),
        null,
      ),
      'Gym every mon wed fri 7am #health': (
        'Gym',
        naive(2026, 10, 26, 7),
        const RecurrenceRule(unit: RepeatUnit.week, weekdays: {1, 3, 5}),
        'health',
      ),
      'Take pills in 30 minutes': (
        'Take pills',
        naive(2026, 10, 23, 10, 30),
        null,
        null,
      ),
      'Standup weekdays 9:30': (
        'Standup',
        naive(2026, 10, 26, 9, 30),
        const RecurrenceRule(unit: RepeatUnit.week, weekdays: {1, 2, 3, 4, 5}),
        null,
      ),
      'Dentist on 12 Nov at 4pm': (
        'Dentist',
        naive(2026, 11, 12, 16),
        null,
        null,
      ),
      "Mom's birthday Dec 3 yearly": (
        "Mom's birthday",
        naive(2026, 12, 3, 9),
        const RecurrenceRule(unit: RepeatUnit.year),
        null,
      ),
      'Buy milk': ('Buy milk', null, null, null),
    };

    for (final entry in cases.entries) {
      test(entry.key, () {
        final (title, start, rule, tag) = entry.value;
        final result = parse(entry.key);

        expect(result.title, title);
        expect(result.start, start);
        expect(result.recurrence, rule);
        expect(result.categoryTag, tag);
      });
    }
  });

  group('times of day', () {
    test('a time later today stays today', () {
      expect(parse('Lunch at 12:30').start, naive(2026, 10, 23, 12, 30));
      expect(parse('Lunch at 12:30').title, 'Lunch');
    });

    test('a time that has passed means tomorrow', () {
      expect(parse('Gym at 7am').start, naive(2026, 10, 24, 7));
    });

    test('understands 12-hour and 24-hour forms', () {
      expect(parse('x 6pm').start, naive(2026, 10, 23, 18));
      expect(parse('x 6:30 pm').start, naive(2026, 10, 23, 18, 30));
      expect(parse('x 6:30pm').start, naive(2026, 10, 23, 18, 30));
      expect(parse('x 18:30').start, naive(2026, 10, 23, 18, 30));
      expect(parse('x 11 p.m.').start, naive(2026, 10, 23, 23));
    });

    test('12am is midnight and 12pm is noon', () {
      expect(parse('x 12am').start, naive(2026, 10, 24, 0));
      expect(parse('x 12pm').start, naive(2026, 10, 23, 12));
    });

    test('noon, midnight and tonight', () {
      expect(parse('Pick up kids at noon').start, naive(2026, 10, 23, 12));
      expect(parse('Pick up kids at noon').title, 'Pick up kids');
      expect(parse('Call at midnight').start, naive(2026, 10, 24, 0));
      expect(parse('Drinks tonight').start, naive(2026, 10, 23, 20));
      expect(parse('Drinks tonight').title, 'Drinks');
    });

    test('a time alone leaves an empty title', () {
      final result = parse('6pm');
      expect(result.title, isEmpty);
      expect(result.start, naive(2026, 10, 23, 18));
    });

    test('an impossible hour is left in the title', () {
      final result = parse('Buy 13pm thing');
      expect(result.start, isNull);
      expect(result.title, 'Buy 13pm thing');
    });
  });

  group('days', () {
    test('tomorrow and day after tomorrow, with the default time', () {
      expect(parse('x tomorrow').start, naive(2026, 10, 24, 9));
      expect(parse('x day after tomorrow').start, naive(2026, 10, 25, 9));
    });

    test('today', () {
      expect(parse('x today 5pm').start, naive(2026, 10, 23, 17));
    });

    test('a weekday that is today still counts when the time is ahead', () {
      // It is Friday 10:00.
      expect(parse('Meeting friday 3pm').start, naive(2026, 10, 23, 15));
    });

    test('a weekday that is today but already past means next week', () {
      expect(parse('Meeting friday 9am').start, naive(2026, 10, 30, 9));
      expect(parse('Meeting friday').start, naive(2026, 10, 30, 9));
    });

    test('other weekdays', () {
      expect(parse('Review next monday').start, naive(2026, 10, 26, 9));
      expect(parse('Review next monday').title, 'Review');
      expect(parse('Dinner on sunday 7pm').start, naive(2026, 10, 25, 19));
      expect(parse('Dinner on sunday 7pm').title, 'Dinner');
    });

    test('calendar dates in either order, with ordinals and years', () {
      expect(parse('x 1st nov').start, naive(2026, 11, 1, 9));
      expect(parse('x nov 12th').start, naive(2026, 11, 12, 9));
      expect(parse('x 3 december 2027').start, naive(2027, 12, 3, 9));
      expect(parse('x 5 of march').start, naive(2027, 3, 5, 9));
    });

    test('a date that already passed this year means next year', () {
      final result = parse('Jan 5 appointment');
      expect(result.start, naive(2027, 1, 5, 9));
      expect(result.title, 'appointment');
    });

    test('today as a date is not pushed to next year', () {
      expect(parse('x oct 23 5pm').start, naive(2026, 10, 23, 17));
    });

    test('"may" is only a month when a day follows', () {
      expect(parse('May 3 dentist').start, naive(2027, 5, 3, 9));
      final result = parse('Pay may');
      expect(result.start, isNull);
      expect(result.title, 'Pay may');
    });
  });

  group('relative times', () {
    test('minutes and hours are exact from now', () {
      expect(parse('x in 45 minutes').start, naive(2026, 10, 23, 10, 45));
      expect(parse('x in an hour').start, naive(2026, 10, 23, 11));
      expect(parse('x in 2 hrs').start, naive(2026, 10, 23, 12));
    });

    test('seconds in "now" are ignored', () {
      final at = DateTime.utc(2026, 10, 23, 10, 0, 40);
      expect(
        parse('x in 30 minutes', at: at).start,
        naive(2026, 10, 23, 10, 30),
      );
    });

    test('days and weeks use the default time', () {
      expect(parse('Call in 2 days').start, naive(2026, 10, 25, 9));
      expect(parse('Check in 1 week').start, naive(2026, 10, 30, 9));
    });
  });

  group('repeats', () {
    test('daily and every day', () {
      final result = parse('Run daily at 6am');
      expect(result.recurrence, const RecurrenceRule(unit: RepeatUnit.day));
      expect(result.start, naive(2026, 10, 24, 6));
      expect(result.title, 'Run');

      expect(
        parse('Wake up 6:30am every day').recurrence,
        const RecurrenceRule(unit: RepeatUnit.day),
      );
    });

    test('every N hours and minutes start one interval from now', () {
      final hours = parse('Drink water every 2 hours');
      expect(
        hours.recurrence,
        const RecurrenceRule(unit: RepeatUnit.hour, interval: 2),
      );
      expect(hours.start, naive(2026, 10, 23, 12));
      expect(hours.title, 'Drink water');

      final minutes = parse('Stretch every 30 minutes');
      expect(minutes.start, naive(2026, 10, 23, 10, 30));
    });

    test('an interval below the minimum is reported, not hidden', () {
      final result = parse('Stretch every 5 minutes');

      expect(result.recurrence!.validate(), isNotNull);
      expect(result.start, naive(2026, 10, 23, 10, 5));
    });

    test('weekdays and weekends', () {
      expect(
        parse('Gym weekends 8am').recurrence,
        const RecurrenceRule(unit: RepeatUnit.week, weekdays: {6, 7}),
      );
      expect(parse('Gym weekends 8am').start, naive(2026, 10, 24, 8));
      expect(
        parse('Email every weekday').recurrence,
        const RecurrenceRule(unit: RepeatUnit.week, weekdays: {1, 2, 3, 4, 5}),
      );
    });

    test('a list of weekdays with commas and "and"', () {
      final result = parse('Class every mon, wed and fri 7am');

      expect(
        result.recurrence,
        const RecurrenceRule(unit: RepeatUnit.week, weekdays: {1, 3, 5}),
      );
      expect(result.title, 'Class');
    });

    test('every friday today still starts today when the time is ahead', () {
      final result = parse('Report every friday 5pm');

      expect(result.start, naive(2026, 10, 23, 17));
      expect(
        result.recurrence,
        const RecurrenceRule(unit: RepeatUnit.week, weekdays: {5}),
      );
    });

    test('weekly, monthly and yearly without a date start tomorrow', () {
      expect(
        parse('Water the plants weekly').recurrence,
        const RecurrenceRule(unit: RepeatUnit.week),
      );
      expect(parse('Water the plants weekly').start, naive(2026, 10, 24, 9));
      expect(
        parse('Rent monthly').recurrence,
        const RecurrenceRule(unit: RepeatUnit.month),
      );
      expect(
        parse('Review yearly').recurrence,
        const RecurrenceRule(unit: RepeatUnit.year),
      );
    });

    test('every 15th: this month if it is still ahead, else next month', () {
      expect(parse('Call mom every 15th').start, naive(2026, 11, 15, 9));
      expect(parse('Call mom every 28th').start, naive(2026, 10, 28, 9));
    });

    test('a repeat keeps an explicit date as its start', () {
      final result = parse('Anniversary 20 nov yearly');

      expect(result.start, naive(2026, 11, 20, 9));
      expect(result.recurrence, const RecurrenceRule(unit: RepeatUnit.year));
    });
  });

  group('category tag', () {
    test('is taken out and lower-cased', () {
      final result = parse('Buy milk #Groceries');

      expect(result.categoryTag, 'groceries');
      expect(result.title, 'Buy milk');
      expect(result.start, isNull);
    });

    test('can come first', () {
      final result = parse('#work standup tomorrow 9am');

      expect(result.categoryTag, 'work');
      expect(result.title, 'standup');
      expect(result.start, naive(2026, 10, 24, 9));
    });

    test('a # inside a word is not a tag', () {
      expect(parse('C#sharp lesson').categoryTag, isNull);
    });
  });

  group('title cleanup', () {
    test('ignores case but keeps the title as typed', () {
      final result = parse('CALL MOM TOMORROW AT 6PM');

      expect(result.title, 'CALL MOM');
      expect(result.start, naive(2026, 10, 24, 18));
    });

    test('drops stray punctuation and extra spaces', () {
      expect(parse('Call mom,  tomorrow at 6pm.').title, 'Call mom');
      expect(parse('  Call   mom   tomorrow  ').title, 'Call mom');
    });

    test('leaves numbers that are not times alone', () {
      final result = parse('Buy 2 milk');

      expect(result.title, 'Buy 2 milk');
      expect(result.start, isNull);
    });

    test('empty and whitespace input', () {
      expect(parse('').title, isEmpty);
      expect(parse('   ').start, isNull);
    });

    test('a NUL character in the input cannot confuse it', () {
      expect(parse('Call\u0000 mom tomorrow').title, 'Call mom');
    });
  });

  group('configuration', () {
    test('the default time is configurable', () {
      const evening = QuickAddParser(defaultHour: 18, defaultMinute: 30);

      expect(
        evening.parser('x tomorrow', now).start,
        naive(2026, 10, 24, 18, 30),
      );
    });
  });
}

extension on QuickAddParser {
  QuickAddResult parser(String text, DateTime now) => parse(text, now: now);
}
