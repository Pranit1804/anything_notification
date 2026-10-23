import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import '../../reminders/domain/occurrence_outcome.dart';
import '../domain/history_entry.dart';

class HistoryRepository {
  HistoryRepository(this._db);

  final AppDatabase _db;

  Future<void> log({
    required int reminderId,
    required String title,
    required DateTime scheduledLocal,
    required OccurrenceOutcome outcome,
    required DateTime at,
    int? categoryId,
    String? categoryName,
    int? categoryColor,
  }) async {
    // A missed occurrence is recorded once, even if two isolates settle at
    // the same time.
    if (outcome == OccurrenceOutcome.missed) {
      final existing =
          await (_db.select(_db.occurrences)..where(
                (t) =>
                    t.reminderId.equals(reminderId) &
                    t.outcome.equalsValue(OccurrenceOutcome.missed) &
                    t.scheduledLocal.equals(
                      scheduledLocal.millisecondsSinceEpoch,
                    ),
              ))
              .get();
      if (existing.isNotEmpty) return;
    }
    await _db
        .into(_db.occurrences)
        .insert(
          OccurrencesCompanion.insert(
            reminderId: reminderId,
            title: title,
            scheduledLocal: scheduledLocal,
            outcome: outcome,
            at: at,
            categoryId: Value(categoryId),
            categoryName: Value(categoryName),
            categoryColor: Value(categoryColor),
          ),
        );
  }

  /// Newest first.
  Stream<List<HistoryEntry>> watchAll() {
    final query = _db.select(_db.occurrences)
      ..orderBy([
        (t) => OrderingTerm.desc(t.at),
        (t) => OrderingTerm.desc(t.id),
      ]);
    return query.watch().map((rows) => rows.map(_toDomain).toList());
  }

  /// Oldest first.
  Future<List<HistoryEntry>> entriesFor(int reminderId) async {
    final rows =
        await (_db.select(_db.occurrences)
              ..where((t) => t.reminderId.equals(reminderId))
              ..orderBy([(t) => OrderingTerm.asc(t.id)]))
            .get();
    return rows.map(_toDomain).toList();
  }

  Future<void> clear() => _db.delete(_db.occurrences).go();

  /// Removes entries recorded before [cutoff] (UTC).
  Future<int> deleteOlderThan(DateTime cutoff) => (_db.delete(
    _db.occurrences,
  )..where((t) => t.at.isSmallerThanValue(cutoff))).go();

  HistoryEntry _toDomain(OccurrenceRow row) => HistoryEntry(
    id: row.id,
    reminderId: row.reminderId,
    title: row.title,
    scheduledLocal: row.scheduledLocal,
    outcome: row.outcome,
    at: row.at.toUtc(),
    categoryId: row.categoryId,
    categoryName: row.categoryName,
    categoryColor: row.categoryColor,
  );
}
