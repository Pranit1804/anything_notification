package com.bytecode.anything_notification

import android.app.KeyguardManager
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        ReconcileWorker.ensurePeriodic(applicationContext)
        showOverLockScreenIfLocked()
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        showOverLockScreenIfLocked()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SYSTEM_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "openBatterySettings" -> {
                        openBatterySettings()
                        result.success(null)
                    }
                    "canUseFullScreenIntent" -> result.success(canUseFullScreenIntent())
                    "finishAlarm" -> {
                        finishAlarm()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    /**
     * An alarm-style reminder launches the app while the phone is locked.
     * Only then is the app shown over the lock screen with the screen turned
     * on. Doing this as permanent activity attributes would show the whole app
     * over the lock screen on every launch.
     */
    private fun showOverLockScreenIfLocked() {
        val keyguard = getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
        if (!keyguard.isKeyguardLocked) return
        setOverLockScreen(true)
    }

    private fun setOverLockScreen(enabled: Boolean) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(enabled)
            setTurnScreenOn(enabled)
        } else {
            val flags = WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
            if (enabled) window.addFlags(flags) else window.clearFlags(flags)
        }
    }

    /** Whether the user allows alarm-style reminders to take over the screen. */
    private fun canUseFullScreenIntent(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.UPSIDE_DOWN_CAKE) return true
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        return manager.canUseFullScreenIntent()
    }

    /** The alarm was handled: stop covering the lock screen and go back to it. */
    private fun finishAlarm() {
        setOverLockScreen(false)
        val keyguard = getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
        if (keyguard.isKeyguardLocked) moveTaskToBack(true)
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
