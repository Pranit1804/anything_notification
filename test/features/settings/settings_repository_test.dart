import 'package:anything_notification/features/settings/data/settings_repository.dart';
import 'package:anything_notification/features/settings/domain/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<SettingsRepository> _repo([
  Map<String, Object> initial = const {},
]) async {
  SharedPreferences.setMockInitialValues(initial);
  return SettingsRepository(await SharedPreferences.getInstance());
}

void main() {
  test('loads defaults when nothing is stored', () async {
    final repo = await _repo();

    expect(repo.load(), const AppSettings());
    expect(repo.load().themeMode, ThemeMode.system);
    expect(repo.load().useDynamicColor, isTrue);
  });

  test('round-trips saved settings', () async {
    final repo = await _repo();
    const saved = AppSettings(
      themeMode: ThemeMode.dark,
      useDynamicColor: false,
    );

    await repo.save(saved);

    expect(repo.load(), saved);
  });

  test('falls back to system theme when the stored value is unknown', () async {
    final repo = await _repo({'settings.theme_mode': 'sepia'});

    expect(repo.load().themeMode, ThemeMode.system);
  });

  group('reminder preferences', () {
    test('default to a 10 minute snooze and 90 days of history', () async {
      final repo = await _repo();

      expect(repo.snoozeMinutes, 10);
      expect(repo.historyRetentionDays, 90);
    });

    test('round-trip through save and load', () async {
      final repo = await _repo();
      const saved = AppSettings(snoozeMinutes: 30, historyRetentionDays: 0);

      await repo.save(saved);

      expect(repo.load(), saved);
      expect(repo.snoozeMinutes, 30);
      expect(repo.historyRetentionDays, 0); // 0 means forever
    });

    test('ignore nonsense stored values', () async {
      final repo = await _repo({
        'settings.snooze_minutes': 0,
        'settings.history_retention_days': -5,
      });

      expect(repo.snoozeMinutes, 10);
      expect(repo.historyRetentionDays, 90);
    });

    test('every offered choice is distinct and the defaults are offered', () {
      expect(AppSettings.snoozeOptions.toSet(), hasLength(5));
      expect(
        AppSettings.snoozeOptions,
        contains(AppSettings.defaultSnoozeMinutes),
      );
      expect(
        AppSettings.retentionOptions,
        contains(AppSettings.defaultHistoryRetentionDays),
      );
    });
  });
}
