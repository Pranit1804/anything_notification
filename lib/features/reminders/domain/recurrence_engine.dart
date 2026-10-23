import 'dart:math' as math;

import '../../../core/time/naive_time.dart';
import 'recurrence_rule.dart';

/// Computes occurrences of a reminder. Pure Dart: works on naive wall-clock
/// times (see `naive_time.dart`), no time zones, no clock.
class RecurrenceEngine {
  const RecurrenceEngine();

  /// Occurrences strictly after [after], in order, lazily.
  ///
  /// [start] is the first occurrence. A null [rule] means a one-time reminder.
  /// The sequence is infinite for open-ended rules: always bound it with
  /// `take` / `takeWhile`.
  Iterable<DateTime> occurrencesAfter(
    DateTime start,
    RecurrenceRule? rule,
    DateTime after,
  ) sync* {
    if (rule == null) {
      if (start.isAfter(after)) yield start;
      return;
    }

    final untilEnd = rule.until == null
        ? null
        : DateTime.utc(
            rule.until!.year,
            rule.until!.month,
            rule.until!.day,
            23,
            59,
            59,
          );

    for (final (index, time) in _generate(start, rule, after)) {
      if (rule.count != null && index >= rule.count!) return;
      if (untilEnd != null && time.isAfter(untilEnd)) return;
      if (time.isAfter(after)) yield time;
    }
  }

  /// The first occurrence strictly after [after], or null when the series has
  /// ended.
  DateTime? nextAfter(DateTime start, RecurrenceRule? rule, DateTime after) {
    final it = occurrencesAfter(start, rule, after).iterator;
    return it.moveNext() ? it.current : null;
  }

  /// Yields `(index, time)` pairs starting at or before the first occurrence
  /// after [after]. The index is only reliable when `rule.count != null`
  /// (that case never fast-forwards where the index could be lost).
  Iterable<(int, DateTime)> _generate(
    DateTime start,
    RecurrenceRule rule,
    DateTime after,
  ) {
    return switch (rule.unit) {
      RepeatUnit.minute ||
      RepeatUnit.hour ||
      RepeatUnit.day => _fixedStep(start, rule, after),
      RepeatUnit.week => _weekly(start, rule, after),
      RepeatUnit.month || RepeatUnit.year => _calendarStep(start, rule, after),
    };
  }

  Iterable<(int, DateTime)> _fixedStep(
    DateTime start,
    RecurrenceRule rule,
    DateTime after,
  ) sync* {
    final stepMinutes = switch (rule.unit) {
      RepeatUnit.minute => rule.interval,
      RepeatUnit.hour => rule.interval * 60,
      _ => rule.interval * 24 * 60,
    };
    // `DateTime.utc` normalises overflowing days, so day steps are exact.
    DateTime at(int n) => rule.unit == RepeatUnit.day
        ? DateTime.utc(
            start.year,
            start.month,
            start.day + n * rule.interval,
            start.hour,
            start.minute,
          )
        : start.add(Duration(minutes: n * stepMinutes));

    final estimate = after.difference(start).inMinutes ~/ stepMinutes;
    for (var n = math.max(0, estimate - 1); ; n++) {
      yield (n, at(n));
    }
  }

  Iterable<(int, DateTime)> _weekly(
    DateTime start,
    RecurrenceRule rule,
    DateTime after,
  ) sync* {
    final days =
        (rule.weekdays.isEmpty ? {start.weekday} : rule.weekdays).toList()
          ..sort();
    // Weeks are Monday-based and anchored on the week containing [start].
    final firstMonday = DateTime.utc(
      start.year,
      start.month,
      start.day - (start.weekday - 1),
    );

    // Counting occurrences needs every one from the start; otherwise skip
    // ahead to just before [after].
    var week = 0;
    if (rule.count == null) {
      final weeksBetween = after.difference(firstMonday).inDays ~/ 7;
      week = math.max(0, weeksBetween ~/ rule.interval - 1) * rule.interval;
    }

    var index = 0;
    while (true) {
      for (final day in days) {
        final time = DateTime.utc(
          firstMonday.year,
          firstMonday.month,
          firstMonday.day + 7 * week + day - 1,
          start.hour,
          start.minute,
        );
        if (time.isBefore(start)) continue;
        yield (index++, time);
      }
      week += rule.interval;
    }
  }

  Iterable<(int, DateTime)> _calendarStep(
    DateTime start,
    RecurrenceRule rule,
    DateTime after,
  ) sync* {
    final monthStep = rule.unit == RepeatUnit.year
        ? rule.interval * 12
        : rule.interval;
    final startMonths = start.year * 12 + start.month - 1;

    DateTime at(int n) {
      final months = startMonths + n * monthStep;
      final year = months ~/ 12;
      final month = months % 12 + 1;
      final maxDay = daysInMonth(year, month);
      final day = rule.unit == RepeatUnit.month && rule.lastDayOfMonth
          ? maxDay
          : math.min(start.day, maxDay);
      return DateTime.utc(year, month, day, start.hour, start.minute);
    }

    final afterMonths = after.year * 12 + after.month - 1;
    final estimate = (afterMonths - startMonths) ~/ monthStep;
    for (var n = math.max(0, estimate - 1); ; n++) {
      yield (n, at(n));
    }
  }
}
