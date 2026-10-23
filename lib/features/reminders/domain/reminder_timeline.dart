import 'package:equatable/equatable.dart';

import 'recurrence_engine.dart';
import 'reminder.dart';

/// The occurrence of a reminder that matters right now.
class Due extends Equatable {
  const Due(this.occurrence, {required this.isOverdue});

  /// Naive wall-clock time of the occurrence.
  final DateTime occurrence;

  /// True when the occurrence has already fired and is still unhandled.
  final bool isOverdue;

  @override
  List<Object> get props => [occurrence, isOverdue];
}

/// Which occurrence of [reminder] the user should see or act on at
/// [nowNaive]:
///
/// * the latest occurrence that already fired and is unhandled (overdue), or
/// * otherwise the next upcoming one, or
/// * null when the series has finished.
///
/// Earlier unhandled occurrences of a recurring reminder are superseded by the
/// latest one (they count as missed).
Due? dueOf(
  Reminder reminder,
  DateTime nowNaive, [
  RecurrenceEngine engine = const RecurrenceEngine(),
]) {
  if (reminder.status == ReminderStatus.completed) return null;

  final after =
      reminder.resolvedThrough ??
      reminder.start.subtract(const Duration(minutes: 1));

  DateTime? latestPast;
  for (final occurrence in engine.occurrencesAfter(
    reminder.start,
    reminder.recurrence,
    after,
  )) {
    if (occurrence.isAfter(nowNaive)) {
      return latestPast != null
          ? Due(latestPast, isOverdue: true)
          : Due(occurrence, isOverdue: false);
    }
    latestPast = occurrence;
  }
  return latestPast == null ? null : Due(latestPast, isOverdue: true);
}
