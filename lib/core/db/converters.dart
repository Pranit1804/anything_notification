import 'dart:convert';

import 'package:drift/drift.dart';

import '../../features/reminders/domain/recurrence_rule.dart';

/// Stores a naive wall-clock time (see `naive_time.dart`) as the milliseconds
/// of its UTC-flagged [DateTime].
///
/// Drift's default `dateTime()` would read values back in the device's local
/// zone and shift the wall-clock components, which is exactly what naive times
/// must never do.
class NaiveDateTimeConverter extends TypeConverter<DateTime, int> {
  const NaiveDateTimeConverter();

  @override
  DateTime fromSql(int fromDb) =>
      DateTime.fromMillisecondsSinceEpoch(fromDb, isUtc: true);

  @override
  int toSql(DateTime value) => value.millisecondsSinceEpoch;
}

class RecurrenceRuleConverter extends TypeConverter<RecurrenceRule, String> {
  const RecurrenceRuleConverter();

  @override
  RecurrenceRule fromSql(String fromDb) =>
      RecurrenceRule.fromJson(jsonDecode(fromDb) as Map<String, Object?>);

  @override
  String toSql(RecurrenceRule value) => jsonEncode(value.toJson());
}
