import 'dart:convert';

import 'package:equatable/equatable.dart';

import '../../features/reminders/domain/alarm_planner.dart';

/// What a scheduled notification carries, so that tapping it (or one of its
/// actions) can be mapped back to a reminder occurrence, and so that
/// `reconcile` can tell whether an armed notification is still current.
class AlarmPayload extends Equatable {
  const AlarmPayload({
    required this.reminderId,
    required this.kind,
    required this.occurrence,
    required this.fireAt,
    required this.revision,
    required this.exact,
    this.snoozeMinutes = 10,
    this.categoryName,
    this.categoryColor,
  });

  factory AlarmPayload.fromAlarm(
    PlannedAlarm alarm, {
    required bool exact,
    required int snoozeMinutes,
  }) => AlarmPayload(
    reminderId: alarm.reminderId,
    kind: alarm.kind,
    occurrence: alarm.occurrence,
    fireAt: alarm.fireAt,
    revision: alarm.revision,
    exact: exact,
    snoozeMinutes: snoozeMinutes,
    categoryName: alarm.categoryName,
    categoryColor: alarm.categoryColor,
  );

  final int reminderId;
  final AlarmKind kind;

  /// Naive wall-clock time of the occurrence.
  final DateTime occurrence;

  /// UTC instant the alarm was armed for.
  final DateTime fireAt;

  /// Reminder revision the notification content was built from.
  final int revision;

  /// Whether it was armed as an exact alarm.
  final bool exact;

  /// Snooze length the notification's button was labelled with, and the
  /// category it was built from. They are part of the payload so that
  /// `reconcile` notices when a setting or category changed and re-arms.
  final int snoozeMinutes;
  final String? categoryName;
  final int? categoryColor;

  String encode() => jsonEncode({
    'r': reminderId,
    'k': kind.name,
    'o': occurrence.millisecondsSinceEpoch,
    'f': fireAt.millisecondsSinceEpoch,
    'v': revision,
    'x': exact,
    'sm': snoozeMinutes,
    if (categoryName != null) 'cn': categoryName,
    if (categoryColor != null) 'cc': categoryColor,
  });

  static AlarmPayload? tryParse(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final json = jsonDecode(raw) as Map<String, Object?>;
      return AlarmPayload(
        reminderId: json['r']! as int,
        kind: AlarmKind.values.byName(json['k']! as String),
        occurrence: DateTime.fromMillisecondsSinceEpoch(
          json['o']! as int,
          isUtc: true,
        ),
        fireAt: DateTime.fromMillisecondsSinceEpoch(
          json['f']! as int,
          isUtc: true,
        ),
        revision: json['v']! as int,
        exact: json['x']! as bool,
        // Notifications armed before these fields existed lack them.
        snoozeMinutes: json['sm'] as int? ?? 10,
        categoryName: json['cn'] as String?,
        categoryColor: json['cc'] as int?,
      );
    } on Object {
      return null;
    }
  }

  @override
  List<Object?> get props => [
    reminderId,
    kind,
    occurrence,
    fireAt,
    revision,
    exact,
    snoozeMinutes,
    categoryName,
    categoryColor,
  ];
}
