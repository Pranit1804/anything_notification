import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/time/zoned_clock.dart';
import '../../../categories/data/category_repository.dart';
import '../../../categories/domain/category.dart';
import '../../application/reminder_service.dart';
import '../../data/reminder_repository.dart';
import '../../domain/reminder.dart';
import '../../domain/reminder_grouping.dart';
import '../../domain/reminder_timeline.dart';

class ReminderListState extends Equatable {
  const ReminderListState({
    this.loaded = false,
    this.reminders = const GroupedReminders(),
    this.hasReminders = false,
    this.categories = const [],
    this.filterCategoryId,
    this.deleted,
    this.deleteSerial = 0,
  });

  final bool loaded;

  /// What the list shows: all reminders, or only those in [filterCategoryId].
  final GroupedReminders reminders;

  /// Whether there are any reminders at all, ignoring the filter.
  final bool hasReminders;
  final List<Category> categories;

  /// Null shows everything.
  final int? filterCategoryId;

  /// The reminder deleted last, so the UI can offer Undo. [deleteSerial]
  /// changes on every delete, even of equal reminders.
  final Reminder? deleted;
  final int deleteSerial;

  Category? get filterCategory {
    for (final category in categories) {
      if (category.id == filterCategoryId) return category;
    }
    return null;
  }

  ReminderListState copyWith({
    bool? loaded,
    GroupedReminders? reminders,
    bool? hasReminders,
    List<Category>? categories,
    int? filterCategoryId,
    bool clearFilter = false,
    Reminder? deleted,
    bool clearDeleted = false,
    int? deleteSerial,
  }) => ReminderListState(
    loaded: loaded ?? this.loaded,
    reminders: reminders ?? this.reminders,
    hasReminders: hasReminders ?? this.hasReminders,
    categories: categories ?? this.categories,
    filterCategoryId: clearFilter
        ? null
        : (filterCategoryId ?? this.filterCategoryId),
    deleted: clearDeleted ? null : (deleted ?? this.deleted),
    deleteSerial: deleteSerial ?? this.deleteSerial,
  );

  @override
  List<Object?> get props => [
    loaded,
    reminders,
    hasReminders,
    categories,
    filterCategoryId,
    deleted,
    deleteSerial,
  ];
}

/// Feeds the Upcoming screen: watches the database and regroups as time
/// passes.
class ReminderListCubit extends Cubit<ReminderListState> {
  ReminderListCubit({
    required ReminderRepository repository,
    required CategoryRepository categories,
    required this._service,
    required this._clock,
    Duration tick = const Duration(minutes: 1),
  }) : super(const ReminderListState()) {
    _subscription = repository.watchAll().listen((reminders) {
      _reminders = reminders;
      _regroup();
    });
    _categorySubscription = categories.watchAll().listen((all) {
      _categories = all;
      // A filter on a category that was deleted would show nothing.
      final filter = state.filterCategoryId;
      final stale = filter != null && !all.any((c) => c.id == filter);
      if (stale) emit(state.copyWith(clearFilter: true));
      _regroup();
    });
    // Sections depend on the time of day (Today/Overdue boundaries).
    _timer = Timer.periodic(tick, (_) => _regroup());
  }

  final ReminderService _service;
  final ZonedClock _clock;
  late final StreamSubscription<List<Reminder>> _subscription;
  late final StreamSubscription<List<Category>> _categorySubscription;
  late final Timer _timer;

  var _reminders = const <Reminder>[];
  var _categories = const <Category>[];

  /// Hidden right away on delete so a swiped card does not linger while the
  /// database catches up.
  final _hidden = <int>{};

  void _regroup() {
    if (isClosed) return;
    final visible = _reminders.where((r) => !_hidden.contains(r.id)).toList();
    final filter = state.filterCategoryId;
    final nowNaive = _clock.nowNaive;
    final nowInstant = _clock.nowInstant;

    emit(
      state.copyWith(
        loaded: true,
        categories: _categories,
        hasReminders: !groupReminders(
          visible,
          nowNaive: nowNaive,
          nowInstant: nowInstant,
        ).isEmpty,
        reminders: groupReminders(
          filter == null
              ? visible
              : visible.where((r) => r.categoryId == filter),
          nowNaive: nowNaive,
          nowInstant: nowInstant,
        ),
      ),
    );
  }

  /// Shows only reminders in [categoryId], or everything with null.
  void setFilter(int? categoryId) {
    emit(
      state.copyWith(
        filterCategoryId: categoryId,
        clearFilter: categoryId == null,
      ),
    );
    _regroup();
  }

  /// Marks what is currently due for [reminder] as done.
  Future<void> markDone(Reminder reminder) async {
    final due = dueOf(reminder, _clock.nowNaive);
    if (due == null) return;
    await _service.markDone(reminder.id, due.occurrence);
  }

  Future<void> delete(Reminder reminder) async {
    _hidden.add(reminder.id);
    _regroup();
    emit(
      state.copyWith(deleted: reminder, deleteSerial: state.deleteSerial + 1),
    );
    try {
      await _service.delete(reminder);
    } finally {
      _hidden.remove(reminder.id);
    }
  }

  Future<void> undoDelete() async {
    final deleted = state.deleted;
    if (deleted == null) return;
    emit(state.copyWith(clearDeleted: true));
    await _service.restore(deleted);
  }

  /// Call once the Undo offer is gone.
  void deleteHandled() => emit(state.copyWith(clearDeleted: true));

  @override
  Future<void> close() {
    _timer.cancel();
    unawaited(_subscription.cancel());
    unawaited(_categorySubscription.cancel());
    return super.close();
  }
}
