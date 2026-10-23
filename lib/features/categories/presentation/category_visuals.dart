import 'package:flutter/material.dart';

/// The icon for a category icon key (see `categoryIconKeys`).
IconData categoryIcon(String key) => switch (key) {
  'person' => Icons.person_rounded,
  'work' => Icons.work_rounded,
  'health' => Icons.favorite_rounded,
  'bills' => Icons.receipt_long_rounded,
  'home' => Icons.home_rounded,
  'shopping' => Icons.shopping_cart_rounded,
  'school' => Icons.school_rounded,
  'fitness' => Icons.fitness_center_rounded,
  'travel' => Icons.flight_rounded,
  'pets' => Icons.pets_rounded,
  'food' => Icons.restaurant_rounded,
  'celebration' => Icons.celebration_rounded,
  'savings' => Icons.savings_rounded,
  'car' => Icons.directions_car_rounded,
  'medication' => Icons.medication_rounded,
  'event' => Icons.event_rounded,
  _ => Icons.label_rounded,
};

/// A category's accent as a readable pair of colors for the current theme:
/// the tonal container and the color to draw on it.
class CategoryTones {
  const CategoryTones(this.container, this.onContainer);

  final Color container;
  final Color onContainer;
}

final _tones = <(int, Brightness), CategoryTones>{};

CategoryTones categoryTones(int colorValue, Brightness brightness) {
  return _tones.putIfAbsent((colorValue, brightness), () {
    final scheme = ColorScheme.fromSeed(
      seedColor: Color(colorValue),
      brightness: brightness,
    );
    return CategoryTones(scheme.primaryContainer, scheme.onPrimaryContainer);
  });
}

/// A category's icon in a tonal circle.
class CategoryAvatar extends StatelessWidget {
  const CategoryAvatar({
    super.key,
    required this.colorValue,
    required this.iconKey,
    this.size = 48,
  });

  final int colorValue;
  final String iconKey;
  final double size;

  @override
  Widget build(BuildContext context) {
    final tones = categoryTones(colorValue, Theme.of(context).brightness);
    return DecoratedBox(
      decoration: BoxDecoration(color: tones.container, shape: BoxShape.circle),
      child: SizedBox.square(
        dimension: size,
        child: Icon(
          categoryIcon(iconKey),
          size: size * 0.5,
          color: tones.onContainer,
        ),
      ),
    );
  }
}
