import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../features/reminders/application/reminder_service.dart';
import '../../features/settings/domain/reminder_preferences.dart';
import 'alarm_payload.dart';
import 'notification_content.dart';

/// Carries out the Done / Snooze buttons on a notification.
///
/// Taps on the notification body are not handled here: they open the app and
/// are routed by the UI.
class NotificationActionHandler {
  NotificationActionHandler(this._service, this._preferences);

  final ReminderService _service;
  final ReminderPreferences _preferences;

  Future<void> handle(NotificationResponse response) async {
    final payload = AlarmPayload.tryParse(response.payload);
    if (payload == null) return;

    switch (response.actionId) {
      case actionDone:
        await _service.markDone(payload.reminderId, payload.occurrence);
      case actionSnooze:
        // The current setting, which may differ from the label the
        // notification was armed with if it was changed since.
        await _service.snooze(
          payload.reminderId,
          payload.occurrence,
          Duration(minutes: _preferences.snoozeMinutes),
        );
    }
  }
}
