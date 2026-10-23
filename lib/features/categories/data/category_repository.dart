import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import '../domain/category.dart';

class CategoryRepository {
  CategoryRepository(this._db);

  final AppDatabase _db;

  SimpleSelectStatement<$CategoriesTable, CategoryRow> _ordered() =>
      _db.select(_db.categories)..orderBy([
        (t) => OrderingTerm.asc(t.sortOrder),
        (t) => OrderingTerm.asc(t.id),
      ]);

  Stream<List<Category>> watchAll() =>
      _ordered().watch().map((rows) => rows.map(_toDomain).toList());

  Future<List<Category>> getAll() async =>
      (await _ordered().get()).map(_toDomain).toList();

  Future<Category?> getById(int id) async {
    final row = await (_db.select(
      _db.categories,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  /// Adds a category after the existing ones.
  Future<Category> create(CategoryDraft draft) async {
    final last = await (_db.selectOnly(
      _db.categories,
    )..addColumns([_db.categories.sortOrder.max()])).getSingle();
    final next = (last.read(_db.categories.sortOrder.max()) ?? -1) + 1;

    final row = await _db
        .into(_db.categories)
        .insertReturning(
          CategoriesCompanion.insert(
            name: draft.name,
            colorValue: draft.colorValue,
            iconKey: draft.iconKey,
            sortOrder: next,
          ),
        );
    return _toDomain(row);
  }

  Future<void> update(Category category) =>
      (_db.update(
        _db.categories,
      )..where((t) => t.id.equals(category.id))).write(
        CategoriesCompanion(
          name: Value(category.name),
          colorValue: Value(category.colorValue),
          iconKey: Value(category.iconKey),
        ),
      );

  /// Deletes the category; its reminders simply lose their category. History
  /// keeps its own copy of the name and color.
  Future<void> delete(int id) => _db.transaction(() async {
    await (_db.update(_db.reminders)..where((t) => t.categoryId.equals(id)))
        .write(const RemindersCompanion(categoryId: Value(null)));
    await (_db.delete(_db.categories)..where((t) => t.id.equals(id))).go();
  });

  Category _toDomain(CategoryRow row) => Category(
    id: row.id,
    name: row.name,
    colorValue: row.colorValue,
    iconKey: row.iconKey,
    sortOrder: row.sortOrder,
  );
}
