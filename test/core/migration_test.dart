import 'package:anything_notification/core/db/app_database.dart';
import 'package:anything_notification/core/time/naive_time.dart';
import 'package:anything_notification/features/categories/data/category_repository.dart';
import 'package:anything_notification/features/history/data/history_repository.dart';
import 'package:anything_notification/features/reminders/data/reminder_repository.dart';
import 'package:anything_notification/features/reminders/domain/occurrence_outcome.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

/// The database exactly as schema version 1 (M1) created it.
const _v1Schema = '''
CREATE TABLE "occurrences" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "reminder_id" INTEGER NOT NULL, "title" TEXT NOT NULL, "scheduled_local" INTEGER NOT NULL, "outcome" INTEGER NOT NULL, "at" INTEGER NOT NULL);
CREATE TABLE "reminders" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "title" TEXT NOT NULL, "note" TEXT NULL, "start_local" INTEGER NOT NULL, "recurrence" TEXT NULL, "delivery" INTEGER NOT NULL, "status" INTEGER NOT NULL, "resolved_through_local" INTEGER NULL, "snoozed_until" INTEGER NULL, "revision" INTEGER NOT NULL DEFAULT 1, "created_at" INTEGER NOT NULL);
''';

void main() {
  test(
    'upgrading from v1 keeps the data and adds the default categories',
    () async {
      final raw = sqlite3.openInMemory()
        ..execute(_v1Schema)
        ..execute('PRAGMA user_version = 1;')
        ..execute(
          'INSERT INTO reminders (id, title, note, start_local, recurrence, '
          'delivery, status, resolved_through_local, snoozed_until, revision, '
          'created_at) VALUES (7, ?, ?, ?, ?, 0, 0, NULL, NULL, 3, 1792000000)',
          [
            'Pay rent',
            'Landlord',
            naive(2026, 11, 1, 9).millisecondsSinceEpoch,
            '{"u":"month","i":1}',
          ],
        )
        ..execute(
          'INSERT INTO occurrences (reminder_id, title, scheduled_local, '
          'outcome, at) VALUES (7, ?, ?, 0, 1792000100)',
          ['Pay rent', naive(2026, 10, 1, 9).millisecondsSinceEpoch],
        );

      final db = AppDatabase(NativeDatabase.opened(raw));
      addTearDown(db.close);

      // Existing reminder: untouched, and simply without a category.
      final reminder = (await ReminderRepository(db).getById(7))!;
      expect(reminder.title, 'Pay rent');
      expect(reminder.note, 'Landlord');
      expect(reminder.start, naive(2026, 11, 1, 9));
      expect(reminder.recurrence, isNotNull);
      expect(reminder.revision, 3);
      expect(reminder.categoryId, isNull);

      // Existing history: untouched, with no category snapshot.
      final history = (await HistoryRepository(db).entriesFor(7)).single;
      expect(history.outcome, OccurrenceOutcome.done);
      expect(history.scheduledLocal, naive(2026, 10, 1, 9));
      expect(history.categoryName, isNull);

      // New: the default categories.
      final categories = await CategoryRepository(db).getAll();
      expect(categories.map((c) => c.name), [
        'Personal',
        'Work',
        'Health',
        'Bills',
      ]);

      expect(
        raw.select('PRAGMA user_version').first.values.first,
        db.schemaVersion,
      );
    },
  );

  test('a brand-new database is created at the current version with '
      'the defaults', () async {
    final raw = sqlite3.openInMemory();
    final db = AppDatabase(NativeDatabase.opened(raw));
    addTearDown(db.close);

    expect(await CategoryRepository(db).getAll(), hasLength(4));
    expect(
      raw.select('PRAGMA user_version').first.values.first,
      db.schemaVersion,
    );
  });
}
