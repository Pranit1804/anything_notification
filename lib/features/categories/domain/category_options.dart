import 'category.dart';

/// Accent colors a category can use (ARGB).
const categoryColors = <int>[
  0xFF5B5BD6, // indigo
  0xFF1971C2, // blue
  0xFF0B7285, // teal
  0xFF2F9E44, // green
  0xFFF08C00, // amber
  0xFFE8590C, // orange
  0xFFE03131, // red
  0xFFD6336C, // rose
  0xFF9C36B5, // violet
  0xFF495057, // slate
];

/// Icons a category can use. The UI maps each key to an `IconData`.
const categoryIconKeys = <String>[
  'person',
  'work',
  'health',
  'bills',
  'home',
  'shopping',
  'school',
  'fitness',
  'travel',
  'pets',
  'food',
  'celebration',
  'savings',
  'car',
  'medication',
  'event',
];

/// Categories every new install starts with. They are ordinary categories:
/// editable and deletable.
const defaultCategories = <CategoryDraft>[
  CategoryDraft(name: 'Personal', colorValue: 0xFF5B5BD6, iconKey: 'person'),
  CategoryDraft(name: 'Work', colorValue: 0xFF0B7285, iconKey: 'work'),
  CategoryDraft(name: 'Health', colorValue: 0xFFD6336C, iconKey: 'health'),
  CategoryDraft(name: 'Bills', colorValue: 0xFFE8590C, iconKey: 'bills'),
];
