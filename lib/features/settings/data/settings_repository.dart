import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/app_settings.dart';
import '../domain/reminder_preferences.dart';

class SettingsRepository implements ReminderPreferences {
  SettingsRepository(this._prefs);

  final SharedPreferences _prefs;

  static const _themeModeKey = 'settings.theme_mode';
  static const _dynamicColorKey = 'settings.dynamic_color';
  static const _snoozeKey = 'settings.snooze_minutes';
  static const _retentionKey = 'settings.history_retention_days';
  static const _defaultTimeKey = 'settings.default_reminder_minutes';
  static const _exactAlarmPromptKey = 'prompts.exact_alarm_shown';

  AppSettings load() {
    const defaults = AppSettings();
    return AppSettings(
      themeMode:
          ThemeMode.values.asNameMap()[_prefs.getString(_themeModeKey)] ??
          defaults.themeMode,
      useDynamicColor:
          _prefs.getBool(_dynamicColorKey) ?? defaults.useDynamicColor,
      snoozeMinutes: snoozeMinutes,
      historyRetentionDays: historyRetentionDays,
      defaultReminderMinutes: _defaultReminderMinutes,
    );
  }

  Future<void> save(AppSettings settings) async {
    await _prefs.setString(_themeModeKey, settings.themeMode.name);
    await _prefs.setBool(_dynamicColorKey, settings.useDynamicColor);
    await _prefs.setInt(_snoozeKey, settings.snoozeMinutes);
    await _prefs.setInt(_retentionKey, settings.historyRetentionDays);
    await _prefs.setInt(_defaultTimeKey, settings.defaultReminderMinutes);
  }

  int get _defaultReminderMinutes {
    final stored = _prefs.getInt(_defaultTimeKey);
    return stored != null && stored >= 0 && stored < 24 * 60
        ? stored
        : AppSettings.defaultReminderTimeMinutes;
  }

  @override
  int get snoozeMinutes {
    final stored = _prefs.getInt(_snoozeKey);
    return stored != null && stored > 0
        ? stored
        : AppSettings.defaultSnoozeMinutes;
  }

  @override
  int get historyRetentionDays {
    final stored = _prefs.getInt(_retentionKey);
    return stored != null && stored >= 0
        ? stored
        : AppSettings.defaultHistoryRetentionDays;
  }

  /// Whether the "allow exact alarms?" explanation has been shown already.
  bool get exactAlarmPromptShown =>
      _prefs.getBool(_exactAlarmPromptKey) ?? false;

  Future<void> markExactAlarmPromptShown() =>
      _prefs.setBool(_exactAlarmPromptKey, true);
}
