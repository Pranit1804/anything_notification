package com.bytecode.anything_notification

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        ReconcileWorker.ensurePeriodic(applicationContext)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SYSTEM_CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "openBatterySettings") {
                    openBatterySettings()
                    result.success(null)
                } else {
                    result.notImplemented()
                }
            }
    }

    /**
     * Opens the battery optimisation list, where the app can be set to run
     * unrestricted. This only opens the screen (it does not request an
     * exemption); if a phone lacks it, the app's own details page is used.
     */
    private fun openBatterySettings() {
        val list = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
        val details = Intent(
            Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
            Uri.parse("package:$packageName"),
        )
        try {
            startActivity(list)
        } catch (_: Exception) {
            startActivity(details)
        }
    }

    private companion object {
        const val SYSTEM_CHANNEL = "com.bytecode.anything_notification/system"
    }
}
