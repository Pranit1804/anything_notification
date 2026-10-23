import 'dart:async';

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import '../core/notifications/alarm_payload.dart';
import '../core/notifications/refresh_port.dart';
import '../core/time/zoned_clock.dart';
import '../features/categories/presentation/categories_cubit.dart';
import '../features/history/presentation/history_cubit.dart';
import '../features/permissions/presentation/permissions_cubit.dart';
import '../features/reminders/application/reminder_service.dart';
import '../features/reminders/data/reminder_repository.dart';
import '../features/reminders/domain/reminder.dart';
import '../features/reminders/presentation/cubit/reminder_list_cubit.dart';
import '../features/settings/data/settings_repository.dart';
import '../features/settings/domain/app_settings.dart';
import '../features/settings/presentation/cubit/settings_cubit.dart';
import '../l10n/app_localizations.dart';
import 'app_dependencies.dart';
import 'router.dart';
import 'theme/app_theme.dart';

class App extends StatefulWidget {
  const App({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> with WidgetsBindingObserver {
  // Created once so rebuilds (e.g. theme changes) never reset navigation.
  late final GoRouter _router = createRouter();
  late final SettingsCubit _settings;
  late final ReminderListCubit _reminders;
  late final PermissionsCubit _permissions;
  late final CategoriesCubit _categories;
  late final HistoryCubit _history;
  RefreshListener? _refreshListener;
  StreamSubscription<AlarmPayload>? _notificationTaps;

  AppDependencies get _deps => widget.dependencies;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _settings = SettingsCubit(_deps.settingsRepository);
    _reminders = ReminderListCubit(
      repository: _deps.reminderRepository,
      service: _deps.reminderService,
      clock: _deps.clock,
      categories: _deps.categoryRepository,
    );
    _categories = CategoriesCubit(_deps.categoryRepository);
    _history = HistoryCubit(
      history: _deps.historyRepository,
      categories: _deps.categoryRepository,
      clock: _deps.clock,
    );
    _permissions = PermissionsCubit(_deps.permissions, _deps.settingsRepository)
      ..refresh();

    // A notification action handled in the background changed the database.
    try {
      _refreshListener = RefreshPort.listen(
        _deps.reminderRepository.notifyExternalChange,
      );
    } on Object catch (error) {
      debugPrint('Background refresh unavailable: $error');
    }

    _notificationTaps = _deps.openReminderRequests.listen(_openReminder);
    final initial = _deps.initialOpen;
    if (initial != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _openReminder(initial),
      );
    }
  }

  /// An alarm-style reminder opens the full-screen alarm; anything else opens
  /// the reminder to edit.
  Future<void> _openReminder(AlarmPayload payload) async {
    final reminder = await _deps.reminderRepository.getById(payload.reminderId);
    // A tap on a notification for something already finished does nothing.
    if (reminder == null ||
        reminder.status == ReminderStatus.completed ||
        !mounted) {
      return;
    }

    final ringing =
        reminder.delivery == DeliveryMode.alarm &&
        reminder.status == ReminderStatus.active;
    unawaited(
      _router.push(
        ringing
            ? AppRoutes.alarm(reminder.id, payload.occurrence)
            : AppRoutes.editReminder(reminder.id),
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    // The user may have changed permissions or time settings, or a background
    // action may have changed reminders, while the app was away.
    unawaited(_permissions.refresh());
    _deps.reminderRepository.notifyExternalChange();
    unawaited(_maintain());
  }

  /// Records what went unhandled while away, then re-arms what changed.
  Future<void> _maintain() async {
    try {
      await _deps.reminderService.settleMissed();
      await _deps.scheduler.reconcile();
    } on Object catch (error) {
      debugPrint('Maintenance failed: $error');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshListener?.dispose();
    unawaited(_notificationTaps?.cancel());
    unawaited(_settings.close());
    unawaited(_reminders.close());
    unawaited(_permissions.close());
    unawaited(_categories.close());
    unawaited(_history.close());
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<SettingsRepository>.value(
          value: _deps.settingsRepository,
        ),
        RepositoryProvider<ReminderRepository>.value(
          value: _deps.reminderRepository,
        ),
        RepositoryProvider<ReminderService>.value(value: _deps.reminderService),
        RepositoryProvider<ZonedClock>.value(value: _deps.clock),
        RepositoryProvider<AppDependencies>.value(value: _deps),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<SettingsCubit>.value(value: _settings),
          BlocProvider<ReminderListCubit>.value(value: _reminders),
          BlocProvider<PermissionsCubit>.value(value: _permissions),
          BlocProvider<CategoriesCubit>.value(value: _categories),
          BlocProvider<HistoryCubit>.value(value: _history),
        ],
        // Notifications already armed show the old snooze length on their
        // button until re-armed.
        child: BlocListener<SettingsCubit, AppSettings>(
          listenWhen: (a, b) => a.snoozeMinutes != b.snoozeMinutes,
          listener: (_, _) => unawaited(_maintain()),
          child: BlocBuilder<SettingsCubit, AppSettings>(
            builder: (context, settings) => DynamicColorBuilder(
              builder: (lightDynamic, darkDynamic) {
                final useDynamic = settings.useDynamicColor;
                return MaterialApp.router(
                  onGenerateTitle: (context) =>
                      AppLocalizations.of(context).appName,
                  routerConfig: _router,
                  themeMode: settings.themeMode,
                  theme: AppTheme.light(
                    useDynamic ? lightDynamic?.harmonized() : null,
                  ),
                  darkTheme: AppTheme.dark(
                    useDynamic ? darkDynamic?.harmonized() : null,
                  ),
                  localizationsDelegates: const [
                    AppLocalizations.delegate,
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                  ],
                  supportedLocales: AppLocalizations.supportedLocales,
                  builder: (context, child) => _SystemBars(child: child!),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Transparent, edge-to-edge system bars with icons that follow the theme.
class _SystemBars extends StatelessWidget {
  const _SystemBars({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final iconBrightness = Theme.of(context).brightness == Brightness.dark
        ? Brightness.light
        : Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: iconBrightness,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: iconBrightness,
        systemNavigationBarContrastEnforced: false,
      ),
      child: child,
    );
  }
}
