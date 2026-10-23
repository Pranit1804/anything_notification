import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/time/naive_time.dart';
import '../../../../core/time/zoned_clock.dart';
import '../../application/reminder_service.dart';
import '../../domain/recurrence_engine.dart';
import '../../domain/recurrence_rule.dart';
import '../../domain/reminder.dart';

enum EditorError { titleMissing, startInPast, invalidRepeat }

/// Values to start a new reminder with (from quick-add's "More options").
class ReminderPrefill {
  const ReminderPrefill({
    this.title = '',
    this.start,
    this.recurrence,
    this.categoryId,
  });

  final String title;
  final DateTime? start;
  final RecurrenceRule? recurrence;
  final int? categoryId;
}

class ReminderEditorState extends Equatable {
  const ReminderEditorState({
    required this.title,
    required this.note,
    required this.start,
    required this.recurrence,
    required this.paused,
    this.categoryId,
    this.existing,
    this.error,
    this.saving = false,
    this.saved = false,
  });

  final String title;
  final String note;

  /// Naive wall-clock time of the first occurrence.
  final DateTime start;
  final RecurrenceRule? recurrence;
  final bool paused;

  /// Null for no category.
  final int? categoryId;

  /// The reminder being edited, or null when creating.
  final Reminder? existing;
  final EditorError? error;
  final bool saving;
  final bool saved;

  bool get isNew => existing == null;

  ReminderEditorState copyWith({
    String? title,
    String? note,
    DateTime? start,
    RecurrenceRule? recurrence,
    bool clearRecurrence = false,
    bool? paused,
    int? categoryId,
    bool clearCategory = false,
    EditorError? error,
    bool clearError = false,
    bool? saving,
    bool? saved,
  }) => ReminderEditorState(
    title: title ?? this.title,
    note: note ?? this.note,
    start: start ?? this.start,
    recurrence: clearRecurrence ? null : (recurrence ?? this.recurrence),
    paused: paused ?? this.paused,
    categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
    existing: existing,
    error: clearError ? null : (error ?? this.error),
    saving: saving ?? this.saving,
    saved: saved ?? this.saved,
  );

  @override
  List<Object?> get props => [
    title,
    note,
    start,
    recurrence,
    paused,
    categoryId,
    existing,
    error,
    saving,
    saved,
  ];
}

class ReminderEditorCubit extends Cubit<ReminderEditorState> {
  ReminderEditorCubit({
    required ReminderService service,
    required ZonedClock clock,
    Reminder? existing,
    ReminderPrefill? prefill,
    this.engine = const RecurrenceEngine(),
    // The initial state needs `clock`, which a private formal can't provide.
    // ignore: prefer_initializing_formals
  }) : _service = service,
       _clock = clock,
       super(
         existing == null
             ? ReminderEditorState(
                 title: prefill?.title ?? '',
                 note: '',
                 start: prefill?.start ?? _defaultStart(clock.nowNaive),
                 recurrence: prefill?.recurrence,
                 paused: false,
                 categoryId: prefill?.categoryId,
               )
             : ReminderEditorState(
                 title: existing.title,
                 note: existing.note ?? '',
                 start: existing.start,
                 recurrence: existing.recurrence,
                 paused: existing.status == ReminderStatus.paused,
                 categoryId: existing.categoryId,
                 existing: existing,
               ),
       );

  final ReminderService _service;
  final ZonedClock _clock;
  final RecurrenceEngine engine;

  /// The next full hour: a sensible default for "remind me later".
  static DateTime _defaultStart(DateTime now) =>
      naive(now.year, now.month, now.day, now.hour + 1);

  void titleChanged(String value) =>
      emit(state.copyWith(title: value, clearError: true));

  void noteChanged(String value) => emit(state.copyWith(note: value));

  void dateChanged(DateTime date) => emit(
    state.copyWith(
      start: naive(
        date.year,
        date.month,
        date.day,
        state.start.hour,
        state.start.minute,
      ),
      clearError: true,
    ),
  );

  void timeChanged(int hour, int minute) => emit(
    state.copyWith(
      start: naive(
        state.start.year,
        state.start.month,
        state.start.day,
        hour,
        minute,
      ),
      clearError: true,
    ),
  );

  void recurrenceChanged(RecurrenceRule? rule) => emit(
    state.copyWith(
      recurrence: rule,
      clearRecurrence: rule == null,
      clearError: true,
    ),
  );

  void pausedChanged(bool value) => emit(state.copyWith(paused: value));

  /// Picks a category, or none with null.
  void categoryChanged(int? id) =>
      emit(state.copyWith(categoryId: id, clearCategory: id == null));

  /// The next [count] occurrences from now, for the "Next:" preview.
  List<DateTime> preview({int count = 2}) => engine
      .occurrencesAfter(state.start, state.recurrence, _clock.nowNaive)
      .take(count)
      .toList();

  /// Validates and saves. Returns whether it was saved; on failure
  /// [ReminderEditorState.error] says why.
  Future<bool> save() async {
    if (state.saving) return false;

    final title = state.title.trim();
    if (title.isEmpty) {
      emit(state.copyWith(error: EditorError.titleMissing));
      return false;
    }
    if (state.recurrence?.validate() != null) {
      emit(state.copyWith(error: EditorError.invalidRepeat));
      return false;
    }

    final existing = state.existing;
    final startChanged = existing == null || existing.start != state.start;
    if (startChanged && !state.start.isAfter(_clock.nowNaive)) {
      emit(state.copyWith(error: EditorError.startInPast));
      return false;
    }

    emit(state.copyWith(saving: true, clearError: true));
    final note = state.note.trim().isEmpty ? null : state.note.trim();
    final status = state.paused ? ReminderStatus.paused : ReminderStatus.active;

    if (existing == null) {
      await _service.create(
        ReminderDraft(
          title: title,
          note: note,
          start: state.start,
          recurrence: state.recurrence,
          categoryId: state.categoryId,
          status: status,
        ),
      );
    } else {
      // A new schedule starts fresh: what was handled under the old one no
      // longer applies.
      final rescheduled =
          existing.start != state.start ||
          existing.recurrence != state.recurrence;
      await _service.update(
        existing.copyWith(
          title: title,
          note: note,
          clearNote: note == null,
          start: state.start,
          recurrence: state.recurrence,
          clearRecurrence: state.recurrence == null,
          categoryId: state.categoryId,
          clearCategory: state.categoryId == null,
          status: status,
          clearResolvedThrough: rescheduled,
          clearSnoozedUntil: rescheduled,
        ),
      );
    }
    emit(state.copyWith(saving: false, saved: true));
    return true;
  }
}
