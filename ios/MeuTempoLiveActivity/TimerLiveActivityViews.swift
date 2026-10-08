import ActivityKit
import AppIntents
import SwiftUI
import WidgetKit

/// Clock without formatting a duration in Swift: the system draws it.
struct TimerClockText: View {
    let state: TimerActivityAttributes.ContentState

    var body: some View {
        Group {
            if state.isPaused {
                let origin = Date(timeIntervalSinceReferenceDate: 0)
                Text(
                    timerInterval: origin...origin.addingTimeInterval(state.elapsedSeconds + 1),
                    pauseTime: origin.addingTimeInterval(state.elapsedSeconds),
                    countsDown: false
                )
            } else {
                Text(timerInterval: state.clockBase...Date.distantFuture, countsDown: false)
            }
        }
        .monospacedDigit()
        .multilineTextAlignment(.trailing)
        .frame(maxWidth: 120, alignment: .trailing)
    }
}

/// Only draws the `ContentState`; the buttons come from `state.actions`.
struct TimerLockScreenView: View {
    let context: ActivityViewContext<TimerActivityAttributes>

    private var state: TimerActivityAttributes.ContentState { context.state }

    private var subtitle: String {
        state.isPaused
            ? "\(state.listName) · \(LockScreenStrings.paused)"
            : state.listName
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(state.title)
                        .font(.headline)
                        .foregroundStyle(LockScreenPalette.textPrimary)
                        .lineLimit(1)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(LockScreenPalette.textSecondary)
                        .lineLimit(1)
                }
                Spacer(minLength: 8)
                TimerClockText(state: state)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(
                        state.isPaused ? LockScreenPalette.textSecondary : LockScreenPalette.accent
                    )
            }
            HStack(spacing: 8) {
                ForEach(state.actions, id: \.self) { action in
                    actionButton(action)
                }
            }
        }
        .padding(16)
    }

    @ViewBuilder
    private func actionButton(_ action: LockScreenAction) -> some View {
        let targetId = context.attributes.targetId
        switch action {
        case .pause:
            Button(intent: PauseTimerIntent(targetId: targetId)) {
                label(LockScreenStrings.pause)
            }
            .buttonStyle(.bordered)
            .tint(LockScreenPalette.accent)
        case .resume:
            Button(intent: ResumeTimerIntent(targetId: targetId)) {
                label(LockScreenStrings.resume)
            }
            .buttonStyle(.bordered)
            .tint(LockScreenPalette.accent)
        case .stopConfirmed:
            if state.isConfirming {
                Button(intent: ConfirmStopTimerIntent(targetId: targetId)) {
                    label(LockScreenStrings.confirm)
                }
                .buttonStyle(.bordered)
                .tint(LockScreenPalette.danger)
            } else {
                Button(intent: StopTimerIntent(targetId: targetId)) {
                    label(LockScreenStrings.stop)
                }
                .buttonStyle(.bordered)
                .tint(LockScreenPalette.accent)
            }
        }
    }

    private func label(_ text: String) -> some View {
        Text(text).frame(maxWidth: .infinity)
    }
}
