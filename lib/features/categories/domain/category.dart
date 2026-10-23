import 'package:equatable/equatable.dart';

class Category extends Equatable {
  const Category({
    required this.id,
    required this.name,
    required this.colorValue,
    required this.iconKey,
    required this.sortOrder,
  });

  final int id;
  final String name;

  /// ARGB value of the category's accent color.
  final int colorValue;

  /// One of [categoryIconKeys]; mapped to an icon by the UI.
  final String iconKey;
  final int sortOrder;

  Category copyWith({String? name, int? colorValue, String? iconKey}) =>
      Category(
        id: id,
        name: name ?? this.name,
        colorValue: colorValue ?? this.colorValue,
        iconKey: iconKey ?? this.iconKey,
        sortOrder: sortOrder,
      );

  @override
  List<Object> get props => [id, name, colorValue, iconKey, sortOrder];
}

/// Values for a category that has not been saved yet.
class CategoryDraft extends Equatable {
  const CategoryDraft({
    required this.name,
    required this.colorValue,
    required this.iconKey,
  });

  final String name;
  final int colorValue;
  final String iconKey;

  @override
  List<Object> get props => [name, colorValue, iconKey];
}
