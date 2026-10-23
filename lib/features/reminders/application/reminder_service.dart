import '../../../core/notifications/alarm_scheduler.dart';
import '../../../core/time/zoned_clock.dart';
import '../../categories/data/category_repository.dart';
import '../../history/data/history_repository.dart';
import '../../settings/domain/reminder_preferences.dart';
import '../data/reminder_repository.dart';
import '../domain/occurrence_outcome.dart';
import '../domain/recurrence_engine.dart';
import '../domain/reminder.dart';

/// The things a user can do to reminders. Each change is saved and then the
/// notifications are brought in line with it.
///
/// Used both by the app and by notification actions running in a background
/// isolate, so it must not depend on any UI.
class ReminderService {
  ReminderService({
    required this.repository,
    required this.history,
    required this.categories,
    required this.preferences,
    required this.scheduler,
    required this.clock,
    this.engine = const RecurrenceEngine(),
  });

  /// Most "missed" entries written in one go: a reminder left for months would
  /// otherwise flood the history.
  static const maxMissedPerRun = 50;

  final ReminderRepository repository;
  final HistoryRepository history;
  final CategoryRepository categories;
  final ReminderPreferences preferences;
  final AlarmScheduler scheduler;
  final ZonedClock clock;
  final RecurrenceEngine engine;

  Future<Reminder> create(ReminderDraft draft) async {
    final reminder = await repository.create(draft, now: clock.nowInstant);
    await scheduler.reconcile();
    return reminder;
  }

  /// Saves an edited reminder. Resuming a paused recurring reminder does not
  /// resurrect the occurrences that passed while it was paused.
  Future<Reminder> update(Reminder reminder) async {
    final previous = await repository.getById(reminder.id);
    final resuming =
        previous != null &&
        previous.status == ReminderStatus.paused &&
        reminder.status == ReminderStatus.active &&
        reminder.isRecurring;

    final saved = await repository.update(
      resuming ? _skippingPassedOccurrences(reminder) : reminder,
    );
    await scheduler.reconcile();
    return saved;
  }

  Future<void> setPaused(Reminder reminder, {required bool paused}) async {
    await update(
      reminder.copyWith(
        status: paused ? ReminderStatus.paused : ReminderStatus.active,
      ),
    );
  }

  Future<void> delete(Reminder reminder) async {
    await repository.delete(reminder.id);
    await scheduler.reconcile();
  }

  /// Puts back a reminder removed by [delete] (Undo).
  Future<void> restore(Reminder reminder) async {
    await repository.restore(reminder, createdAt: clock.nowInstant);
    await scheduler.reconcile();
  }

  /// Marks [occurrence] (naive wall-clock time) done. A one-time reminder, or
  /// the last occurrence of a series, completes the reminder.
  Future<void> markDone(int reminderId, DateTime occurrence) async {
    final reminder = await repository.getById(reminderId);
    if (reminder == null || reminder.status == ReminderStatus.completed) {
      return;
    }

    final previous = reminder.resolvedThrough;
    final resolved = previous != null && previous.isAfter(occurrence)
        ? previous
        : occurrence;
    final hasMore =
        engine.nextAfter(reminder.start, reminder.recurrence, resolved) != null;

    // Earlier occurrences that fired and were never handled were missed.
    if (reminder.isRecurring) {
      await _logMissed(
        reminder,
        _unhandledOccurrences(
          reminder,
        ).takeWhile((o) => o.isBefore(occurrence)).toList(),
        supersededBy: occurrence,
      );
    }
    await _log(reminder, occurrence, OccurrenceOutcome.done);
    await repository.update(
      reminder.copyWith(
        resolvedThrough: resolved,
        clearSnoozedUntil: true,
        status: hasMore ? reminder.status : ReminderStatus.completed,
      ),
      bumpRevision: false,
    );
    await scheduler.dismissShown(reminder.id, occurrence);
    await scheduler.reconcile();
  }

  /// Silences [occurrence] for [duration]; it stays unhandled and a snooze
  /// alarm fires when the time is up.
  Future<void> snooze(
    int reminderId,
    DateTime occurrence,
    Duration duration,
  ) async {
    final reminder = await repository.getById(reminderId);
    if (reminder == null || reminder.status != ReminderStatus.active) return;

    await _log(reminder, occurrence, OccurrenceOutcome.snoozed);
    await repository.update(
      reminder.copyWith(snoozedUntil: clock.nowInstant.add(duration)),
      bumpRevision: false,
    );
    await scheduler.dismissShown(reminder.id, occurrence);
    await scheduler.reconcile();
  }

  /// Records occurrences of recurring reminders that were superseded by a
  /// later one without being handled, then trims old history.
  ///
  /// Safe to call at any time and from several isolates: it only ever moves
  /// forward, and a missed occurrence is never recorded twice.
  Future<void> settleMissed() async {
    for (final reminder in await repository.getAll()) {
      if (reminder.status != ReminderStatus.active || !reminder.isRecurring) {
        continue;
      }
      final fired = _unhandledOccurrences(reminder).toList();
      // The latest one is still awaiting the user (shown as overdue).
      if (fired.length < 2) continue;

      final missed = fired.sublist(0, fired.length - 1);
      await _logMissed(reminder, missed, supersededBy: fired.last);
      await repository.update(
        reminder.copyWith(resolvedThrough: missed.last),
        bumpRevision: false,
      );
    }
    await purgeHistory();
  }

  /// Deletes history older than the retention setting (0 keeps everything).
  Future<void> purgeHistory() async {
    final days = preferences.historyRetentionDays;
    if (days <= 0) return;
    await history.deleteOlderThan(
      clock.nowInstant.subtract(Duration(days: days)),
    );
  }

  /// Occurrences that have already fired and were not handled, oldest first.
  Iterable<DateTime> _unhandledOccurrences(Reminder reminder) {
    final now = clock.nowNaive;
    final after =
        reminder.resolvedThrough ??
        reminder.start.subtract(const Duration(minutes: 1));
    return engine
        .occurrencesAfter(reminder.start, reminder.recurrence, after)
        .takeWhile((o) => !o.isAfter(now));
  }

  Reminder _skippingPassedOccurrences(Reminder reminder) {
    final passed = _unhandledOccurrences(reminder).toList();
    return passed.isEmpty
        ? reminder
        : reminder.copyWith(resolvedThrough: passed.last);
  }

  /// Records [missed] (oldest first). Each became missed when the occurrence
  /// after it fired, so that is the time it is filed under, not when the app
  /// happened to notice; [supersededBy] is what followed the last one.
  Future<void> _logMissed(
    Reminder reminder,
    List<DateTime> missed, {
    required DateTime supersededBy,
  }) async {
    final now = clock.nowInstant;
    final first = missed.length > maxMissedPerRun
        ? missed.length - maxMissedPerRun
        : 0;
    for (var i = first; i < missed.length; i++) {
      final next = i + 1 < missed.length ? missed[i + 1] : supersededBy;
      final became = clock.toInstant(next);
      await _log(
        reminder,
        missed[i],
        OccurrenceOutcome.missed,
        at: became.isAfter(now) ? now : became,
      );
    }
  }

  Future<void> _log(
    Reminder reminder,
    DateTime occurrence,
    OccurrenceOutcome outcome, {
    DateTime? at,
  }) async {
    final categoryId = reminder.categoryId;
    final category = categoryId == null
        ? null
        : await categories.getById(categoryId);
    await history.log(
      reminderId: reminder.id,
      title: reminder.title,
      scheduledLocal: occurrence,
      outcome: outcome,
      at: at ?? clock.nowInstant,
      categoryId: category?.id,
      categoryName: category?.name,
      categoryColor: category?.colorValue,
    );
  }
}
