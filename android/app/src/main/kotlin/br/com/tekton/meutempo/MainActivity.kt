package br.com.tekton.meutempo

import android.content.Intent
import br.com.tekton.meutempo.lockscreen.LockScreenTapStreamHandler
import br.com.tekton.meutempo.lockscreen.LockScreenTimerChannel
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private var timerChannel: LockScreenTimerChannel? = null
    private var tapStreamHandler: LockScreenTapStreamHandler? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        timerChannel = LockScreenTimerChannel(this, messenger)
        tapStreamHandler = LockScreenTapStreamHandler(messenger).also { it.offer(intent) }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        tapStreamHandler?.offer(intent)
    }

    override fun onResume() {
        super.onResume()
        timerChannel?.onResumedChanged(true)
    }

    override fun onPause() {
        timerChannel?.onResumedChanged(false)
        super.onPause()
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        timerChannel?.onRequestPermissionsResult(requestCode, grantResults)
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        timerChannel?.dispose()
        timerChannel = null
        tapStreamHandler = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
