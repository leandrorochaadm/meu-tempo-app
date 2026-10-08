package br.com.tekton.meutempo.lockscreen

/**
 * Names that cross the Dart/native border. Mirrors
 * `lock_screen_timer_channel_constants.dart`,
 * `lock_screen_timer_channel_method_enum.dart` and
 * `lock_screen_channel_constants.dart`: change both sides together.
 */
object LockScreenContract {
    const val TIMER_CHANNEL = "br.com.tekton.meutempo/lock_screen_timer"
    const val TAP_CHANNEL = "br.com.tekton.meutempo/lock_screen_taps"
    const val ACTION_CHANNEL = "br.com.tekton.meutempo/lock_screen_action"
    const val ENTRYPOINT = "lockScreenActionMain"

    // Timer channel methods (Dart -> native).
    const val METHOD_SHOW = "show"
    const val METHOD_CLEAR = "clear"
    const val METHOD_GET_PERMISSION_STATUS = "getPermissionStatus"
    const val METHOD_REQUEST_PERMISSION = "requestPermission"
    const val METHOD_OPEN_NOTIFICATION_SETTINGS = "openNotificationSettings"

    // Action channel methods.
    const val METHOD_BACKGROUND_READY = "backgroundReady"
    const val METHOD_BACKGROUND_FAILED = "backgroundFailed"
    const val METHOD_HANDLE_ACTION = "handleAction"

    // Payload keys.
    const val KEY_TARGET_ID = "targetId"
    const val KEY_TARGET_TYPE = "targetType"
    const val KEY_TITLE = "title"
    const val KEY_LIST_NAME = "listName"
    const val KEY_STATUS = "status"
    const val KEY_CLOCK_BASE = "clockBaseEpochMillis"
    const val KEY_ELAPSED = "elapsedMillis"
    const val KEY_ACTIONS = "actions"
    const val KEY_STOP_WINDOW = "stopConfirmationWindowMillis"
    const val KEY_ACTION = "action"
    const val KEY_REPLY = "reply"
    const val KEY_TIMER = "timer"

    // Time limits (contract with the Dart background entrypoint).
    const val ENGINE_READY_TIMEOUT_MS = 20_000L
    const val ACTION_REPLY_TIMEOUT_MS = 20_000L
    const val ENGINE_IDLE_MS = 60_000L

    const val NOTIFICATION_ID = 4101
    const val NOTIFICATION_CHANNEL_ID = "lock_screen_timer"

    // Preferences.
    const val PREFS_NAME = "lock_screen_timer"
    const val PREF_PAYLOAD_JSON = "payload_json"
    const val PREF_PERMISSION_REQUESTED = "permission_requested"

    // Intent extras.
    const val EXTRA_PAYLOAD_JSON = "payload_json"
    const val EXTRA_TARGET_ID = KEY_TARGET_ID
    const val EXTRA_TARGET_TYPE = KEY_TARGET_TYPE

    const val LOG_TAG = "MeuTempoLockScreen"
}
