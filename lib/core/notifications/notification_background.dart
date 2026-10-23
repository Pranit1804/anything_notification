import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../app/app_container.dart';
import 'notification_action_handler.dart';
import 'refresh_port.dart';

/// Runs when a notification's Done / Snooze button is pressed, possibly with
/// the app not running at all: a fresh isolate with no UI.
@pragma('vm:entry-point')
Future<void> notificationBackgroundHandler(
  NotificationResponse response,
) async {
  DartPluginRegistrant.ensureInitialized();

  try {
    final container = await AppContainer.create();
    try {
      await NotificationActionHandler(
        container.service,
        container.settings,
      ).handle(response);
    } finally {
      await container.dispose();
    }
    RefreshPort.notify();
  } on Object catch (error, stackTrace) {
    // There is no UI to show this in, and an uncaught error in a background
    // isolate would vanish: leave a trace in the log.
    debugPrint(
      'Notification action "${response.actionId}" failed: $error\n$stackTrace',
    );
  }
}
