import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class AppSettings extends Equatable {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.useDynamicColor = true,
    this.snoozeMinutes = defaultSnoozeMinutes,
    this.historyRetentionDays = defaultHistoryRetentionDays,
    this.defaultReminderMinutes = defaultReminderTimeMinutes,
  });

  static const defaultSnoozeMinutes = 10;
  static const defaultHistoryRetentionDays = 90;

  /// 9:00 AM, as minutes after midnight.
  static const defaultReminderTimeMinutes = 9 * 60;

  /// Choices offered for the snooze duration, in minutes.
  static const snoozeOptions = [5, 10, 15, 30, 60];

  /// Choices offered for history retention, in days; 0 means forever.
  static const retentionOptions = [30, 90, 365, 0];

  final ThemeMode themeMode;
  final bool useDynamicColor;
  final int snoozeMinutes;
  final int historyRetentionDays;

  /// The time of day used when a reminder names a day but no time, as
  /// minutes after midnight.
  final int defaultReminderMinutes;

  AppSettings copyWith({
    ThemeMode? themeMode,
    bool? useDynamicColor,
    int? snoozeMinutes,
    int? historyRetentionDays,
    int? defaultReminderMinutes,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      useDynamicColor: useDynamicColor ?? this.useDynamicColor,
      snoozeMinutes: snoozeMinutes ?? this.snoozeMinutes,
      historyRetentionDays: historyRetentionDays ?? this.historyRetentionDays,
      defaultReminderMinutes:
          defaultReminderMinutes ?? this.defaultReminderMinutes,
    );
  }

  @override
  List<Object> get props => [
    themeMode,
    useDynamicColor,
    snoozeMinutes,
    historyRetentionDays,
    defaultReminderMinutes,
  ];
}
