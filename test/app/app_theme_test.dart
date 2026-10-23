import 'package:anything_notification/app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('builds Material 3 light and dark themes from the seed color', () {
    final light = AppTheme.light();
    final dark = AppTheme.dark();

    expect(light.useMaterial3, isTrue);
    expect(light.colorScheme.brightness, Brightness.light);
    expect(dark.colorScheme.brightness, Brightness.dark);
  });

  test('prefers a provided dynamic color scheme over the seed', () {
    final dynamicScheme = ColorScheme.fromSeed(seedColor: Colors.teal);

    expect(
      AppTheme.light(dynamicScheme).colorScheme.primary,
      dynamicScheme.primary,
    );
    expect(AppTheme.light().colorScheme.primary, isNot(dynamicScheme.primary));
  });

  test('uses the bundled font family', () {
    expect(
      AppTheme.light().textTheme.bodyMedium?.fontFamily,
      AppTheme.fontFamily,
    );
  });
}
