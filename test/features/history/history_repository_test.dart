import 'package:anything_notification/core/time/naive_time.dart';
import 'package:anything_notification/features/history/domain/history_entry.dart';
import 'package:anything_notification/features/reminders/domain/occurrence_outcome.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_dependencies.dart';

void main() {
  late TestEnvironment env;

  setUp(() async => env = await TestEnvironment.create());
  tearDown(() => env.dispose());

  Future<void> log(
    String title, {
    OccurrenceOutcome outcome = OccurrenceOutcome.done,
    DateTime? scheduled,
    DateTime? at,
    int reminderId = 1,
    int? categoryId,
    String? categoryName,
    int? categoryColor,
  }) => env.history.log(
    reminderId: reminderId,
    title: title,
    scheduledLocal: scheduled ?? naive(2026, 10, 23, 9),
    outcome: outcome,
    at: at ?? testNow,
    categoryId: categoryId,
    categoryName: categoryName,
    categoryColor: categoryColor,
  );

  test('stores everything, including the category snapshot', () async {
    await log(
      'Pay rent',
      outcome: OccurrenceOutcome.snoozed,
      categoryId: 4,
      categoryName: 'Bills',
      categoryColor: 0xFFE8590C,
    );

    final entry = (await env.history.entriesFor(1)).single;
    expect(entry.title, 'Pay rent');
    expect(entry.outcome, OccurrenceOutcome.snoozed);
    expect(entry.scheduledLocal, naive(2026, 10, 23, 9));
    expect(entry.at, testNow);
    expect(entry.categoryId, 4);
    expect(entry.categoryName, 'Bills');
    expect(entry.categoryColor, 0xFFE8590C);
  });

  test('watchAll lists the newest first', () async {
    await log('First', at: testNow.subtract(const Duration(hours: 2)));
    await log('Second', at: testNow.subtract(const Duration(hours: 1)));
    await log('Third', at: testNow);

    final entries = await env.history.watchAll().first;

    expect(entries.map((e) => e.title), ['Third', 'Second', 'First']);
  });

  test('watchAll re-emits when something is logged', () async {
    final stream = env.history.watchAll();
    expect(await stream.first, isEmpty);

    final next = expectLater(
      stream.skip(1),
      emits(predicate<List<HistoryEntry>>((l) => l.length == 1)),
    );
    await log('New');
    await next;
  });

  test('a missed occurrence is only recorded once', () async {
    await log('Daily', outcome: OccurrenceOutcome.missed);
    await log('Daily', outcome: OccurrenceOutcome.missed);
    // A different occurrence, or a different outcome, is still recorded.
    await log(
      'Daily',
      outcome: OccurrenceOutcome.missed,
      scheduled: naive(2026, 10, 24, 9),
    );
    await log('Daily');

    expect(await env.history.entriesFor(1), hasLength(3));
  });

  test('deleteOlderThan removes only entries before the cutoff', () async {
    await log('Old', at: testNow.subtract(const Duration(days: 100)));
    await log('Edge', at: testNow.subtract(const Duration(days: 30)));
    await log('New');

    final removed = await env.history.deleteOlderThan(
      testNow.subtract(const Duration(days: 90)),
    );

    expect(removed, 1);
    expect((await env.history.entriesFor(1)).map((e) => e.title), [
      'Edge',
      'New',
    ]);
  });

  test('clear removes everything', () async {
    await log('A');
    await log('B', reminderId: 2);

    await env.history.clear();

    expect(await env.history.watchAll().first, isEmpty);
  });

  test('history outlives the reminder it came from', () async {
    await log('Gone soon');
    // No reminder with id 1 exists at all, and the entry is still readable.
    expect(await env.repository.getById(1), isNull);
    expect((await env.history.entriesFor(1)).single.title, 'Gone soon');
  });
}
