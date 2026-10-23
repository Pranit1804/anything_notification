import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/settings_repository.dart';
import '../../domain/app_settings.dart';

class SettingsCubit extends Cubit<AppSettings> {
  SettingsCubit(this._repository) : super(_repository.load());

  final SettingsRepository _repository;

  Future<void> setThemeMode(ThemeMode mode) =>
      _update(state.copyWith(themeMode: mode));

  Future<void> setUseDynamicColor(bool value) =>
      _update(state.copyWith(useDynamicColor: value));

  Future<void> setSnoozeMinutes(int minutes) =>
      _update(state.copyWith(snoozeMinutes: minutes));

  /// 0 keeps history forever.
  Future<void> setHistoryRetentionDays(int days) =>
      _update(state.copyWith(historyRetentionDays: days));

  /// Minutes after midnight.
  Future<void> setDefaultReminderMinutes(int minutes) =>
      _update(state.copyWith(defaultReminderMinutes: minutes));

  Future<void> _update(AppSettings next) async {
    if (next == state) return;
    emit(next);
    await _repository.save(next);
  }
}
