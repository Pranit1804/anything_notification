import 'package:anything_notification/core/time/naive_time.dart';
import 'package:anything_notification/features/reminders/domain/recurrence_rule.dart';
import 'package:anything_notification/features/reminders/domain/reminder.dart';
import 'package:anything_notification/features/reminders/presentation/cubit/reminder_editor_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_dependencies.dart';

void main() {
  late TestEnvironment env;

  setUp(() async => env = await TestEnvironment.create());
  tearDown(() => env.dispose());

  ReminderEditorCubit cubit({Reminder? existing}) {
    final c = ReminderEditorCubit(
      service: env.service,
      clock: env.dependencies.clock,
      existing: existing,
    );
    addTearDown(c.close);
    return c;
  }

  group('new reminder', () {
    test('starts at the next full hour', () {
      expect(cubit().state.start, naive(2026, 10, 23, 11));
    });

    test('needs a title', () async {
      final c = cubit()..titleChanged('   ');

      expect(await c.save(), isFalse);
      expect(c.state.error, EditorError.titleMissing);
      expect(await env.repository.getAll(), isEmpty);
    });

    test('cannot start in the past', () async {
      final c = cubit()
        ..titleChanged('Call mom')
        ..dateChanged(naive(2026, 10, 22))
        ..timeChanged(9, 0);

      expect(await c.save(), isFalse);
      expect(c.state.error, EditorError.startInPast);
    });

    test('rejects an invalid repeat', () async {
      final c = cubit()
        ..titleChanged('Stretch')
        ..recurrenceChanged(
          const RecurrenceRule(unit: RepeatUnit.minute, interval: 5),
        );

      expect(await c.save(), isFalse);
      expect(c.state.error, EditorError.invalidRepeat);
    });

    test('editing a field clears the error', () async {
      final c = cubit();
      await c.save();
      expect(c.state.error, isNotNull);

      c.titleChanged('Call mom');

      expect(c.state.error, isNull);
    });

    test('saves a trimmed title and note', () async {
      final c = cubit()
        ..titleChanged('  Call mom ')
        ..noteChanged('  about the trip ')
        ..recurrenceChanged(const RecurrenceRule(unit: RepeatUnit.week));

      expect(await c.save(), isTrue);

      final saved = (await env.repository.getAll()).single;
      expect(saved.title, 'Call mom');
      expect(saved.note, 'about the trip');
      expect(saved.recurrence, const RecurrenceRule(unit: RepeatUnit.week));
      expect(saved.start, naive(2026, 10, 23, 11));
      expect(c.state.saved, isTrue);
    });

    test('an empty note is stored as no note', () async {
      final c = cubit()
        ..titleChanged('Call mom')
        ..noteChanged('   ');

      await c.save();

      expect((await env.repository.getAll()).single.note, isNull);
    });

    test('can be saved paused', () async {
      final c = cubit()
        ..titleChanged('Later')
        ..pausedChanged(true);

      await c.save();

      expect(
        (await env.repository.getAll()).single.status,
        ReminderStatus.paused,
      );
    });
  });

  group('editing', () {
    Future<Reminder> existing({
      DateTime? start,
      RecurrenceRule? recurrence,
      DateTime? resolvedThrough,
    }) async {
      final created = await env.service.create(
        ReminderDraft(
          title: 'Original',
          start: start ?? naive(2026, 10, 24, 9),
          recurrence: recurrence,
        ),
      );
      return resolvedThrough == null
          ? created
          : env.service.update(
              created.copyWith(resolvedThrough: resolvedThrough),
            );
    }

    test('prefills from the reminder', () async {
      final reminder = await existing(
        recurrence: const RecurrenceRule(unit: RepeatUnit.day),
      );

      final state = cubit(existing: reminder).state;

      expect(state.title, 'Original');
      expect(state.isNew, isFalse);
      expect(state.recurrence, const RecurrenceRule(unit: RepeatUnit.day));
    });

    test('an unchanged start in the past is still saveable', () async {
      final reminder = await existing(
        start: naive(2026, 10, 20, 9),
        recurrence: const RecurrenceRule(unit: RepeatUnit.day),
      );
      final c = cubit(existing: reminder)..titleChanged('Renamed');

      expect(await c.save(), isTrue);

      final saved = (await env.repository.getAll()).single;
      expect(saved.title, 'Renamed');
      expect(saved.start, naive(2026, 10, 20, 9));
    });

    test('keeps what was handled when the schedule is untouched', () async {
      final reminder = await existing(
        recurrence: const RecurrenceRule(unit: RepeatUnit.day),
        resolvedThrough: naive(2026, 10, 24, 9),
      );
      final c = cubit(existing: reminder)..titleChanged('Renamed');

      await c.save();

      expect(
        (await env.repository.getAll()).single.resolvedThrough,
        naive(2026, 10, 24, 9),
      );
    });

    test('a new schedule starts fresh', () async {
      final reminder = await existing(
        recurrence: const RecurrenceRule(unit: RepeatUnit.day),
        resolvedThrough: naive(2026, 10, 24, 9),
      );
      final c = cubit(existing: reminder)
        ..recurrenceChanged(const RecurrenceRule(unit: RepeatUnit.week));

      await c.save();

      final saved = (await env.repository.getAll()).single;
      expect(saved.resolvedThrough, isNull);
      expect(saved.snoozedUntil, isNull);
    });

    test('removing the repeat makes it one-time again', () async {
      final reminder = await existing(
        recurrence: const RecurrenceRule(unit: RepeatUnit.day),
      );
      final c = cubit(existing: reminder)..recurrenceChanged(null);

      await c.save();

      expect((await env.repository.getAll()).single.recurrence, isNull);
    });

    test('moving the start to the past is rejected', () async {
      final reminder = await existing();
      final c = cubit(existing: reminder)..dateChanged(naive(2026, 10, 1));

      expect(await c.save(), isFalse);
      expect(c.state.error, EditorError.startInPast);
    });
  });

  group('preview', () {
    test('shows the next two occurrences', () {
      final c = cubit()
        ..recurrenceChanged(const RecurrenceRule(unit: RepeatUnit.day));

      expect(c.preview(), [naive(2026, 10, 23, 11), naive(2026, 10, 24, 11)]);
    });

    test('is a single occurrence for a one-time reminder', () {
      expect(cubit().preview(), [naive(2026, 10, 23, 11)]);
    });

    test('is empty when the start is in the past and does not repeat', () {
      final c = cubit()
        ..dateChanged(naive(2026, 10, 1))
        ..timeChanged(9, 0);

      expect(c.preview(), isEmpty);
    });
  });

  group('category', () {
    test('is saved with a new reminder', () async {
      final work = (await env.categories.getAll())[1];
      final c = cubit()
        ..titleChanged('Standup')
        ..categoryChanged(work.id);

      await c.save();

      expect((await env.repository.getAll()).single.categoryId, work.id);
    });

    test('starts empty and can be cleared again', () async {
      final work = (await env.categories.getAll())[1];
      final c = cubit();
      expect(c.state.categoryId, isNull);

      c.categoryChanged(work.id);
      expect(c.state.categoryId, work.id);

      c.categoryChanged(null);
      expect(c.state.categoryId, isNull);
    });

    test('is prefilled when editing and can be changed or removed', () async {
      final all = await env.categories.getAll();
      final created = await env.service.create(
        ReminderDraft(
          title: 'Original',
          start: naive(2026, 10, 24, 9),
          categoryId: all[0].id,
        ),
      );

      final change = cubit(existing: created);
      expect(change.state.categoryId, all[0].id);
      change.categoryChanged(all[3].id);
      await change.save();
      expect((await env.repository.getById(created.id))!.categoryId, all[3].id);

      final saved = (await env.repository.getById(created.id))!;
      final remove = cubit(existing: saved)..categoryChanged(null);
      await remove.save();
      expect((await env.repository.getById(created.id))!.categoryId, isNull);
    });
  });
}
