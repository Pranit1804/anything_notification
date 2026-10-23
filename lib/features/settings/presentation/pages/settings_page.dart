import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_dependencies.dart';
import '../../../../app/router.dart';
import '../../../../core/l10n_context.dart';
import '../../../../core/notifications/notification_permissions.dart';
import '../../../../core/time/naive_time.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../history/presentation/history_cubit.dart';
import '../../../permissions/presentation/permissions_cubit.dart';
import '../../../reminders/presentation/reminder_formatters.dart';
import '../../domain/app_settings.dart';
import '../cubit/settings_cubit.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.watch<SettingsCubit>();
    final settings = cubit.state;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(title: Text(l10n.settingsTitle)),
          SliverList.list(
            children: [
              _SectionHeader(l10n.settingsAppearance),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<ThemeMode>(
                    segments: [
                      ButtonSegment(
                        value: ThemeMode.system,
                        label: Text(l10n.themeSystem),
                      ),
                      ButtonSegment(
                        value: ThemeMode.light,
                        label: Text(l10n.themeLight),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        label: Text(l10n.themeDark),
                      ),
                    ],
                    selected: {settings.themeMode},
                    onSelectionChanged: (selection) =>
                        cubit.setThemeMode(selection.first),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                title: Text(l10n.dynamicColorTitle),
                subtitle: Text(l10n.dynamicColorSubtitle),
                value: settings.useDynamicColor,
                onChanged: cubit.setUseDynamicColor,
              ),
              _SectionHeader(l10n.settingsReminders),
              _ChoiceTile<int>(
                title: l10n.settingsSnooze,
                value: settings.snoozeMinutes,
                options: AppSettings.snoozeOptions,
                label: (minutes) => l10n.settingsSnoozeValue(minutes),
                onChanged: cubit.setSnoozeMinutes,
              ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                title: Text(l10n.settingsDefaultTime),
                subtitle: Text(
                  formatTime(
                    context,
                    naive(
                      2000,
                      1,
                      1,
                      settings.defaultReminderMinutes ~/ 60,
                      settings.defaultReminderMinutes % 60,
                    ),
                  ),
                ),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    helpText: l10n.settingsDefaultTimeSubtitle,
                    initialTime: TimeOfDay(
                      hour: settings.defaultReminderMinutes ~/ 60,
                      minute: settings.defaultReminderMinutes % 60,
                    ),
                  );
                  if (picked != null) {
                    await cubit.setDefaultReminderMinutes(
                      picked.hour * 60 + picked.minute,
                    );
                  }
                },
              ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                title: Text(l10n.settingsCategoriesTile),
                subtitle: Text(l10n.settingsCategoriesSubtitle),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.push(AppRoutes.categories),
              ),
              _SectionHeader(l10n.settingsHistory),
              _ChoiceTile<int>(
                title: l10n.settingsKeepHistory,
                value: settings.historyRetentionDays,
                options: AppSettings.retentionOptions,
                label: (days) => _retentionLabel(l10n, days),
                onChanged: cubit.setHistoryRetentionDays,
              ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                title: Text(l10n.historyClear),
                onTap: () => _confirmClearHistory(context),
              ),
              _SectionHeader(l10n.settingsReliability),
              const _ReliabilitySection(),
              const SizedBox(height: 32),
            ],
          ),
        ],
      ),
    );
  }

  static String _retentionLabel(AppLocalizations l10n, int days) =>
      switch (days) {
        0 => l10n.settingsRetentionForever,
        365 => l10n.settingsRetentionYear,
        _ => l10n.settingsRetentionDays(days),
      };

  static Future<void> _confirmClearHistory(BuildContext context) async {
    final l10n = context.l10n;
    final history = context.read<HistoryCubit>();
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.historyClearTitle),
        content: Text(l10n.historyClearBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.historyClear),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await history.clear();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.historyCleared)));
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
      child: Text(
        label,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

/// A row showing the current choice; tapping opens a dialog to change it.
class _ChoiceTile<T> extends StatelessWidget {
  const _ChoiceTile({
    required this.title,
    required this.value,
    required this.options,
    required this.label,
    required this.onChanged,
  });

  final String title;
  final T value;
  final List<T> options;
  final String Function(T) label;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      title: Text(title),
      subtitle: Text(label(value)),
      onTap: () async {
        final picked = await showDialog<T>(
          context: context,
          builder: (context) => SimpleDialog(
            title: Text(title),
            children: [
              RadioGroup<T>(
                groupValue: value,
                onChanged: (v) => Navigator.pop(context, v),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final option in options)
                      RadioListTile<T>(
                        value: option,
                        title: Text(label(option)),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
        if (picked != null) onChanged(picked);
      },
    );
  }
}

/// Is everything in place for reminders to arrive? With a way to fix it,
/// a test, and a guide for when a reminder still doesn't show up.
class _ReliabilitySection extends StatelessWidget {
  const _ReliabilitySection();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final deps = context.read<AppDependencies>();
    final permissions = context.read<PermissionsCubit>();

    return BlocBuilder<PermissionsCubit, PermissionSnapshot?>(
      builder: (context, snapshot) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l10n.reliabilityIntro,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            _StatusTile(
              title: l10n.reliabilityNotifications,
              ok: snapshot?.notificationsEnabled,
              okLabel: l10n.statusOn,
              notOkLabel: l10n.statusOff,
              onFix: permissions.turnOnNotifications,
            ),
            _StatusTile(
              title: l10n.reliabilityExact,
              ok: snapshot?.exactAlarmsAllowed,
              okLabel: l10n.statusAllowed,
              notOkLabel: l10n.statusNotAllowed,
              onFix: permissions.requestExactAlarms,
            ),
            _StatusTile(
              title: l10n.reliabilityFullScreen,
              ok: snapshot?.fullScreenIntentAllowed,
              okLabel: l10n.statusAllowed,
              notOkLabel: l10n.statusNotAllowed,
              onFix: permissions.requestFullScreenIntent,
            ),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
              leading: const Icon(Icons.notifications_active_outlined),
              title: Text(l10n.reliabilityTest),
              subtitle: Text(l10n.reliabilityTestSubtitle),
              onTap: () async {
                final messenger = ScaffoldMessenger.of(context);
                await deps.testNotifications.send();
                messenger
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(content: Text(l10n.reliabilityTestSent)),
                  );
              },
            ),
            ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 24),
              leading: const Icon(Icons.help_outline_rounded),
              title: Text(l10n.reliabilityGuideTitle),
              shape: const Border(),
              collapsedShape: const Border(),
              childrenPadding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _GuideLine(l10n.reliabilityGuideBattery),
                _GuideLine(l10n.reliabilityGuideForceStop),
                _GuideLine(l10n.reliabilityGuideFocus),
                _GuideLine(l10n.reliabilityGuideSticky),
                _GuideLine(l10n.reliabilityGuideChecks),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: deps.systemSettings.openBatterySettings,
                    icon: const Icon(Icons.battery_saver_outlined),
                    label: Text(l10n.reliabilityOpenBattery),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _StatusTile extends StatelessWidget {
  const _StatusTile({
    required this.title,
    required this.ok,
    required this.okLabel,
    required this.notOkLabel,
    required this.onFix,
  });

  final String title;

  /// Null while the status is still being read.
  final bool? ok;
  final String okLabel;
  final String notOkLabel;
  final VoidCallback onFix;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final good = ok ?? true;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      leading: Icon(
        good ? Icons.check_circle_rounded : Icons.error_rounded,
        color: good ? scheme.primary : scheme.error,
      ),
      title: Text(title),
      subtitle: ok == null ? null : Text(good ? okLabel : notOkLabel),
      trailing: good
          ? null
          : FilledButton.tonal(
              onPressed: onFix,
              child: Text(context.l10n.reliabilityFix),
            ),
    );
  }
}

class _GuideLine extends StatelessWidget {
  const _GuideLine(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6, right: 12),
            child: Icon(Icons.circle, size: 6),
          ),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
