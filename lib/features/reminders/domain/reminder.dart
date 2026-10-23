import 'package:equatable/equatable.dart';

import 'recurrence_rule.dart';

enum ReminderStatus { active, paused, completed }

enum DeliveryMode { standard, sticky, alarm }

class Reminder extends Equatable {
  const Reminder({
    required this.id,
    required this.title,
    this.note,
    required this.start,
    this.recurrence,
    this.categoryId,
    this.delivery = DeliveryMode.standard,
    this.status = ReminderStatus.active,
    this.resolvedThrough,
    this.snoozedUntil,
    this.revision = 1,
  });

  final int id;
  final String title;
  final String? note;

  /// First occurrence, as a naive wall-clock time.
  final DateTime start;

  /// Null for a one-time reminder.
  final RecurrenceRule? recurrence;

  /// Null when the reminder has no category.
  final int? categoryId;
  final DeliveryMode delivery;
  final ReminderStatus status;

  /// Every occurrence at or before this (naive) time has been handled.
  final DateTime? resolvedThrough;

  /// While in the future, a snooze alarm is armed for this instant (UTC).
  final DateTime? snoozedUntil;

  /// Bumped on every change so armed notifications can be told apart from
  /// stale ones.
  final int revision;

  bool get isRecurring => recurrence != null;

  Reminder copyWith({
    String? title,
    String? note,
    bool clearNote = false,
    DateTime? start,
    RecurrenceRule? recurrence,
    bool clearRecurrence = false,
    int? categoryId,
    bool clearCategory = false,
    DeliveryMode? delivery,
    ReminderStatus? status,
    DateTime? resolvedThrough,
    bool clearResolvedThrough = false,
    DateTime? snoozedUntil,
    bool clearSnoozedUntil = false,
    int? revision,
  }) {
    return Reminder(
      id: id,
      title: title ?? this.title,
      note: clearNote ? null : (note ?? this.note),
      start: start ?? this.start,
      recurrence: clearRecurrence ? null : (recurrence ?? this.recurrence),
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      delivery: delivery ?? this.delivery,
      status: status ?? this.status,
      resolvedThrough: clearResolvedThrough
          ? null
          : (resolvedThrough ?? this.resolvedThrough),
      snoozedUntil: clearSnoozedUntil
          ? null
          : (snoozedUntil ?? this.snoozedUntil),
      revision: revision ?? this.revision,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    note,
    start,
    recurrence,
    categoryId,
    delivery,
    status,
    resolvedThrough,
    snoozedUntil,
    revision,
  ];
}

/// Values for a reminder that has not been saved yet.
class ReminderDraft extends Equatable {
  const ReminderDraft({
    required this.title,
    this.note,
    required this.start,
    this.recurrence,
    this.categoryId,
    this.delivery = DeliveryMode.standard,
    this.status = ReminderStatus.active,
  });

  final String title;
  final String? note;
  final DateTime start;
  final RecurrenceRule? recurrence;
  final int? categoryId;
  final DeliveryMode delivery;
  final ReminderStatus status;

  @override
  List<Object?> get props => [
    title,
    note,
    start,
    recurrence,
    categoryId,
    delivery,
    status,
  ];
}
