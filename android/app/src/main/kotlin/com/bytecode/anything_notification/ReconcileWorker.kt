package com.bytecode.anything_notification

import android.content.Context
import android.os.Handler
import android.os.Looper
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.ExistingWorkPolicy
import androidx.work.OneTimeWorkRequest
import androidx.work.PeriodicWorkRequest
import androidx.work.WorkManager
import androidx.work.Worker
import androidx.work.WorkerParameters
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit

/**
 * Re-arms every reminder notification by running the app's Dart
 * `reconcileEntrypoint` in a headless Flutter engine (no UI).
 *
 * Alarms are lost when the device reboots, when the app is force-stopped, and
 * are wrong after a time or time zone change, so this runs after those events
 * and also periodically as a safety net.
 */
class ReconcileWorker(context: Context, params: WorkerParameters) :
    Worker(context, params) {

    @Volatile
    private var engine: FlutterEngine? = null

    override fun doWork(): Result {
        val finished = CountDownLatch(1)
        val main = Handler(Looper.getMainLooper())

        main.post {
            val loader = FlutterInjector.instance().flutterLoader()
            loader.startInitialization(applicationContext)
            loader.ensureInitializationCompleteAsync(applicationContext, null, main) {
                val flutterEngine = FlutterEngine(applicationContext)
                engine = flutterEngine
                MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
                    .setMethodCallHandler { call, result ->
                        if (call.method == "done") {
                            result.success(null)
                            destroyEngine()
                            finished.countDown()
                        } else {
                            result.notImplemented()
                        }
                    }
                flutterEngine.dartExecutor.executeDartEntrypoint(
                    DartExecutor.DartEntrypoint(
                        loader.findAppBundlePath(),
                        "reconcileEntrypoint",
                    ),
                )
            }
        }

        val completed = finished.await(TIMEOUT_SECONDS, TimeUnit.SECONDS)
        if (!completed) main.post { destroyEngine() }
        return if (completed) Result.success() else Result.retry()
    }

    private fun destroyEngine() {
        engine?.destroy()
        engine = null
    }

    companion object {
        private const val CHANNEL = "com.bytecode.anything_notification/reconcile"
        private const val TIMEOUT_SECONDS = 90L
        private const val NOW_WORK = "reconcile-now"
        private const val PERIODIC_WORK = "reconcile-periodic"

        /** Re-arm as soon as possible; queued behind a run already in progress. */
        fun runNow(context: Context) {
            WorkManager.getInstance(context).enqueueUniqueWork(
                NOW_WORK,
                ExistingWorkPolicy.APPEND_OR_REPLACE,
                OneTimeWorkRequest.Builder(ReconcileWorker::class.java).build(),
            )
        }

        /** Safety net: re-arm every few hours even if no event arrives. */
        fun ensurePeriodic(context: Context) {
            WorkManager.getInstance(context).enqueueUniquePeriodicWork(
                PERIODIC_WORK,
                ExistingPeriodicWorkPolicy.KEEP,
                PeriodicWorkRequest.Builder(
                    ReconcileWorker::class.java,
                    6,
                    TimeUnit.HOURS,
                ).build(),
            )
        }
    }
}
