import 'dart:async';

import 'package:anything_notification/app/app_dependencies.dart';
import 'package:anything_notification/core/notifications/alarm_payload.dart';
import 'package:anything_notification/core/db/app_database.dart';
import 'package:anything_notification/core/notifications/alarm_scheduler.dart';
import 'package:anything_notification/core/notifications/notification_permissions.dart';
import 'package:anything_notification/core/notifications/test_notification.dart';
import 'package:anything_notification/core/platform/system_settings.dart';
import 'package:anything_notification/core/time/zoned_clock.dart';
import 'package:anything_notification/features/categories/data/category_repository.dart';
import 'package:anything_notification/features/history/data/history_repository.dart';
import 'package:anything_notification/features/reminders/application/reminder_service.dart';
import 'package:anything_notification/features/reminders/data/reminder_repository.dart';
import 'package:anything_notification/features/settings/data/settings_repository.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

/// Fri 2026-10-23 10:00, in UTC so wall-clock and instant coincide.
final testNow = DateTime.utc(2026, 10, 23, 10);

class FakeScheduler implements AlarmScheduler {
  int reconciles = 0;
  final dismissed = <(int, DateTime)>[];

  @override
  Future<void> reconcile({bool rearmAll = false}) async => reconciles++;

  @override
  Future<void> dismissShown(int reminderId, DateTime occurrence) async =>
      dismissed.add((reminderId, occurrence));
}

class FakePermissions implements NotificationPermissions {
  FakePermissions({
    this.notificationsEnabled = true,
    this.exactAlarmsAllowed = true,
    this.fullScreenIntentAllowed = true,
  });

  bool notificationsEnabled;
  bool exactAlarmsAllowed;
  bool fullScreenIntentAllowed;
  var fullScreenRequests = 0;
  var notificationRequests = 0;
  var exactAlarmRequests = 0;
  var settingsOpened = 0;

  @override
  Future<PermissionSnapshot> status() async => PermissionSnapshot(
    notificationsEnabled: notificationsEnabled,
    exactAlarmsAllowed: exactAlarmsAllowed,
    fullScreenIntentAllowed: fullScreenIntentAllowed,
  );

  @override
  Future<bool> requestNotifications() async {
    notificationRequests++;
    return notificationsEnabled;
  }

  @override
  Future<void> requestExactAlarms() async => exactAlarmRequests++;

  @override
  Future<void> openNotificationSettings() async => settingsOpened++;

  @override
  Future<void> requestFullScreenIntent() async => fullScreenRequests++;
}

class FakeTestNotifications implements TestNotificationSender {
  var sent = 0;

  @override
  Future<void> send({Duration delay = const Duration(seconds: 10)}) async =>
      sent++;
}

class FakeSystemSettings implements SystemSettings {
  var batterySettingsOpened = 0;
  var alarmsFinished = 0;

  @override
  Future<bool> canUseFullScreenIntent() async => true;

  @override
  Future<void> finishAlarm() async => alarmsFinished++;

  @override
  Future<void> openBatterySettings() async => batterySettingsOpened++;
}

class TestEnvironment {
  TestEnvironment._({
    required this.database,
    required this.dependencies,
    required this.scheduler,
    required this.permissions,
    required this.testNotifications,
    required this.systemSettings,
    required this.notificationTaps,
  });

  final AppDatabase database;
  final AppDependencies dependencies;
  final FakeScheduler scheduler;
  final FakePermissions permissions;
  final FakeTestNotifications testNotifications;
  final FakeSystemSettings systemSettings;

  /// Push a payload to act as if a notification was tapped in the running app.
  final StreamController<AlarmPayload> notificationTaps;

  ReminderRepository get repository => dependencies.reminderRepository;
  CategoryRepository get categories => dependencies.categoryRepository;
  HistoryRepository get history => dependencies.historyRepository;
  SettingsRepository get settings => dependencies.settingsRepository;
  ReminderService get service => dependencies.reminderService;

  static Future<TestEnvironment> create({
    Map<String, Object> prefs = const {},
    FakePermissions? permissions,
  }) async {
    SharedPreferences.setMockInitialValues(prefs);
    // Widget tests fail on leftover timers; by default drift closes cancelled
    // stream queries on a zero-duration timer.
    final database = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    final repository = ReminderRepository(database);
    final categories = CategoryRepository(database);
    final history = HistoryRepository(database);
    final settings = SettingsRepository(await SharedPreferences.getInstance());
    final scheduler = FakeScheduler();
    final clock = ZonedClock(now: () => testNow, location: () => tz.UTC);
    final fakePermissions = permissions ?? FakePermissions();
    final testNotifications = FakeTestNotifications();
    final systemSettings = FakeSystemSettings();
    final taps = StreamController<AlarmPayload>.broadcast();

    return TestEnvironment._(
      database: database,
      scheduler: scheduler,
      permissions: fakePermissions,
      testNotifications: testNotifications,
      systemSettings: systemSettings,
      notificationTaps: taps,
      dependencies: AppDependencies(
        settingsRepository: settings,
        reminderRepository: repository,
        categoryRepository: categories,
        historyRepository: history,
        reminderService: ReminderService(
          repository: repository,
          history: history,
          categories: categories,
          preferences: settings,
          scheduler: scheduler,
          clock: clock,
        ),
        scheduler: scheduler,
        permissions: fakePermissions,
        testNotifications: testNotifications,
        systemSettings: systemSettings,
        clock: clock,
        openReminderRequests: taps.stream,
      ),
    );
  }

  Future<void> dispose() async {
    await notificationTaps.close();
    await database.close();
  }
}
