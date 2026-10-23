import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../../features/categories/domain/category_options.dart';
import '../../features/reminders/domain/occurrence_outcome.dart';
import '../../features/reminders/domain/recurrence_rule.dart';
import '../../features/reminders/domain/reminder.dart';
import 'converters.dart';

part 'app_database.g.dart';

@DataClassName('CategoryRow')
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  IntColumn get colorValue => integer()();
  TextColumn get iconKey => text()();
  IntColumn get sortOrder => integer()();
}

@DataClassName('ReminderRow')
class Reminders extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get note => text().nullable()();

  /// Naive wall-clock time of the first occurrence.
  IntColumn get startLocal => integer().map(const NaiveDateTimeConverter())();
  TextColumn get recurrence =>
      text().map(const RecurrenceRuleConverter()).nullable()();

  /// Not a foreign key: deleting a category clears this by hand.
  IntColumn get categoryId => integer().nullable()();
  IntColumn get delivery => intEnum<DeliveryMode>()();
  IntColumn get status => intEnum<ReminderStatus>()();
  IntColumn get resolvedThroughLocal =>
      integer().map(const NaiveDateTimeConverter()).nullable()();
  DateTimeColumn get snoozedUntil => dateTime().nullable()();
  IntColumn get revision => integer().withDefault(const Constant(1))();
  DateTimeColumn get createdAt => dateTime()();
}

/// History of what happened to occurrences. Kept after a reminder or category
/// is deleted, so the title and category are copied here.
@DataClassName('OccurrenceRow')
class Occurrences extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get reminderId => integer()();
  TextColumn get title => text()();
  IntColumn get scheduledLocal =>
      integer().map(const NaiveDateTimeConverter())();
  IntColumn get outcome => intEnum<OccurrenceOutcome>()();
  DateTimeColumn get at => dateTime()();
  IntColumn get categoryId => integer().nullable()();
  TextColumn get categoryName => text().nullable()();
  IntColumn get categoryColor => integer().nullable()();
}

@DriftDatabase(tables: [Categories, Reminders, Occurrences])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  /// Opens the on-device database.
  ///
  /// The app, notification actions and the boot worker each run in their own
  /// isolate with their own connection to the same file, so WAL mode and a
  /// busy timeout keep concurrent writers from failing.
  AppDatabase.open()
    : super(
        driftDatabase(
          name: 'anything_notification',
          native: DriftNativeOptions(
            setup: (db) {
              // The timeout must come first: the app and the background worker
              // open the database together at startup, and the next pragma can
              // meet the other connection.
              db.execute('PRAGMA busy_timeout = 5000;');
              try {
                db.execute('PRAGMA journal_mode = WAL;');
              } on Object {
                // WAL is remembered by the database file, so another connection
                // having it locked right now just means it is (or will be) set.
              }
            },
          ),
        ),
      );

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _seedDefaultCategories();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        // v2: categories, and the category link on reminders and history.
        await m.createTable(categories);
        await m.addColumn(reminders, reminders.categoryId);
        await m.addColumn(occurrences, occurrences.categoryId);
        await m.addColumn(occurrences, occurrences.categoryName);
        await m.addColumn(occurrences, occurrences.categoryColor);
        await _seedDefaultCategories();
      }
    },
  );

  Future<void> _seedDefaultCategories() async {
    var order = 0;
    for (final category in defaultCategories) {
      await into(categories).insert(
        CategoriesCompanion.insert(
          name: category.name,
          colorValue: category.colorValue,
          iconKey: category.iconKey,
          sortOrder: order++,
        ),
      );
    }
  }
}
