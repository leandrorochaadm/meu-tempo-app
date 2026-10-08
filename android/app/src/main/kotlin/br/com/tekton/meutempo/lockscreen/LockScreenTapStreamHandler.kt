package br.com.tekton.meutempo.lockscreen

import android.content.Intent
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel

/**
 * Delivers taps on the notification body to Dart. Keeps the tap that opened
 * the app until the first subscriber arrives.
 */
class LockScreenTapStreamHandler(messenger: BinaryMessenger) : EventChannel.StreamHandler {
    private var sink: EventChannel.EventSink? = null
    private var pending: LockScreenTap? = null

    init {
        EventChannel(messenger, LockScreenContract.TAP_CHANNEL).setStreamHandler(this)
    }

    fun offer(intent: Intent?) {
        if (intent == null) return
        val targetType = intent.getStringExtra(LockScreenContract.EXTRA_TARGET_TYPE)
        val targetId = intent.getStringExtra(LockScreenContract.EXTRA_TARGET_ID)
        if (targetType == null || targetId == null) return
        // Always consume the extras so a recreation does not repeat the tap.
        intent.removeExtra(LockScreenContract.EXTRA_TARGET_TYPE)
        intent.removeExtra(LockScreenContract.EXTRA_TARGET_ID)
        // Reopening from recents must not repeat the tap.
        if (intent.flags and Intent.FLAG_ACTIVITY_LAUNCHED_FROM_HISTORY != 0) return
        val tap = LockScreenTap(targetType, targetId)
        val current = sink
        if (current != null) current.success(tap.toMap()) else pending = tap
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        sink = events
        pending?.let { events?.success(it.toMap()) }
        pending = null
    }

    override fun onCancel(arguments: Any?) {
        sink = null
    }
}
