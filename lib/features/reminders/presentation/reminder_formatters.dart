import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n_context.dart';
import '../../../core/time/naive_time.dart';
import '../domain/recurrence_rule.dart';

/// "Fri 23 Oct".
String formatDate(BuildContext context, DateTime naiveTime) => DateFormat(
  'EEE d MMM',
  Localizations.localeOf(context).toString(),
).format(naiveTime);

/// "6:00 PM" or "18:00", following the system 12/24-hour setting.
String formatTime(BuildContext context, DateTime naiveTime) =>
    MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay(hour: naiveTime.hour, minute: naiveTime.minute),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );

/// "Today, 6:00 PM" / "Tomorrow, 9:00 AM" / "Sat 25 Oct, 9:00 AM".
String formatWhen(
  BuildContext context,
  DateTime occurrence, {
  required DateTime nowNaive,
}) {
  final l10n = context.l10n;
  final time = formatTime(context, occurrence);
  final days = dateOnly(occurrence).difference(dateOnly(nowNaive)).inDays;
  return switch (days) {
    0 => l10n.whenToday(time),
    1 => l10n.whenTomorrow(time),
    _ => l10n.whenOnDate(formatDate(context, occurrence), time),
  };
}

/// Weekday names for ISO weekdays (Monday = 1), abbreviated.
String weekdayName(BuildContext context, int isoWeekday) {
  // 2024-01-01 was a Monday.
  final date = DateTime.utc(2024, 1, isoWeekday);
  return DateFormat.E(Localizations.localeOf(context).toString()).format(date);
}

/// "Every 2 weeks on Mon, Wed, until Fri 31 Dec", or "Doesn't repeat".
String describeRecurrence(
  BuildContext context,
  RecurrenceRule? rule,
  DateTime start,
) {
  final l10n = context.l10n;
  if (rule == null) return l10n.repeatNone;

  var text = switch (rule.unit) {
    RepeatUnit.minute => l10n.repeatEveryMinutes(rule.interval),
    RepeatUnit.hour => l10n.repeatEveryHours(rule.interval),
    RepeatUnit.day => l10n.repeatEveryDays(rule.interval),
    RepeatUnit.week => l10n.repeatEveryWeeks(rule.interval),
    RepeatUnit.month => l10n.repeatEveryMonths(rule.interval),
    RepeatUnit.year => l10n.repeatEveryYears(rule.interval),
  };

  if (rule.unit == RepeatUnit.week && rule.weekdays.isNotEmpty) {
    final days = (rule.weekdays.toList()..sort())
        .map((d) => weekdayName(context, d))
        .join(', ');
    text = l10n.repeatOnDays(text, days);
  } else if (rule.unit == RepeatUnit.month && rule.lastDayOfMonth) {
    text = l10n.repeatOnLastDay(text);
  }

  if (rule.until != null) {
    text = l10n.repeatUntil(text, formatDate(context, rule.until!));
  } else if (rule.count != null) {
    text = l10n.repeatTimes(text, rule.count!);
  }
  return text;
}
