package br.com.tekton.meutempo.lockscreen

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel

/**
 * Takes a button tap to the Dart background entrypoint and returns the reply.
 * Runs on the main thread. Relays only: the rule lives in Dart.
 */
class LockScreenActionEngine(
    context: Context,
    private val onReply: (LockScreenReply, LockScreenTimerPayload?) -> Unit,
) {
    private class Request(val action: LockScreenAction, val targetId: String)

    private val appContext = context.applicationContext
    private val handler = Handler(Looper.getMainLooper())
    private val queue = ArrayDeque<Request>()
    private var engine: FlutterEngine? = null
    private var channel: MethodChannel? = null
    private var ready = false
    private var inFlight: Request? = null

    private val readyTimeout = Runnable {
        Log.w(LockScreenContract.LOG_TAG, "background engine did not get ready")
        failAll()
    }
    private val replyTimeout = Runnable {
        Log.w(LockScreenContract.LOG_TAG, "action reply timed out")
        finishCurrent(LockScreenReply.UNCHANGED, null)
    }
    private val idleTimeout = Runnable { destroy() }

    fun dispatch(action: LockScreenAction, targetId: String) {
        handler.removeCallbacks(idleTimeout)
        Log.d(LockScreenContract.LOG_TAG, "dispatch ${action.apiValue}")
        queue.addLast(Request(action, targetId))
        if (engine == null) startEngine() else pump()
    }

    fun destroy() {
        handler.removeCallbacks(readyTimeout)
        handler.removeCallbacks(replyTimeout)
        handler.removeCallbacks(idleTimeout)
        channel?.setMethodCallHandler(null)
        channel = null
        engine?.destroy()
        engine = null
        ready = false
        inFlight = null
    }

    private fun startEngine() {
        val loader = FlutterInjector.instance().flutterLoader()
        loader.startInitialization(appContext)
        loader.ensureInitializationComplete(appContext, null)
        val newEngine = FlutterEngine(appContext)
        engine = newEngine
        val newChannel = MethodChannel(newEngine.dartExecutor.binaryMessenger, LockScreenContract.ACTION_CHANNEL)
        newChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                LockScreenContract.METHOD_BACKGROUND_READY -> {
                    result.success(null)
                    handler.removeCallbacks(readyTimeout)
                    ready = true
                    pump()
                }
                LockScreenContract.METHOD_BACKGROUND_FAILED -> {
                    result.success(null)
                    failAll()
                }
                else -> result.notImplemented()
            }
        }
        channel = newChannel
        handler.postDelayed(readyTimeout, LockScreenContract.ENGINE_READY_TIMEOUT_MS)
        newEngine.dartExecutor.executeDartEntrypoint(
            DartExecutor.DartEntrypoint(loader.findAppBundlePath(), LockScreenContract.ENTRYPOINT),
        )
    }

    private fun pump() {
        if (!ready || inFlight != null) return
        val request = queue.removeFirstOrNull() ?: run {
            handler.postDelayed(idleTimeout, LockScreenContract.ENGINE_IDLE_MS)
            return
        }
        inFlight = request
        handler.postDelayed(replyTimeout, LockScreenContract.ACTION_REPLY_TIMEOUT_MS)
        val args = mapOf(
            LockScreenContract.KEY_ACTION to request.action.apiValue,
            LockScreenContract.KEY_TARGET_ID to request.targetId,
        )
        channel?.invokeMethod(
            LockScreenContract.METHOD_HANDLE_ACTION,
            args,
            object : MethodChannel.Result {
                override fun success(result: Any?) {
                    if (inFlight !== request) return // late reply: ignored
                    val map = result as? Map<*, *>
                    val reply = LockScreenReply.fromApi(map?.get(LockScreenContract.KEY_REPLY) as? String)
                        ?: LockScreenReply.UNCHANGED
                    val timer = LockScreenTimerPayload.fromMap(map?.get(LockScreenContract.KEY_TIMER))
                    if (reply == LockScreenReply.SHOW && timer == null) {
                        finishCurrent(LockScreenReply.UNCHANGED, null)
                    } else {
                        finishCurrent(reply, timer)
                    }
                }

                override fun error(code: String, message: String?, details: Any?) {
                    if (inFlight === request) finishCurrent(LockScreenReply.UNCHANGED, null)
                }

                override fun notImplemented() {
                    if (inFlight === request) finishCurrent(LockScreenReply.UNCHANGED, null)
                }
            },
        )
    }

    private fun finishCurrent(reply: LockScreenReply, timer: LockScreenTimerPayload?) {
        handler.removeCallbacks(replyTimeout)
        inFlight = null
        Log.d(LockScreenContract.LOG_TAG, "reply ${reply.apiValue}")
        onReply(reply, timer)
        pump()
    }

    private fun failAll() {
        handler.removeCallbacks(readyTimeout)
        handler.removeCallbacks(replyTimeout)
        val count = queue.size + if (inFlight != null) 1 else 0
        queue.clear()
        inFlight = null
        destroy()
        repeat(count) { onReply(LockScreenReply.UNCHANGED, null) }
    }
}
