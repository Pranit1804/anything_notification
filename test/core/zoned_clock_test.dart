import 'package:anything_notification/core/time/naive_time.dart';
import 'package:anything_notification/core/time/zoned_clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

void main() {
  setUpAll(tz_data.initializeTimeZones);

  ZonedClock clockIn(String zone, {DateTime? now}) => ZonedClock(
    now: () => now ?? DateTime.utc(2026, 10, 23, 14),
    location: () => tz.getLocation(zone),
  );

  test('converts the current instant to local wall-clock time', () {
    // 14:00 UTC is 10:00 EDT and 19:30 in Kolkata.
    expect(clockIn('America/New_York').nowNaive, naive(2026, 10, 23, 10));
    expect(clockIn('Asia/Kolkata').nowNaive, naive(2026, 10, 23, 19, 30));
  });

  test('the same wall-clock time maps to different instants per zone', () {
    final wall = naive(2026, 10, 24, 9);

    expect(
      clockIn('America/New_York').toInstant(wall),
      DateTime.utc(2026, 10, 24, 13),
    );
    expect(
      clockIn('Asia/Kolkata').toInstant(wall),
      DateTime.utc(2026, 10, 24, 3, 30),
    );
  });

  test('follows a time zone change without being rebuilt', () {
    var zone = 'America/New_York';
    final clock = ZonedClock(
      now: () => DateTime.utc(2026, 10, 23, 14),
      location: () => tz.getLocation(zone),
    );
    final wall = naive(2026, 10, 24, 9);
    final inNewYork = clock.toInstant(wall);

    zone = 'Asia/Tokyo';

    expect(clock.toInstant(wall), isNot(inNewYork));
    expect(clock.toInstant(wall), DateTime.utc(2026, 10, 24));
  });

  group('DST', () {
    final newYork = clockIn('America/New_York');

    test('a time skipped by spring-forward is shifted by the gap', () {
      // 2027-03-14 02:00 -> 03:00 in New York: 02:30 does not exist.
      expect(
        newYork.toInstant(naive(2027, 3, 14, 2, 30)),
        DateTime.utc(2027, 3, 14, 7, 30), // 03:30 EDT
      );
    });

    test('an ambiguous fall-back time resolves to a single instant', () {
      // 2026-11-01 01:30 happens twice in New York; we must pick one.
      final instant = newYork.toInstant(naive(2026, 11, 1, 1, 30));

      expect([
        DateTime.utc(2026, 11, 1, 5, 30), // first pass (EDT)
        DateTime.utc(2026, 11, 1, 6, 30), // second pass (EST)
      ], contains(instant));
    });

    test('daily 09:00 stays 09:00 local across the change', () {
      final before = newYork.toInstant(naive(2026, 10, 31, 9));
      final after = newYork.toInstant(naive(2026, 11, 2, 9));

      // 09:00 EDT = 13:00Z, 09:00 EST = 14:00Z.
      expect(before, DateTime.utc(2026, 10, 31, 13));
      expect(after, DateTime.utc(2026, 11, 2, 14));
    });
  });
}
