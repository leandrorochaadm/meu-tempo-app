package br.com.tekton.meutempo.lockscreen

enum class LockScreenAction(val apiValue: String) {
    PAUSE("pause"),
    RESUME("resume"),
    STOP_CONFIRMED("stop_confirmed");

    companion object {
        fun fromApi(raw: String?): LockScreenAction? = entries.firstOrNull { it.apiValue == raw }
    }
}

enum class LockScreenReply(val apiValue: String) {
    SHOW("show"),
    CLEAR("clear"),
    UNCHANGED("unchanged");

    companion object {
        fun fromApi(raw: String?): LockScreenReply? = entries.firstOrNull { it.apiValue == raw }
    }
}

enum class LockScreenTimerStatus(val apiValue: String) {
    RUNNING("running"),
    PAUSED("paused");

    companion object {
        fun fromApi(raw: String?): LockScreenTimerStatus? = entries.firstOrNull { it.apiValue == raw }
    }
}

enum class LockScreenPermissionStatus(val apiValue: String) {
    GRANTED("granted"),
    DENIED("denied"),
    NOT_REQUESTED("not_requested");

    companion object {
        fun fromApi(raw: String?): LockScreenPermissionStatus? = entries.firstOrNull { it.apiValue == raw }
    }
}

enum class LockScreenServiceCommand {
    SHOW,
    CLEAR,
    PAUSE,
    RESUME,
    STOP,
    CONFIRM,
    CONFIRM_EXPIRED,
    REPOST;

    val intentAction: String get() = "br.com.tekton.meutempo.lockscreen.$name"

    companion object {
        fun fromIntentAction(raw: String?): LockScreenServiceCommand? =
            entries.firstOrNull { it.intentAction == raw }
    }
}
