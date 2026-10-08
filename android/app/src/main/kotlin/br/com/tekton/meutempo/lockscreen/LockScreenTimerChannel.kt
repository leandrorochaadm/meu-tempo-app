package br.com.tekton.meutempo.lockscreen

import android.app.Activity
import android.util.Log
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler

/** Timer channel of the main engine (app open). Relays; no rule. */
class LockScreenTimerChannel(
    private val activity: Activity,
    messenger: BinaryMessenger,
) : MethodCallHandler {
    private val channel = MethodChannel(messenger, LockScreenContract.TIMER_CHANNEL)
    private val permission = LockScreenPermission(activity, LockScreenTimerStore(activity))

    init {
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            LockScreenContract.METHOD_SHOW -> show(call.arguments, result)
            LockScreenContract.METHOD_CLEAR -> {
                LockScreenTimerService.clear(activity)
                result.success(null)
            }
            LockScreenContract.METHOD_GET_PERMISSION_STATUS ->
                result.success(permission.status().apiValue)
            LockScreenContract.METHOD_REQUEST_PERMISSION -> permission.request(result)
            LockScreenContract.METHOD_OPEN_NOTIFICATION_SETTINGS -> {
                permission.openSettings()
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun show(arguments: Any?, result: MethodChannel.Result) {
        val payload = LockScreenTimerPayload.fromMap(arguments)
        if (payload == null) {
            result.error("invalid_payload", "Invalid lock screen payload", null)
            return
        }
        try {
            LockScreenTimerService.show(activity, payload)
            result.success(null)
        } catch (error: RuntimeException) {
            Log.w(LockScreenContract.LOG_TAG, "show refused: ${error.javaClass.simpleName}")
            result.error("fgs_not_allowed", "Foreground service start refused", null)
        }
    }

    fun onRequestPermissionsResult(requestCode: Int, grantResults: IntArray) =
        permission.onRequestPermissionsResult(requestCode, grantResults)

    fun onResumedChanged(resumed: Boolean) {
        permission.isResumed = resumed
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
        permission.dispose()
    }
}
