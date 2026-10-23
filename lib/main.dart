import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/app.dart';
import 'app/app_container.dart';
import 'app/app_dependencies.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  final dependencies = await AppContainer.createForUi();
  runApp(App(dependencies: dependencies));

  // A cold start is the moment alarms may have been lost silently (force
  // stop, app data restore), so arm everything again. Safe to repeat.
  unawaited(_startupMaintenance(dependencies));
}

Future<void> _startupMaintenance(AppDependencies dependencies) async {
  try {
    await dependencies.reminderService.settleMissed();
    await dependencies.scheduler.reconcile(rearmAll: true);
  } on Object catch (error) {
    debugPrint('Startup maintenance failed: $error');
  }
}

/// Entry point for the native boot / time-change / periodic worker
/// (`ReconcileWorker`): re-arms every notification with no UI.
@pragma('vm:entry-point')
Future<void> reconcileEntrypoint() async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  const channel = MethodChannel('com.bytecode.anything_notification/reconcile');
  try {
    final container = await AppContainer.create();
    try {
      await container.service.settleMissed();
      await container.scheduler.reconcile(rearmAll: true);
    } finally {
      await container.dispose();
    }
  } on Object catch (error) {
    debugPrint('Background reconcile failed: $error');
  } finally {
    // Always tell the worker we are done, or it would wait for its timeout.
    await channel.invokeMethod<void>('done');
  }
}
