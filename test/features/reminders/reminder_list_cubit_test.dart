import 'package:anything_notification/core/time/naive_time.dart';
import 'package:anything_notification/features/reminders/domain/recurrence_rule.dart';
import 'package:anything_notification/features/reminders/domain/reminder.dart';
import 'package:anything_notification/features/reminders/domain/reminder_grouping.dart';
import 'package:anything_notification/features/reminders/presentation/cubit/reminder_list_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_dependencies.dart';

void main() {
  late TestEnvironment env;

  setUp(() async => env = await TestEnvironment.create());
  tearDown(() => env.dispose());

  Future<ReminderListCubit> loaded() async {
    final cubit = ReminderListCubit(
      repository: env.repository,
      categories: env.categories,
      service: env.service,
      clock: env.dependencies.clock,
      tick: const Duration(days: 1),
    );
    addTearDown(cubit.close);
    await cubit.stream.firstWhere((s) => s.loaded);
    return cubit;
  }

  Future<Reminder> add(String title, DateTime start, {RecurrenceRule? rule}) =>
      env.service.create(
        ReminderDraft(title: title, start: start, recurrence: rule),
      );

  List<String> titles(ReminderListState state) => [
    for (final group in state.reminders.groups)
      for (final item in group.items) item.reminder.title,
  ];

  test('loads and groups what is in the database', () async {
    await add('Later', naive(2026, 10, 25, 9));
    await add('Soon', naive(2026, 10, 23, 18));

    final cubit = await loaded();

    expect(titles(cubit.state), ['Soon', 'Later']);
    expect(cubit.state.reminders.groups.map((g) => g.section), [
      ReminderSection.today,
      ReminderSection.thisWeek,
    ]);
  });

  test('is empty but loaded for an empty database', () async {
    final cubit = await loaded();

    expect(cubit.state.loaded, isTrue);
    expect(cubit.state.reminders.isEmpty, isTrue);
  });

  test('follows later changes in the database', () async {
    final cubit = await loaded();

    final next = cubit.stream.firstWhere((s) => titles(s).contains('New'));
    await add('New', naive(2026, 10, 23, 18));

    expect(titles(await next), ['New']);
  });

  test('markDone completes a one-time reminder', () async {
    final reminder = await add('Once', naive(2026, 10, 23, 18));
    final cubit = await loaded();

    final gone = cubit.stream.firstWhere((s) => titles(s).isEmpty);
    await cubit.markDone(reminder);
    await gone;

    expect(
      (await env.repository.getById(reminder.id))!.status,
      ReminderStatus.completed,
    );
  });

  test('markDone moves a recurring reminder to its next occurrence', () async {
    final reminder = await add(
      'Daily',
      naive(2026, 10, 23, 18),
      rule: const RecurrenceRule(unit: RepeatUnit.day),
    );
    final cubit = await loaded();

    await cubit.markDone(reminder);
    final state = await cubit.stream.firstWhere(
      (s) =>
          s.reminders.groups.any((g) => g.section == ReminderSection.tomorrow),
    );

    expect(titles(state), ['Daily']);
  });

  test('delete hides the reminder at once and offers undo', () async {
    final reminder = await add('Gone soon', naive(2026, 10, 23, 18));
    final cubit = await loaded();

    final future = cubit.delete(reminder);

    // Before the database has even finished.
    expect(titles(cubit.state), isEmpty);
    expect(cubit.state.deleted, reminder);
    expect(cubit.state.deleteSerial, 1);
    await future;
    expect(await env.repository.getById(reminder.id), isNull);
  });

  test('undoDelete brings the reminder back', () async {
    final reminder = await add('Oops', naive(2026, 10, 23, 18));
    final cubit = await loaded();
    await cubit.delete(reminder);

    final back = cubit.stream.firstWhere((s) => titles(s).contains('Oops'));
    await cubit.undoDelete();

    expect(titles(await back), ['Oops']);
    expect(cubit.state.deleted, isNull);
    expect(await env.repository.getById(reminder.id), reminder);
  });

  test('deleteHandled forgets the undo offer', () async {
    final reminder = await add('Gone', naive(2026, 10, 23, 18));
    final cubit = await loaded();
    await cubit.delete(reminder);

    cubit.deleteHandled();

    expect(cubit.state.deleted, isNull);
  });

  test('each delete gets its own serial, even for equal reminders', () async {
    final a = await add('Same', naive(2026, 10, 23, 18));
    final cubit = await loaded();
    await cubit.delete(a);
    final first = cubit.state.deleteSerial;

    final b = await add('Same', naive(2026, 10, 23, 18));
    await cubit.stream.firstWhere((s) => titles(s).contains('Same'));
    await cubit.delete(b);

    expect(cubit.state.deleteSerial, greaterThan(first));
  });

  group('category filter', () {
    Future<void> seed() async {
      final all = await env.categories.getAll();
      await env.service.create(
        ReminderDraft(
          title: 'Standup',
          start: naive(2026, 10, 23, 18),
          categoryId: all[1].id, // Work
        ),
      );
      await env.service.create(
        ReminderDraft(
          title: 'Gym',
          start: naive(2026, 10, 23, 19),
          categoryId: all[2].id, // Health
        ),
      );
      await env.service.create(
        ReminderDraft(title: 'Loose end', start: naive(2026, 10, 23, 20)),
      );
    }

    test('shows everything by default and exposes the categories', () async {
      await seed();

      final cubit = await loaded();
      await cubit.stream.firstWhere((s) => s.categories.isNotEmpty);

      expect(titles(cubit.state), ['Standup', 'Gym', 'Loose end']);
      expect(cubit.state.categories, hasLength(4));
      expect(cubit.state.hasReminders, isTrue);
    });

    test('narrows the list to one category', () async {
      await seed();
      final cubit = await loaded();
      final work = (await env.categories.getAll())[1];

      cubit.setFilter(work.id);

      expect(titles(cubit.state), ['Standup']);
      // Other reminders still exist, so the filter chips stay available.
      expect(cubit.state.hasReminders, isTrue);
    });

    test('clearing the filter shows everything again', () async {
      await seed();
      final cubit = await loaded();
      cubit.setFilter((await env.categories.getAll())[1].id);

      cubit.setFilter(null);

      expect(titles(cubit.state), ['Standup', 'Gym', 'Loose end']);
    });

    test('a filter on a deleted category resets itself', () async {
      await seed();
      final cubit = await loaded();
      final work = (await env.categories.getAll())[1];
      cubit.setFilter(work.id);

      final reset = cubit.stream.firstWhere((s) => s.filterCategoryId == null);
      await env.categories.delete(work.id);
      await reset;

      // The Work reminder lost its category and is visible again.
      expect(titles(cubit.state), contains('Standup'));
    });
  });
}
