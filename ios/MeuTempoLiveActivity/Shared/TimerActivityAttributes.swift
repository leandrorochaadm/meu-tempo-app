import ActivityKit
import Foundation

/// Data of the Live Activity. The target is fixed (attributes); what changes
/// lives in `ContentState`. No rules: Dart already sends `status`, `actions`
/// and the clock base ready.
/// Target membership: MeuTempoLiveActivity and Runner.
struct TimerActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var title: String
        var listName: String
        var status: LockScreenTimerStatus
        /// Running: instant the clock would read 00:00 (includes time already spent).
        var clockBase: Date
        /// Paused: fixed elapsed time shown.
        var elapsedSeconds: TimeInterval
        /// Buttons, in display order, exactly as sent by Dart.
        var actions: [LockScreenAction]
        var stopConfirmationWindowSeconds: TimeInterval
        /// Visual state after the first "Parar" tap; nil = not confirming.
        var confirmingUntil: Date?

        var isPaused: Bool { status == .paused }
        var isConfirming: Bool { confirmingUntil != nil }
    }

    let targetId: String
    let targetType: TimerTargetType
}
