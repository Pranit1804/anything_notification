/// "Naive" wall-clock times.
///
/// A reminder fires at a wall-clock time ("9:00 AM") that stays the same when
/// the user travels. Recurrence math therefore works on naive date-times: a
/// [DateTime] built with [DateTime.utc] purely so that arithmetic never hits a
/// DST jump. The UTC flag carries no meaning here; no time zone is attached.
/// Converting to a real instant happens only at scheduling time (see
/// `ZonedClock`).
DateTime naive(int year, int month, int day, [int hour = 0, int minute = 0]) =>
    DateTime.utc(year, month, day, hour, minute);

/// Copies the wall-clock components of [value] into a naive date-time.
DateTime toNaive(DateTime value) => DateTime.utc(
  value.year,
  value.month,
  value.day,
  value.hour,
  value.minute,
  value.second,
  value.millisecond,
);

/// Number of days in [month] (1-12) of [year].
int daysInMonth(int year, int month) => DateTime.utc(year, month + 1, 0).day;

/// Midnight (naive) of the day containing [value].
DateTime dateOnly(DateTime value) =>
    DateTime.utc(value.year, value.month, value.day);
