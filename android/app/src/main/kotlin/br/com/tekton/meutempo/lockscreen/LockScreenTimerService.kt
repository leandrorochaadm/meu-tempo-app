package br.com.tekton.meutempo.lockscreen

import android.app.Notification
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper

/**
 * Foreground service (type specialUse) that keeps the timer notification.
 * No business rule: draws the last payload and relays taps to Dart.
 */
class LockScreenTimerService : Service() {
    private var payload: LockScreenTimerPayload? = null
    private var confirming = false
    private val handler = Handler(Looper.getMainLooper())
    private val confirmExpired = Runnable {
        confirming = false
        redraw()
    }
    private lateinit var store: LockScreenTimerStore
    private var actionEngine: LockScreenActionEngine? = null
    private val engine: LockScreenActionEngine
        get() = actionEngine ?: LockScreenActionEngine(this, ::onEngineReply).also { actionEngine = it }

    override fun onCreate() {
        super.onCreate()
        // Also true when the system recreates the service in a new process, so
        // clear() and show() see it running.
        isActive = true
        store =LockScreenTimerStore(this)
        LockScreenNotificationRenderer.ensureChannel(this)
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent == null) {
            // Recreated by the system: restore the last drawing.
            val restored = store.lastPayload
            if (restored == null) {
                stopSelf()
            } else {
                payload = restored
                confirming = false
                startForegroundWith(restored)
            }
            return START_STICKY
        }
        val targetId = intent.getStringExtra(LockScreenContract.EXTRA_TARGET_ID)
        when (LockScreenServiceCommand.fromIntentAction(intent.action)) {
            LockScreenServiceCommand.SHOW -> onShow(intent)
            LockScreenServiceCommand.CLEAR -> removeAndStop()
            LockScreenServiceCommand.PAUSE -> relay(LockScreenAction.PAUSE, targetId)
            LockScreenServiceCommand.RESUME -> relay(LockScreenAction.RESUME, targetId)
            LockScreenServiceCommand.STOP -> onStop()
            LockScreenServiceCommand.CONFIRM -> onConfirm(targetId)
            LockScreenServiceCommand.CONFIRM_EXPIRED -> confirmExpired.run()
            LockScreenServiceCommand.REPOST -> redraw()
            null -> Unit
        }
        return START_STICKY
    }

    override fun onDestroy() {
        handler.removeCallbacks(confirmExpired)
        actionEngine?.destroy()
        isActive = false
        super.onDestroy()
    }

    private fun onShow(intent: Intent) {
        val next = LockScreenTimerPayload.fromJson(
            intent.getStringExtra(LockScreenContract.EXTRA_PAYLOAD_JSON),
        )
        if (next == null) {
            if (payload == null) stopSelf()
            return
        }
        val previous = payload
        // Confirming only survives when it is the same target and status.
        if (previous == null || previous.targetId != next.targetId || previous.status != next.status) {
            confirming = false
            handler.removeCallbacks(confirmExpired)
        }
        payload = next
        startForegroundWith(next)
    }

    private fun relay(action: LockScreenAction, targetId: String?) {
        confirming = false
        handler.removeCallbacks(confirmExpired)
        if (targetId == null) return
        engine.dispatch(action, targetId)
    }

    private fun onStop() {
        val current = payload ?: return
        confirming = true
        redraw()
        handler.removeCallbacks(confirmExpired)
        handler.postDelayed(confirmExpired, current.stopConfirmationWindowMillis)
    }

    private fun onConfirm(targetId: String?) {
        val current = payload
        if (!confirming || current == null || targetId != current.targetId) {
            // Late tap after the window: nothing changes.
            confirming = false
            redraw()
            return
        }
        handler.removeCallbacks(confirmExpired)
        engine.dispatch(LockScreenAction.STOP_CONFIRMED, current.targetId)
    }

    private fun onEngineReply(reply: LockScreenReply, timer: LockScreenTimerPayload?) {
        when (reply) {
            LockScreenReply.SHOW -> {
                if (timer == null) return
                payload = timer
                store.lastPayload = timer
                confirming = false
                handler.removeCallbacks(confirmExpired)
                startForegroundWith(timer)
            }
            LockScreenReply.CLEAR -> {
                store.lastPayload = null
                removeAndStop()
            }
            LockScreenReply.UNCHANGED -> {
                confirming = false
                handler.removeCallbacks(confirmExpired)
                redraw()
            }
        }
    }

    private fun redraw() {
        val current = payload ?: return
        startForegroundWith(current)
    }

    private fun startForegroundWith(current: LockScreenTimerPayload) {
        val notification: Notification =
            LockScreenNotificationRenderer.build(this, current, confirming)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            startForeground(
                LockScreenContract.NOTIFICATION_ID,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE,
            )
        } else {
            startForeground(LockScreenContract.NOTIFICATION_ID, notification)
        }
    }

    private fun removeAndStop() {
        handler.removeCallbacks(confirmExpired)
        payload = null
        confirming = false
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    companion object {
        @Volatile
        var isActive = false
            private set

        /** Starts or updates the service. Throws if the system refuses (background start). */
        fun show(context: Context, payload: LockScreenTimerPayload) {
            val app = context.applicationContext
            LockScreenTimerStore(app).lastPayload = payload
            val intent = Intent(app, LockScreenTimerService::class.java)
                .setAction(LockScreenServiceCommand.SHOW.intentAction)
                .putExtra(LockScreenContract.EXTRA_PAYLOAD_JSON, payload.toJson())
            if (isActive) {
                app.startService(intent)
                return
            }
            isActive = true
            try {
                app.startForegroundService(intent)
            } catch (error: RuntimeException) {
                isActive = false
                throw error
            }
        }

        /**
         * Never uses stopService: stopping before startForeground crashes the app.
         * The CLEAR command runs after SHOW, which already called startForeground.
         */
        fun clear(context: Context) {
            val app = context.applicationContext
            LockScreenTimerStore(app).lastPayload = null
            if (!isActive) return
            val intent = Intent(app, LockScreenTimerService::class.java)
                .setAction(LockScreenServiceCommand.CLEAR.intentAction)
            app.startService(intent)
        }
    }
}
