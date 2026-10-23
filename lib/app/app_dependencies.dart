import '../core/notifications/alarm_scheduler.dart';
import '../core/notifications/notification_permissions.dart';
import '../core/notifications/test_notification.dart';
import '../core/platform/system_settings.dart';
import '../core/time/zoned_clock.dart';
import '../features/categories/data/category_repository.dart';
import '../features/history/data/history_repository.dart';
import '../features/reminders/application/reminder_service.dart';
import '../features/reminders/data/reminder_repository.dart';
import '../features/settings/data/settings_repository.dart';

/// Everything the UI needs from the outside world. The app builds the real one
/// (see `AppContainer`); tests build one from in-memory fakes.
class AppDependencies {
  AppDependencies({
    required this.settingsRepository,
    required this.reminderRepository,
    required this.categoryRepository,
    required this.historyRepository,
    required this.reminderService,
    required this.scheduler,
    required this.permissions,
    required this.testNotifications,
    required this.systemSettings,
    required this.clock,
    this.openReminderRequests = const Stream.empty(),
    this.initialReminderId,
  });

  final SettingsRepository settingsRepository;
  final ReminderRepository reminderRepository;
  final CategoryRepository categoryRepository;
  final HistoryRepository historyRepository;
  final ReminderService reminderService;
  final AlarmScheduler scheduler;
  final NotificationPermissions permissions;
  final TestNotificationSender testNotifications;
  final SystemSettings systemSettings;
  final ZonedClock clock;

  /// Ids of reminders whose notification was tapped while the app was running.
  final Stream<int> openReminderRequests;

  /// Set when the app was launched by tapping a reminder's notification.
  final int? initialReminderId;
}
