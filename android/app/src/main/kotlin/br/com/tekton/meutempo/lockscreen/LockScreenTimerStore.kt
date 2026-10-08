package br.com.tekton.meutempo.lockscreen

import android.content.Context

/**
 * Own preferences: lets the service redraw itself after the system recreates
 * it, and remembers whether the permission was already asked.
 */
class LockScreenTimerStore(context: Context) {
    private val prefs = context.applicationContext
        .getSharedPreferences(LockScreenContract.PREFS_NAME, Context.MODE_PRIVATE)

    var lastPayload: LockScreenTimerPayload?
        get() = LockScreenTimerPayload.fromJson(
            prefs.getString(LockScreenContract.PREF_PAYLOAD_JSON, null),
        )
        set(value) {
            prefs.edit().apply {
                if (value == null) remove(LockScreenContract.PREF_PAYLOAD_JSON)
                else putString(LockScreenContract.PREF_PAYLOAD_JSON, value.toJson())
            }.apply()
        }

    var permissionRequested: Boolean
        get() = prefs.getBoolean(LockScreenContract.PREF_PERMISSION_REQUESTED, false)
        set(value) {
            prefs.edit().putBoolean(LockScreenContract.PREF_PERMISSION_REQUESTED, value).apply()
        }
}
