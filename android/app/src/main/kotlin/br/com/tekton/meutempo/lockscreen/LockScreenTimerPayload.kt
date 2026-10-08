package br.com.tekton.meutempo.lockscreen

import org.json.JSONArray
import org.json.JSONObject

/** Timer drawn on the notification. Comes ready from Dart: no rule here. */
data class LockScreenTimerPayload(
    val targetId: String,
    val targetType: String,
    val title: String,
    val listName: String,
    val status: LockScreenTimerStatus,
    val clockBaseEpochMillis: Long,
    val elapsedMillis: Long,
    val actions: List<LockScreenAction>,
    val stopConfirmationWindowMillis: Long,
) {
    val isPaused: Boolean get() = status == LockScreenTimerStatus.PAUSED

    fun toJson(): String = JSONObject().apply {
        put(LockScreenContract.KEY_TARGET_ID, targetId)
        put(LockScreenContract.KEY_TARGET_TYPE, targetType)
        put(LockScreenContract.KEY_TITLE, title)
        put(LockScreenContract.KEY_LIST_NAME, listName)
        put(LockScreenContract.KEY_STATUS, status.apiValue)
        put(LockScreenContract.KEY_CLOCK_BASE, clockBaseEpochMillis)
        put(LockScreenContract.KEY_ELAPSED, elapsedMillis)
        put(LockScreenContract.KEY_ACTIONS, JSONArray(actions.map { it.apiValue }))
        put(LockScreenContract.KEY_STOP_WINDOW, stopConfirmationWindowMillis)
    }.toString()

    companion object {
        fun fromMap(raw: Any?): LockScreenTimerPayload? {
            val map = raw as? Map<*, *> ?: return null
            val targetId = map[LockScreenContract.KEY_TARGET_ID] as? String
            val targetType = map[LockScreenContract.KEY_TARGET_TYPE] as? String
            val title = map[LockScreenContract.KEY_TITLE] as? String
            val listName = map[LockScreenContract.KEY_LIST_NAME] as? String
            val status = LockScreenTimerStatus.fromApi(map[LockScreenContract.KEY_STATUS] as? String)
            val clockBase = (map[LockScreenContract.KEY_CLOCK_BASE] as? Number)?.toLong()
            val elapsed = (map[LockScreenContract.KEY_ELAPSED] as? Number)?.toLong()
            val window = (map[LockScreenContract.KEY_STOP_WINDOW] as? Number)?.toLong()
            val rawActions = map[LockScreenContract.KEY_ACTIONS] as? List<*>
            if (targetId.isNullOrEmpty() || targetType == null || title == null ||
                listName == null || status == null || clockBase == null ||
                elapsed == null || window == null || rawActions == null
            ) {
                return null
            }
            val actions = rawActions.mapNotNull { LockScreenAction.fromApi(it as? String) }
            return LockScreenTimerPayload(
                targetId, targetType, title, listName, status,
                clockBase, elapsed, actions, window,
            )
        }

        fun fromJson(json: String?): LockScreenTimerPayload? {
            if (json.isNullOrEmpty()) return null
            return try {
                val obj = JSONObject(json)
                val actions = obj.getJSONArray(LockScreenContract.KEY_ACTIONS)
                fromMap(
                    mapOf(
                        LockScreenContract.KEY_TARGET_ID to obj.getString(LockScreenContract.KEY_TARGET_ID),
                        LockScreenContract.KEY_TARGET_TYPE to obj.getString(LockScreenContract.KEY_TARGET_TYPE),
                        LockScreenContract.KEY_TITLE to obj.getString(LockScreenContract.KEY_TITLE),
                        LockScreenContract.KEY_LIST_NAME to obj.getString(LockScreenContract.KEY_LIST_NAME),
                        LockScreenContract.KEY_STATUS to obj.getString(LockScreenContract.KEY_STATUS),
                        LockScreenContract.KEY_CLOCK_BASE to obj.getLong(LockScreenContract.KEY_CLOCK_BASE),
                        LockScreenContract.KEY_ELAPSED to obj.getLong(LockScreenContract.KEY_ELAPSED),
                        LockScreenContract.KEY_ACTIONS to List(actions.length()) { actions.getString(it) },
                        LockScreenContract.KEY_STOP_WINDOW to obj.getLong(LockScreenContract.KEY_STOP_WINDOW),
                    ),
                )
            } catch (_: org.json.JSONException) {
                null
            }
        }
    }
}

/** Tap on the notification body: asks to open the app on the target. */
data class LockScreenTap(val targetType: String, val targetId: String) {
    fun toMap(): Map<String, String> = mapOf(
        LockScreenContract.KEY_TARGET_TYPE to targetType,
        LockScreenContract.KEY_TARGET_ID to targetId,
    )
}
