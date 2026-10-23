import 'package:equatable/equatable.dart';

enum RepeatUnit { minute, hour, day, week, month, year }

/// "Every [interval] [unit]", optionally limited by [until] or [count].
///
/// The presets (daily, weekly, monthly, yearly) are just rules with
/// `interval == 1`; "custom" is any other combination.
class RecurrenceRule extends Equatable {
  const RecurrenceRule({
    required this.unit,
    this.interval = 1,
    this.weekdays = const {},
    this.lastDayOfMonth = false,
    this.until,
    this.count,
  });

  /// Shortest interval the app allows (matches the background top-up cadence).
  static const minMinuteInterval = 15;

  final RepeatUnit unit;
  final int interval;

  /// ISO weekdays (Monday = 1 ... Sunday = 7). Only used when
  /// [unit] is [RepeatUnit.week]; empty means "the weekday of the start".
  final Set<int> weekdays;

  /// Only used when [unit] is [RepeatUnit.month]: fire on the last day of each
  /// month instead of the start's day-of-month.
  final bool lastDayOfMonth;

  /// Last day (naive, inclusive) on which the rule may fire.
  final DateTime? until;

  /// Total number of occurrences, including the first.
  final int? count;

  /// Returns the first problem with this rule, or null when it is valid.
  RecurrenceRuleError? validate() {
    if (interval < 1) return RecurrenceRuleError.intervalTooSmall;
    if (unit == RepeatUnit.minute && interval < minMinuteInterval) {
      return RecurrenceRuleError.minuteIntervalTooSmall;
    }
    if (until != null && count != null) return RecurrenceRuleError.twoEndings;
    if (count != null && count! < 1) return RecurrenceRuleError.countTooSmall;
    return null;
  }

  RecurrenceRule copyWith({
    RepeatUnit? unit,
    int? interval,
    Set<int>? weekdays,
    bool? lastDayOfMonth,
    DateTime? until,
    int? count,
    bool clearEnd = false,
  }) {
    return RecurrenceRule(
      unit: unit ?? this.unit,
      interval: interval ?? this.interval,
      weekdays: weekdays ?? this.weekdays,
      lastDayOfMonth: lastDayOfMonth ?? this.lastDayOfMonth,
      until: clearEnd ? null : (until ?? this.until),
      count: clearEnd ? null : (count ?? this.count),
    );
  }

  Map<String, Object?> toJson() => {
    'u': unit.name,
    'i': interval,
    if (weekdays.isNotEmpty) 'w': (weekdays.toList()..sort()),
    if (lastDayOfMonth) 'l': true,
    if (until != null) 'until': until!.millisecondsSinceEpoch,
    if (count != null) 'c': count,
  };

  factory RecurrenceRule.fromJson(Map<String, Object?> json) {
    final until = json['until'] as int?;
    return RecurrenceRule(
      unit: RepeatUnit.values.byName(json['u']! as String),
      interval: json['i']! as int,
      weekdays: {...?(json['w'] as List<Object?>?)?.cast<int>()},
      lastDayOfMonth: json['l'] as bool? ?? false,
      until: until == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(until, isUtc: true),
      count: json['c'] as int?,
    );
  }

  @override
  List<Object?> get props => [
    unit,
    interval,
    (weekdays.toList()..sort()),
    lastDayOfMonth,
    until,
    count,
  ];
}

enum RecurrenceRuleError {
  intervalTooSmall,
  minuteIntervalTooSmall,
  twoEndings,
  countTooSmall,
}
