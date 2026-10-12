package br.com.tekton.meutempo.lockscreen

import android.Manifest
import android.app.Activity
import android.app.NotificationManager
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.provider.Settings
import io.flutter.plugin.common.MethodChannel

/** Reads and asks the notification permission. Reads system state; no rule. */
class LockScreenPermission(
    private val activity: Activity,
    private val store: LockScreenTimerStore,
) {
    var isResumed = false

    private var pending: MethodChannel.Result? = null

    fun status(): LockScreenPermissionStatus {
        val manager = activity.getSystemService(NotificationManager::class.java)
        val channel = manager.getNotificationChannel(LockScreenContract.NOTIFICATION_CHANNEL_ID)
        val channelOn = channel == null || channel.importance != NotificationManager.IMPORTANCE_NONE
        // Below Android 13 there is no runtime permission: notifications start enabled.
        val granted = !canAsk() ||
            activity.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) ==
            PackageManager.PERMISSION_GRANTED
        return when {
            granted && manager.areNotificationsEnabled() && channelOn -> LockScreenPermissionStatus.GRANTED
            canAsk() && !store.permissionRequested -> LockScreenPermissionStatus.NOT_REQUESTED
            else -> LockScreenPermissionStatus.DENIED
        }
    }

    fun request(result: MethodChannel.Result) {
        val noDialog = !canAsk() || status() == LockScreenPermissionStatus.GRANTED
        if (noDialog || !isResumed || pending != null) {
            result.success(status().apiValue)
            return
        }
        pending = result
        activity.requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), REQUEST_CODE)
    }

    fun onRequestPermissionsResult(requestCode: Int, grantResults: IntArray) {
        if (requestCode != REQUEST_CODE) return
        // Only a real answer counts as "asked"; empty means the system cancelled.
        if (grantResults.isNotEmpty()) store.permissionRequested = true
        answerPending()
    }

    fun dispose() = answerPending()

    fun openSettings() {
        val intent = Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
            .putExtra(Settings.EXTRA_APP_PACKAGE, activity.packageName)
        activity.startActivity(intent)
    }

    private fun canAsk() = Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU

    private fun answerPending() {
        val result = pending ?: return
        pending = null
        result.success(status().apiValue)
    }

    private companion object {
        const val REQUEST_CODE = 4102
    }
}
