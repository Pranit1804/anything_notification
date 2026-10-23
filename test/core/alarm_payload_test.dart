import 'dart:convert';

import 'package:anything_notification/core/notifications/alarm_payload.dart';
import 'package:anything_notification/core/time/naive_time.dart';
import 'package:anything_notification/features/reminders/domain/alarm_planner.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final payload = AlarmPayload(
    reminderId: 7,
    kind: AlarmKind.snooze,
    occurrence: naive(2026, 10, 24, 9),
    fireAt: DateTime.utc(2026, 10, 24, 13),
    revision: 3,
    exact: true,
    snoozeMinutes: 15,
    categoryName: 'Bills',
    categoryColor: 0xFFE8590C,
  );

  test('round-trips every field', () {
    expect(AlarmPayload.tryParse(payload.encode()), payload);
  });

  test('round-trips without a category', () {
    final plain = AlarmPayload(
      reminderId: 1,
      kind: AlarmKind.occurrence,
      occurrence: naive(2026, 10, 24, 9),
      fireAt: DateTime.utc(2026, 10, 24, 13),
      revision: 1,
      exact: false,
    );

    final parsed = AlarmPayload.tryParse(plain.encode())!;

    expect(parsed, plain);
    expect(parsed.categoryName, isNull);
    expect(parsed.snoozeMinutes, 10);
  });

  test('reads a payload armed before categories and snooze were added', () {
    // What M1 wrote: no "sm", "cn" or "cc".
    final old = jsonEncode({
      'r': 5,
      'k': 'occurrence',
      'o': naive(2026, 10, 24, 9).millisecondsSinceEpoch,
      'f': DateTime.utc(2026, 10, 24, 13).millisecondsSinceEpoch,
      'v': 2,
      'x': true,
    });

    final parsed = AlarmPayload.tryParse(old)!;

    expect(parsed.reminderId, 5);
    expect(parsed.snoozeMinutes, 10);
    expect(parsed.categoryName, isNull);
  });

  test('rejects garbage', () {
    expect(AlarmPayload.tryParse(null), isNull);
    expect(AlarmPayload.tryParse(''), isNull);
    expect(AlarmPayload.tryParse('not json'), isNull);
    expect(AlarmPayload.tryParse('{"r":1}'), isNull);
  });

  test('a changed snooze length or category changes the payload text, '
      'which is how reconcile knows to re-arm', () {
    final base = payload.encode();

    expect(
      AlarmPayload(
        reminderId: 7,
        kind: AlarmKind.snooze,
        occurrence: naive(2026, 10, 24, 9),
        fireAt: DateTime.utc(2026, 10, 24, 13),
        revision: 3,
        exact: true,
        snoozeMinutes: 30,
        categoryName: 'Bills',
        categoryColor: 0xFFE8590C,
      ).encode(),
      isNot(base),
    );
    expect(
      AlarmPayload(
        reminderId: 7,
        kind: AlarmKind.snooze,
        occurrence: naive(2026, 10, 24, 9),
        fireAt: DateTime.utc(2026, 10, 24, 13),
        revision: 3,
        exact: true,
        snoozeMinutes: 15,
        categoryName: 'Invoices',
        categoryColor: 0xFFE8590C,
      ).encode(),
      isNot(base),
    );
  });
}
