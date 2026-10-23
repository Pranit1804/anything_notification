package com.bytecode.anything_notification

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * Re-arms reminders after events that silently invalidate scheduled alarms:
 * reboot, app update, time or time zone change, or exact-alarm permission
 * being granted or revoked.
 */
class SystemEventReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        ReconcileWorker.runNow(context.applicationContext)
    }
}
