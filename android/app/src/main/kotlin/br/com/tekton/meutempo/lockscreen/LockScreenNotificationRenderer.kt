package br.com.tekton.meutempo.lockscreen

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.SystemClock
import android.view.View
import android.widget.RemoteViews
import br.com.tekton.meutempo.MainActivity
import br.com.tekton.meutempo.R

/** Draws the notification from a ready payload. "Confirming" is visual only. */
object LockScreenNotificationRenderer {
    fun ensureChannel(context: Context) {
        val manager = context.getSystemService(NotificationManager::class.java)
        val channel = NotificationChannel(
            LockScreenContract.NOTIFICATION_CHANNEL_ID,
            context.getString(R.string.lock_screen_channel_name),
            NotificationManager.IMPORTANCE_LOW,
        ).apply {
            description = context.getString(R.string.lock_screen_channel_description)
            setShowBadge(false)
            lockscreenVisibility = Notification.VISIBILITY_PUBLIC
        }
        manager.createNotificationChannel(channel)
    }

    fun build(context: Context, payload: LockScreenTimerPayload, confirming: Boolean): Notification {
        val builder = Notification.Builder(context, LockScreenContract.NOTIFICATION_CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_stat_timer)
            .setColor(context.getColor(R.color.lock_screen_timer_accent))
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setCategory(Notification.CATEGORY_STOPWATCH)
            .setVisibility(Notification.VISIBILITY_PUBLIC)
            .setShowWhen(false)
            .setForegroundServiceBehavior(Notification.FOREGROUND_SERVICE_IMMEDIATE)
            .setStyle(Notification.DecoratedCustomViewStyle())
            .setCustomContentView(buildViews(context, payload))
            .setCustomBigContentView(buildViews(context, payload))
            .setContentIntent(openTargetIntent(context, payload))
            .setDeleteIntent(commandIntent(context, LockScreenServiceCommand.REPOST, payload))

        for (action in payload.actions) {
            when (action) {
                LockScreenAction.PAUSE -> builder.addAction(
                    actionOf(context, R.string.lock_screen_action_pause, LockScreenServiceCommand.PAUSE, payload),
                )
                LockScreenAction.RESUME -> builder.addAction(
                    actionOf(context, R.string.lock_screen_action_resume, LockScreenServiceCommand.RESUME, payload),
                )
                LockScreenAction.STOP_CONFIRMED -> builder.addAction(
                    if (confirming) {
                        actionOf(context, R.string.lock_screen_action_confirm, LockScreenServiceCommand.CONFIRM, payload)
                    } else {
                        actionOf(context, R.string.lock_screen_action_stop, LockScreenServiceCommand.STOP, payload)
                    },
                )
            }
        }
        return builder.build()
    }

    private fun buildViews(context: Context, payload: LockScreenTimerPayload): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.notification_lock_screen_timer)
        views.setTextViewText(R.id.lock_screen_title, payload.title)
        views.setTextViewText(R.id.lock_screen_list, payload.listName)
        // Chronometer counts on the elapsedRealtime base, not wall clock.
        val nowWall = System.currentTimeMillis()
        val nowRealtime = SystemClock.elapsedRealtime()
        if (payload.isPaused) {
            views.setChronometer(R.id.lock_screen_clock, nowRealtime - payload.elapsedMillis, null, false)
        } else {
            views.setChronometer(
                R.id.lock_screen_clock,
                nowRealtime - (nowWall - payload.clockBaseEpochMillis),
                null,
                true,
            )
        }
        views.setViewVisibility(
            R.id.lock_screen_paused_label,
            if (payload.isPaused) View.VISIBLE else View.GONE,
        )
        return views
    }

    private fun actionOf(
        context: Context,
        label: Int,
        command: LockScreenServiceCommand,
        payload: LockScreenTimerPayload,
    ): Notification.Action = Notification.Action.Builder(
        null,
        context.getString(label),
        commandIntent(context, command, payload),
    ).build()

    private fun commandIntent(
        context: Context,
        command: LockScreenServiceCommand,
        payload: LockScreenTimerPayload,
    ): PendingIntent {
        val intent = Intent(context, LockScreenTimerService::class.java)
            .setAction(command.intentAction)
            .putExtra(LockScreenContract.EXTRA_TARGET_ID, payload.targetId)
        return PendingIntent.getService(
            context,
            command.ordinal,
            intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
    }

    private fun openTargetIntent(context: Context, payload: LockScreenTimerPayload): PendingIntent {
        val intent = Intent(context, MainActivity::class.java)
            .addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
            .putExtra(LockScreenContract.EXTRA_TARGET_TYPE, payload.targetType)
            .putExtra(LockScreenContract.EXTRA_TARGET_ID, payload.targetId)
        return PendingIntent.getActivity(
            context,
            LockScreenServiceCommand.entries.size,
            intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
    }
}
