import 'package:anything_notification/features/settings/data/settings_repository.dart';
import 'package:anything_notification/features/settings/domain/app_settings.dart';
import 'package:anything_notification/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SettingsRepository repository;
  late SettingsCubit cubit;
  late List<AppSettings> emitted;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    repository = SettingsRepository(await SharedPreferences.getInstance());
    cubit = SettingsCubit(repository);
    emitted = [];
    cubit.stream.listen(emitted.add);
    addTearDown(cubit.close);
  });

  test('setThemeMode emits the new mode and persists it', () async {
    await cubit.setThemeMode(ThemeMode.dark);
    await Future<void>.delayed(Duration.zero);

    expect(emitted, [const AppSettings(themeMode: ThemeMode.dark)]);
    expect(repository.load().themeMode, ThemeMode.dark);
  });

  test('setUseDynamicColor emits the new value and persists it', () async {
    await cubit.setUseDynamicColor(false);
    await Future<void>.delayed(Duration.zero);

    expect(emitted, [const AppSettings(useDynamicColor: false)]);
    expect(repository.load().useDynamicColor, isFalse);
  });

  test('does not emit when the value is unchanged', () async {
    await cubit.setThemeMode(ThemeMode.system);
    await Future<void>.delayed(Duration.zero);

    expect(emitted, isEmpty);
  });

  test('setSnoozeMinutes emits and persists', () async {
    await cubit.setSnoozeMinutes(30);
    await Future<void>.delayed(Duration.zero);

    expect(emitted, [const AppSettings(snoozeMinutes: 30)]);
    expect(repository.snoozeMinutes, 30);
  });

  test('setHistoryRetentionDays emits and persists (0 = forever)', () async {
    await cubit.setHistoryRetentionDays(0);
    await Future<void>.delayed(Duration.zero);

    expect(emitted, [const AppSettings(historyRetentionDays: 0)]);
    expect(repository.historyRetentionDays, 0);
  });
}
