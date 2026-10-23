import 'package:equatable/equatable.dart';

import '../../../core/time/naive_time.dart';
import 'recurrence_engine.dart';
import 'reminder.dart';
import 'reminder_timeline.dart';

enum ReminderSection { overdue, today, tomorrow, thisWeek, later }

/// A reminder together with what is due for it right now.
class ReminderItem extends Equatable {
  const ReminderItem({
    required this.reminder,
    required this.due,
    this.snoozedUntil,
  });

  final Reminder reminder;
  final Due? due;

  /// Set only while a snooze is still running (UTC instant).
  final DateTime? snoozedUntil;

  @override
  List<Object?> get props => [reminder, due, snoozedUntil];
}

class ReminderGroup extends Equatable {
  const ReminderGroup(this.section, this.items);

  final ReminderSection section;
  final List<ReminderItem> items;

  @override
  List<Object> get props => [section, items];
}

class GroupedReminders extends Equatable {
  const GroupedReminders({this.groups = const [], this.paused = const []});

  /// Only non-empty groups, in display order.
  final List<ReminderGroup> groups;
  final List<ReminderItem> paused;

  bool get isEmpty => groups.isEmpty && paused.isEmpty;

  @override
  List<Object> get props => [groups, paused];
}

/// Splits reminders into the sections shown on the Upcoming screen.
/// Completed reminders and finished series are left out.
GroupedReminders groupReminders(
  Iterable<Reminder> reminders, {
  required DateTime nowNaive,
  required DateTime nowInstant,
  RecurrenceEngine engine = const RecurrenceEngine(),
}) {
  final today = dateOnly(nowNaive);
  final bySection = {
    for (final s in ReminderSection.values) s: <ReminderItem>[],
  };
  final paused = <ReminderItem>[];

  for (final reminder in reminders) {
    if (reminder.status == ReminderStatus.completed) continue;
    final due = dueOf(reminder, nowNaive, engine);
    if (due == null) continue;

    final snoozedUntil = reminder.snoozedUntil;
    final item = ReminderItem(
      reminder: reminder,
      due: due,
      snoozedUntil: snoozedUntil != null && snoozedUntil.isAfter(nowInstant)
          ? snoozedUntil
          : null,
    );

    if (reminder.status == ReminderStatus.paused) {
      paused.add(item);
      continue;
    }

    final daysAway = dateOnly(due.occurrence).difference(today).inDays;
    final section = due.isOverdue
        ? ReminderSection.overdue
        : switch (daysAway) {
            <= 0 => ReminderSection.today,
            1 => ReminderSection.tomorrow,
            < 7 => ReminderSection.thisWeek,
            _ => ReminderSection.later,
          };
    bySection[section]!.add(item);
  }

  int byDue(ReminderItem a, ReminderItem b) =>
      a.due!.occurrence.compareTo(b.due!.occurrence);

  return GroupedReminders(
    groups: [
      for (final section in ReminderSection.values)
        if (bySection[section]!.isNotEmpty)
          ReminderGroup(section, bySection[section]!..sort(byDue)),
    ],
    paused: paused..sort(byDue),
  );
}
