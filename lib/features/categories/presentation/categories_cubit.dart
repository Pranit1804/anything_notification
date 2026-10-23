import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/category_repository.dart';
import '../domain/category.dart';

class CategoriesState extends Equatable {
  const CategoriesState({this.loaded = false, this.categories = const []});

  final bool loaded;
  final List<Category> categories;

  Category? byId(int? id) {
    if (id == null) return null;
    for (final category in categories) {
      if (category.id == id) return category;
    }
    return null;
  }

  @override
  List<Object> get props => [loaded, categories];
}

/// The user's categories, kept in step with the database.
class CategoriesCubit extends Cubit<CategoriesState> {
  CategoriesCubit(this._repository) : super(const CategoriesState()) {
    _subscription = _repository.watchAll().listen(
      (categories) =>
          emit(CategoriesState(loaded: true, categories: categories)),
    );
  }

  final CategoryRepository _repository;
  late final StreamSubscription<List<Category>> _subscription;

  /// Creates the category, or updates it when [existing] is given. Returns
  /// the saved category.
  Future<Category> save(CategoryDraft draft, {Category? existing}) async {
    if (existing == null) return _repository.create(draft);

    final updated = existing.copyWith(
      name: draft.name,
      colorValue: draft.colorValue,
      iconKey: draft.iconKey,
    );
    await _repository.update(updated);
    return updated;
  }

  Future<void> delete(Category category) => _repository.delete(category.id);

  @override
  Future<void> close() {
    unawaited(_subscription.cancel());
    return super.close();
  }
}
