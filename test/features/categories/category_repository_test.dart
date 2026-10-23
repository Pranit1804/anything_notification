import 'package:anything_notification/core/time/naive_time.dart';
import 'package:anything_notification/features/categories/domain/category.dart';
import 'package:anything_notification/features/categories/domain/category_options.dart';
import 'package:anything_notification/features/reminders/domain/reminder.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_dependencies.dart';

void main() {
  late TestEnvironment env;

  setUp(() async => env = await TestEnvironment.create());
  tearDown(() => env.dispose());

  const draft = CategoryDraft(
    name: 'Garden',
    colorValue: 0xFF2F9E44,
    iconKey: 'home',
  );

  test(
    'a fresh database starts with the default categories, in order',
    () async {
      final all = await env.categories.getAll();

      expect(all.map((c) => c.name), ['Personal', 'Work', 'Health', 'Bills']);
      expect(all.map((c) => c.sortOrder), [0, 1, 2, 3]);
      expect(
        all.map((c) => c.colorValue),
        defaultCategories.map((c) => c.colorValue),
      );
    },
  );

  test('create appends after the existing ones', () async {
    final created = await env.categories.create(draft);

    expect(created.name, 'Garden');
    expect(created.sortOrder, 4);
    expect((await env.categories.getAll()).last, created);
  });

  test('update changes name, color and icon but not the position', () async {
    final created = await env.categories.create(draft);

    await env.categories.update(
      created.copyWith(name: 'Yard', colorValue: 0xFF1971C2, iconKey: 'pets'),
    );

    final loaded = (await env.categories.getById(created.id))!;
    expect(loaded.name, 'Yard');
    expect(loaded.colorValue, 0xFF1971C2);
    expect(loaded.iconKey, 'pets');
    expect(loaded.sortOrder, created.sortOrder);
  });

  test('delete removes the category and clears it from reminders', () async {
    final category = await env.categories.create(draft);
    final other = (await env.categories.getAll()).first;
    final inCategory = await env.service.create(
      ReminderDraft(
        title: 'Mow',
        start: naive(2026, 10, 24, 9),
        categoryId: category.id,
      ),
    );
    final elsewhere = await env.service.create(
      ReminderDraft(
        title: 'Call mom',
        start: naive(2026, 10, 24, 9),
        categoryId: other.id,
      ),
    );

    await env.categories.delete(category.id);

    expect(await env.categories.getById(category.id), isNull);
    expect((await env.repository.getById(inCategory.id))!.categoryId, isNull);
    expect((await env.repository.getById(elsewhere.id))!.categoryId, other.id);
  });

  test('watchAll re-emits when a category changes', () async {
    final stream = env.categories.watchAll();
    expect((await stream.first).length, 4);

    final next = expectLater(
      stream.skip(1),
      emits(predicate<List<Category>>((l) => l.length == 5)),
    );
    await env.categories.create(draft);
    await next;
  });

  test('the palette and icon lists have no duplicates', () {
    expect(categoryColors.toSet(), hasLength(categoryColors.length));
    expect(categoryIconKeys.toSet(), hasLength(categoryIconKeys.length));
    for (final seed in defaultCategories) {
      expect(categoryColors, contains(seed.colorValue));
      expect(categoryIconKeys, contains(seed.iconKey));
    }
  });
}
