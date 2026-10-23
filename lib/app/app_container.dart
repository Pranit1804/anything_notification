import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/db/app_database.dart';
import '../core/notifications/alarm_payload.dart';
import '../core/notifications/alarm_scheduler.dart';
import '../core/notifications/notification_background.dart';
import '../core/notifications/notification_content.dart';
import '../core/notifications/notification_permissions.dart';
import '../core/notifications/test_notification.dart';
import '../core/platform/system_settings.dart';
import '../core/time/time_zone_service.dart';
import '../core/time/zoned_clock.dart';
import '../features/categories/data/category_repository.dart';
import '../features/history/data/history_repository.dart';
import '../features/reminders/application/reminder_service.dart';
import '../features/reminders/data/reminder_repository.dart';
import '../features/settings/data/settings_repository.dart';
import 'app_dependencies.dart';

/// Builds the real object graph. Used by the app and, with no UI, by the
/// notification-action and boot-worker isolates.
class AppContainer {
  AppContainer._({
    required this.database,
    required this.plugin,
    required this.clock,
    required this.settings,
    required this.repository,
    required this.categories,
    required this.history,
    required this.scheduler,
    required this.service,
  });

  final AppDatabase database;
  final FlutterLocalNotificationsPlugin plugin;
  final ZonedClock clock;
  final SettingsRepository settings;
  final ReminderRepository repository;
  final CategoryRepository categories;
  final HistoryRepository history;
  final AlarmScheduler scheduler;
  final ReminderService service;

  /// [onNotificationResponse] receives taps on a notification while the app is
  /// in the foreground; only the UI isolate needs it.
  static Future<AppContainer> create({
    DidReceiveNotificationResponseCallback? onNotificationResponse,
  }) async {
    final timeZones = TimeZoneService();
    await timeZones.initialize();

    final clock = ZonedClock();
    final database = AppDatabase.open();
    final repository = ReminderRepository(database);
    final categories = CategoryRepository(database);
    final history = HistoryRepository(database);
    final settings = SettingsRepository(await SharedPreferences.getInstance());

    final plugin = FlutterLocalNotificationsPlugin();
    await plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings(notificationSmallIcon),
      ),
      onDidReceiveNotificationResponse: onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: notificationBackgroundHandler,
    );
    final android = plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    for (final channel in NotificationChannels.all) {
      await android?.createNotificationChannel(channel);
    }

    final scheduler = NotificationAlarmScheduler(
      plugin: plugin,
      repository: repository,
      categories: categories,
      preferences: settings,
      clock: clock,
      timeZones: timeZones,
    );

    return AppContainer._(
      database: database,
      plugin: plugin,
      clock: clock,
      settings: settings,
      repository: repository,
      categories: categories,
      history: history,
      scheduler: scheduler,
      service: ReminderService(
        repository: repository,
        history: history,
        categories: categories,
        preferences: settings,
        scheduler: scheduler,
        clock: clock,
      ),
    );
  }

  /// Wires up the UI-facing dependencies, including notification taps.
  static Future<AppDependencies> createForUi() async {
    final taps = StreamController<AlarmPayload>.broadcast();
    final container = await create(
      onNotificationResponse: (response) {
        // Buttons are handled in the background; only plain taps open the app.
        if (response.actionId != null && response.actionId!.isNotEmpty) return;
        final payload = AlarmPayload.tryParse(response.payload);
        if (payload != null) taps.add(payload);
      },
    );

    final launch = await container.plugin.getNotificationAppLaunchDetails();
    final launched = launch?.didNotificationLaunchApp ?? false;
    final launchedBy = launched
        ? AlarmPayload.tryParse(launch!.notificationResponse?.payload)
        : null;

    return AppDependencies(
      settingsRepository: container.settings,
      reminderRepository: container.repository,
      categoryRepository: container.categories,
      historyRepository: container.history,
      reminderService: container.service,
      scheduler: container.scheduler,
      permissions: PluginNotificationPermissions(
        container.plugin,
        const MethodChannelSystemSettings(),
      ),
      testNotifications: PluginTestNotificationSender(
        container.plugin,
        container.clock,
      ),
      systemSettings: const MethodChannelSystemSettings(),
      clock: container.clock,
      openReminderRequests: taps.stream,
      initialOpen: launchedBy,
    );
  }

  Future<void> dispose() => database.close();
}
