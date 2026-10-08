import ActivityKit
import Foundation

/// Draws the Live Activity. Nothing here decides what an action does: that is
/// Dart's job (reached through `LockScreenActionEngine`).
@MainActor
final class LiveActivityController {
    static let shared = LiveActivityController()

    private var confirmingUntil: Date?
    private var isConfirmingStop = false

    private var current: Activity<TimerActivityAttributes>? {
        Activity<TimerActivityAttributes>.activities.first {
            $0.activityState == .active || $0.activityState == .stale
        }
    }

    // MARK: - Draw

    func show(_ payload: LockScreenTimerPayload) async throws {
        if let activity = current, activity.attributes.targetId == payload.targetId {
            let keep = activity.content.state.status == payload.status ? confirmingUntil : nil
            confirmingUntil = keep
            await activity.update(ActivityContent(state: payload.contentState(confirmingUntil: keep), staleDate: nil))
            return
        }
        await endAll()
        confirmingUntil = nil
        isConfirmingStop = false
        _ = try Activity.request(
            attributes: payload.attributes,
            content: ActivityContent(state: payload.contentState(confirmingUntil: nil), staleDate: nil),
            pushType: nil
        )
    }

    func clear() async {
        confirmingUntil = nil
        isConfirmingStop = false
        await endAll()
    }

    private func endAll() async {
        for activity in Activity<TimerActivityAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }

    private func redraw(_ activity: Activity<TimerActivityAttributes>, confirmingUntil: Date?) async {
        var state = activity.content.state
        state.confirmingUntil = confirmingUntil
        await activity.update(ActivityContent(state: state, staleDate: nil))
    }

    // MARK: - Buttons

    /// Pause / resume.
    func perform(_ action: LockScreenAction, targetId: String) async {
        confirmingUntil = nil
        isConfirmingStop = false
        let outcome = await LockScreenActionEngine.shared.dispatch(action, targetId: targetId)
        await apply(outcome)
    }

    /// First tap on "Parar": shows "Confirmar" for the window.
    func beginStopConfirmation(targetId: String) async {
        guard let activity = current, activity.attributes.targetId == targetId else { return }
        let until = Date().addingTimeInterval(activity.content.state.stopConfirmationWindowSeconds)
        confirmingUntil = until
        await redraw(activity, confirmingUntil: until)

        let window = activity.content.state.stopConfirmationWindowSeconds
        try? await Task.sleep(for: .seconds(window))
        guard confirmingUntil == until, !isConfirmingStop, let still = current else { return }
        confirmingUntil = nil
        await redraw(still, confirmingUntil: nil)
    }

    /// Second tap: only valid for the same target and inside the window.
    func confirmStop(targetId: String) async {
        guard let activity = current, activity.attributes.targetId == targetId else { return }
        guard let until = confirmingUntil, until > Date() else {
            confirmingUntil = nil
            await redraw(activity, confirmingUntil: nil)
            return
        }
        isConfirmingStop = true
        let outcome = await LockScreenActionEngine.shared.dispatch(.stopConfirmed, targetId: targetId)
        await apply(outcome)
    }

    private func apply(_ outcome: LockScreenActionOutcome) async {
        isConfirmingStop = false
        switch outcome {
        case .show(let payload):
            confirmingUntil = nil
            try? await show(payload)
        case .clear:
            await clear()
        case .unchanged:
            confirmingUntil = nil
            if let activity = current {
                await redraw(activity, confirmingUntil: nil)
            }
        }
    }
}
