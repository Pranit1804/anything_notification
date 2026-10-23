import 'package:timezone/timezone.dart' as tz;

import 'naive_time.dart' as naive_time;

/// The bridge between real instants and the naive wall-clock times that
/// reminders are stored in.
///
/// The location is read lazily on every call so a time zone change (see
/// `TimeZoneService`) takes effect without rebuilding anything.
class ZonedClock {
  ZonedClock({DateTime Function()? now, tz.Location Function()? location})
    : _now = now ?? DateTime.now,
      _location = location ?? (() => tz.local);

  final DateTime Function() _now;
  final tz.Location Function() _location;

  /// The current instant, in UTC.
  DateTime get nowInstant => _now().toUtc();

  /// The current wall-clock time in the active time zone.
  DateTime get nowNaive => toNaive(nowInstant);

  /// The instant (UTC) at which [naive] occurs in the active time zone.
  ///
  /// A wall-clock time skipped by a DST jump is shifted forward by the length
  /// of the gap (e.g. 02:30 becomes 03:30 when clocks go 02:00 -> 03:00).
  DateTime toInstant(DateTime naive) {
    return tz.TZDateTime(
      _location(),
      naive.year,
      naive.month,
      naive.day,
      naive.hour,
      naive.minute,
      naive.second,
      naive.millisecond,
    ).toUtc();
  }

  /// The wall-clock time in the active time zone at [instant].
  DateTime toNaive(DateTime instant) =>
      naive_time.toNaive(tz.TZDateTime.from(instant, _location()));
}
