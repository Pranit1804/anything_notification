import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import '../domain/reminder.dart';

/// Persistence for reminders.
class ReminderRepository {
  ReminderRepository(this._db);

  final AppDatabase _db;

  Stream<List<Reminder>> watchAll() {
    final query = _db.select(_db.reminders)
      ..orderBy([(t) => OrderingTerm.asc(t.startLocal)]);
    return query.watch().map((rows) => rows.map(_toDomain).toList());
  }

  Future<List<Reminder>> getAll() async {
    final rows = await _db.select(_db.reminders).get();
    return rows.map(_toDomain).toList();
  }

  Future<Reminder?> getById(int id) async {
    final row = await (_db.select(
      _db.reminders,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  Future<Reminder> create(ReminderDraft draft, {required DateTime now}) async {
    final row = await _db
        .into(_db.reminders)
        .insertReturning(
          RemindersCompanion.insert(
            title: draft.title,
            note: Value(draft.note),
            startLocal: draft.start,
            recurrence: Value(draft.recurrence),
            categoryId: Value(draft.categoryId),
            delivery: draft.delivery,
            status: draft.status,
            createdAt: now,
          ),
        );
    return _toDomain(row);
  }

  /// Saves [reminder] and returns what was stored.
  ///
  /// The revision tells armed notifications whether their content is stale,
  /// so it only needs to change when something shown in a notification does.
  /// Bookkeeping updates (an occurrence handled, a snooze) pass
  /// `bumpRevision: false` to avoid re-arming alarms that did not change.
  Future<Reminder> update(Reminder reminder, {bool bumpRevision = true}) async {
    final next = bumpRevision
        ? reminder.copyWith(revision: reminder.revision + 1)
        : reminder;
    await (_db.update(
      _db.reminders,
    )..where((t) => t.id.equals(reminder.id))).write(_toCompanion(next));
    return next;
  }

  Future<void> delete(int id) =>
      (_db.delete(_db.reminders)..where((t) => t.id.equals(id))).go();

  /// Re-inserts a deleted reminder under its original id (Undo).
  Future<void> restore(Reminder reminder, {required DateTime createdAt}) async {
    await _db
        .into(_db.reminders)
        .insert(
          _toCompanion(
            reminder,
          ).copyWith(id: Value(reminder.id), createdAt: Value(createdAt)),
          mode: InsertMode.insertOrReplace,
        );
  }

  /// Makes watchers re-query after another isolate wrote to the database
  /// (for example a notification action handled in the background).
  void notifyExternalChange() =>
      _db.markTablesUpdated([_db.reminders, _db.occurrences, _db.categories]);

  Reminder _toDomain(ReminderRow row) => Reminder(
    id: row.id,
    title: row.title,
    note: row.note,
    start: row.startLocal,
    recurrence: row.recurrence,
    categoryId: row.categoryId,
    delivery: row.delivery,
    status: row.status,
    resolvedThrough: row.resolvedThroughLocal,
    snoozedUntil: row.snoozedUntil?.toUtc(),
    revision: row.revision,
  );

  RemindersCompanion _toCompanion(Reminder r) => RemindersCompanion(
    title: Value(r.title),
    note: Value(r.note),
    startLocal: Value(r.start),
    recurrence: Value(r.recurrence),
    categoryId: Value(r.categoryId),
    delivery: Value(r.delivery),
    status: Value(r.status),
    resolvedThroughLocal: Value(r.resolvedThrough),
    snoozedUntil: Value(r.snoozedUntil),
    revision: Value(r.revision),
  );
}
