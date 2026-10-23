import 'dart:convert';

import 'package:equatable/equatable.dart';

import '../../../core/time/zoned_clock.dart';
import '../../categories/domain/category.dart';
import 'recurrence_engine.dart';
import 'recurrence_rule.dart';
import 'reminder.dart';
import 'reminder_timeline.dart';

enum AlarmKind { occurrence, snooze }

/// One notification that should be armed with the system.
class PlannedAlarm extends Equatable {
  const PlannedAlarm({
    required this.id,
    required this.reminderId,
    required this.kind,
    required this.occurrence,
    required this.fireAt,
    required this.title,
    required this.body,
    required this.delivery,
    required this.revision,
    this.categoryName,
    this.categoryColor,
  });

  /// Deterministic 31-bit notification id (see [AlarmPlanner.notificationId]).
  final int id;
  final int reminderId;
  final AlarmKind kind;

  /// The occurrence (naive) this alarm is about.
  final DateTime occurrence;

  /// When to fire, as a UTC instant.
  final DateTime fireAt;
  final String title;
  final String? body;
  final DeliveryMode delivery;
  final int revision;

  /// Shown as the notification's sub-text, with [categoryColor] as its accent.
  final String? categoryName;
  final int? categoryColor;

  PlannedAlarm withId(int newId) => PlannedAlarm(
    id: newId,
    reminderId: reminderId,
    kind: kind,
    occurrence: occurrence,
    fireAt: fireAt,
    title: title,
    body: body,
    delivery: delivery,
    revision: revision,
    categoryName: categoryName,
    categoryColor: categoryColor,
  );

  @override
  List<Object?> get props => [
    id,
    reminderId,
    kind,
    occurrence,
    fireAt,
    title,
    body,
    delivery,
    revision,
    categoryName,
    categoryColor,
  ];
}

/// Decides which notifications to arm. Pure: no plugin, no storage.
///
/// Rolling window (docs/PRD.md section 5.6): each reminder keeps its next
/// occurrence armed no matter how far away it is, plus further occurrences
/// within [horizon], up to [perReminderLimit] ([frequentLimit] for sub-hour
/// intervals). The whole plan is capped at [globalLimit] alarms, soonest
/// first, because Android limits an app to roughly 500 concurrent alarms.
class AlarmPlanner {
  const AlarmPlanner({
    this.engine = const RecurrenceEngine(),
    this.perReminderLimit = 12,
    this.frequentLimit = 24,
    this.horizon = const Duration(days: 14),
    this.globalLimit = 400,
  });

  final RecurrenceEngine engine;
  final int perReminderLimit;
  final int frequentLimit;
  final Duration horizon;
  final int globalLimit;

  /// [categories] (by id) supplies the name and color shown on notifications.
  List<PlannedAlarm> plan(
    Iterable<Reminder> reminders,
    ZonedClock clock, {
    Map<int, Category> categories = const {},
  }) {
    final now = clock.nowInstant;
    final nowNaive = clock.nowNaive;
    final horizonEnd = nowNaive.add(horizon);

    final firsts = <PlannedAlarm>[];
    final extras = <PlannedAlarm>[];

    final active =
        reminders.where((r) => r.status == ReminderStatus.active).toList()
          ..sort((a, b) => a.id.compareTo(b.id));

    for (final reminder in active) {
      final snoozedUntil = reminder.snoozedUntil;
      if (snoozedUntil != null && snoozedUntil.isAfter(now)) {
        final due = dueOf(reminder, nowNaive, engine);
        if (due != null) {
          firsts.add(
            _alarm(
              reminder,
              AlarmKind.snooze,
              due.occurrence,
              snoozedUntil,
              categories,
            ),
          );
        }
      }

      final rule = reminder.recurrence;
      final limit = _isFrequent(rule) ? frequentLimit : perReminderLimit;
      final resolved = reminder.resolvedThrough;
      final after = resolved != null && resolved.isAfter(nowNaive)
          ? resolved
          : nowNaive;

      var armed = 0;
      for (final occurrence in engine.occurrencesAfter(
        reminder.start,
        rule,
        after,
      )) {
        // The first upcoming occurrence is always armed; later ones only
        // while they stay inside the window.
        if (armed > 0 && (armed >= limit || occurrence.isAfter(horizonEnd))) {
          break;
        }
        final fireAt = clock.toInstant(occurrence);
        if (!fireAt.isAfter(now)) continue;
        final alarm = _alarm(
          reminder,
          AlarmKind.occurrence,
          occurrence,
          fireAt,
          categories,
        );
        (armed == 0 ? firsts : extras).add(alarm);
        armed++;
      }
    }

    int byTime(PlannedAlarm a, PlannedAlarm b) {
      final byFire = a.fireAt.compareTo(b.fireAt);
      return byFire != 0 ? byFire : a.reminderId.compareTo(b.reminderId);
    }

    firsts.sort(byTime);
    extras.sort(byTime);
    final chosen = [...firsts, ...extras].take(globalLimit).toList()
      ..sort(byTime);
    return _withUniqueIds(chosen);
  }

  bool _isFrequent(RecurrenceRule? rule) =>
      rule != null && rule.unit == RepeatUnit.minute && rule.interval < 60;

  PlannedAlarm _alarm(
    Reminder reminder,
    AlarmKind kind,
    DateTime occurrence,
    DateTime fireAt,
    Map<int, Category> categories,
  ) {
    final category = categories[reminder.categoryId];
    return PlannedAlarm(
      id: notificationId(reminder.id, kind, occurrence),
      reminderId: reminder.id,
      kind: kind,
      occurrence: occurrence,
      fireAt: fireAt,
      title: reminder.title,
      body: reminder.note,
      delivery: reminder.delivery,
      revision: reminder.revision,
      categoryName: category?.name,
      categoryColor: category?.colorValue,
    );
  }

  /// Resolves the (very unlikely) id collisions deterministically, so every
  /// isolate that plans the same data arrives at the same ids.
  List<PlannedAlarm> _withUniqueIds(List<PlannedAlarm> alarms) {
    final used = <int>{};
    return [
      for (final alarm in alarms)
        () {
          var id = alarm.id;
          while (!used.add(id)) {
            id = (id + 1) & 0x7fffffff;
          }
          return id == alarm.id ? alarm : alarm.withId(id);
        }(),
    ];
  }

  /// Stable 31-bit notification id for an occurrence: the same inputs always
  /// give the same id, so re-arming replaces rather than duplicates.
  static int notificationId(
    int reminderId,
    AlarmKind kind,
    DateTime occurrence,
  ) {
    final key = '$reminderId|${kind.name}|${occurrence.millisecondsSinceEpoch}';
    // 32-bit FNV-1a.
    var hash = 0x811c9dc5;
    for (final byte in utf8.encode(key)) {
      hash ^= byte;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash & 0x7fffffff;
  }
}
