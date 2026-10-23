import 'package:equatable/equatable.dart';

import '../../reminders/domain/occurrence_outcome.dart';

/// One line of history: what happened to one occurrence of a reminder.
///
/// Title and category are copied when the entry is written, so history stays
/// readable after the reminder or its category is deleted or renamed.
class HistoryEntry extends Equatable {
  const HistoryEntry({
    required this.id,
    required this.reminderId,
    required this.title,
    required this.scheduledLocal,
    required this.outcome,
    required this.at,
    this.categoryId,
    this.categoryName,
    this.categoryColor,
  });

  final int id;
  final int reminderId;
  final String title;

  /// Naive wall-clock time the occurrence was scheduled for.
  final DateTime scheduledLocal;
  final OccurrenceOutcome outcome;

  /// When it was recorded (UTC instant).
  final DateTime at;
  final int? categoryId;
  final String? categoryName;
  final int? categoryColor;

  @override
  List<Object?> get props => [
    id,
    reminderId,
    title,
    scheduledLocal,
    outcome,
    at,
    categoryId,
    categoryName,
    categoryColor,
  ];
}
