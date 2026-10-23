import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/time/naive_time.dart';
import '../../../core/time/zoned_clock.dart';
import '../../categories/data/category_repository.dart';
import '../../categories/domain/category.dart';
import '../../reminders/domain/occurrence_outcome.dart';
import '../data/history_repository.dart';
import '../domain/history_entry.dart';

class HistoryState extends Equatable {
  const HistoryState({
    this.loaded = false,
    this.entries = const [],
    this.categories = const [],
    this.outcomeFilter,
    this.categoryFilter,
    this.doneLast7Days = 0,
  });

  final bool loaded;

  /// Everything, newest first, before filtering.
  final List<HistoryEntry> entries;
  final List<Category> categories;

  /// Null shows every outcome.
  final OccurrenceOutcome? outcomeFilter;

  /// Null shows every category.
  final int? categoryFilter;
  final int doneLast7Days;

  List<HistoryEntry> get visible => [
    for (final entry in entries)
      if ((outcomeFilter == null || entry.outcome == outcomeFilter) &&
          (categoryFilter == null || entry.categoryId == categoryFilter))
        entry,
  ];

  HistoryState copyWith({
    bool? loaded,
    List<HistoryEntry>? entries,
    List<Category>? categories,
    OccurrenceOutcome? outcomeFilter,
    bool clearOutcome = false,
    int? categoryFilter,
    bool clearCategory = false,
    int? doneLast7Days,
  }) => HistoryState(
    loaded: loaded ?? this.loaded,
    entries: entries ?? this.entries,
    categories: categories ?? this.categories,
    outcomeFilter: clearOutcome ? null : (outcomeFilter ?? this.outcomeFilter),
    categoryFilter: clearCategory
        ? null
        : (categoryFilter ?? this.categoryFilter),
    doneLast7Days: doneLast7Days ?? this.doneLast7Days,
  );

  @override
  List<Object?> get props => [
    loaded,
    entries,
    categories,
    outcomeFilter,
    categoryFilter,
    doneLast7Days,
  ];
}

class HistoryCubit extends Cubit<HistoryState> {
  HistoryCubit({
    required HistoryRepository history,
    required CategoryRepository categories,
    required this._clock,
  }) : _history = history,
       super(const HistoryState()) {
    _entries = history.watchAll().listen((entries) {
      emit(
        state.copyWith(
          loaded: true,
          entries: entries,
          doneLast7Days: _countDone(entries),
        ),
      );
    });
    _categories = categories.watchAll().listen((all) {
      final filter = state.categoryFilter;
      final stale = filter != null && !all.any((c) => c.id == filter);
      emit(state.copyWith(categories: all, clearCategory: stale));
    });
  }

  final HistoryRepository _history;
  final ZonedClock _clock;
  late final StreamSubscription<List<HistoryEntry>> _entries;
  late final StreamSubscription<List<Category>> _categories;

  int _countDone(List<HistoryEntry> entries) {
    final since = _clock.nowInstant.subtract(const Duration(days: 7));
    return entries
        .where(
          (e) => e.outcome == OccurrenceOutcome.done && e.at.isAfter(since),
        )
        .length;
  }

  void setOutcomeFilter(OccurrenceOutcome? outcome) => emit(
    state.copyWith(outcomeFilter: outcome, clearOutcome: outcome == null),
  );

  void setCategoryFilter(int? categoryId) => emit(
    state.copyWith(
      categoryFilter: categoryId,
      clearCategory: categoryId == null,
    ),
  );

  Future<void> clear() => _history.clear();

  /// Splits [entries] (newest first) into local calendar days, newest first.
  /// The day is when the entry was recorded, in the device's time zone.
  List<(DateTime day, List<HistoryEntry> entries)> byDay(
    List<HistoryEntry> entries,
  ) {
    final days = <DateTime, List<HistoryEntry>>{};
    for (final entry in entries) {
      final day = dateOnly(_clock.toNaive(entry.at));
      days.putIfAbsent(day, () => []).add(entry);
    }
    return [for (final e in days.entries) (e.key, e.value)];
  }

  @override
  Future<void> close() {
    unawaited(_entries.cancel());
    unawaited(_categories.cancel());
    return super.close();
  }
}
