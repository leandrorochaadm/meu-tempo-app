import Foundation

/// Timer map sent by Dart (`show` and the `handleAction` reply). Tolerant
/// reading: anything invalid returns nil, never crashes. Conversion only, no
/// rules.
struct LockScreenTimerPayload {
    let targetId: String
    let targetType: TimerTargetType
    let title: String
    let listName: String
    let status: LockScreenTimerStatus
    let clockBaseEpochMillis: Int64
    let elapsedMillis: Int64
    let actions: [LockScreenAction]
    let stopConfirmationWindowMillis: Int64

    static func from(_ raw: Any?) -> LockScreenTimerPayload? {
        guard let map = raw as? [String: Any],
              let targetId = map[LockScreenContract.targetId] as? String, !targetId.isEmpty,
              let rawType = map[LockScreenContract.targetType] as? String,
              let targetType = TimerTargetType(rawValue: rawType),
              let title = map[LockScreenContract.title] as? String,
              let listName = map[LockScreenContract.listName] as? String,
              let rawStatus = map[LockScreenContract.status] as? String,
              let status = LockScreenTimerStatus(rawValue: rawStatus),
              let clockBase = (map[LockScreenContract.clockBaseEpochMillis] as? NSNumber)?.int64Value,
              let elapsed = (map[LockScreenContract.elapsedMillis] as? NSNumber)?.int64Value,
              let rawActions = map[LockScreenContract.actions] as? [Any],
              let window = (map[LockScreenContract.stopConfirmationWindowMillis] as? NSNumber)?.int64Value
        else { return nil }

        let actions = rawActions.compactMap { ($0 as? String).flatMap(LockScreenAction.init(rawValue:)) }
        return LockScreenTimerPayload(
            targetId: targetId,
            targetType: targetType,
            title: title,
            listName: listName,
            status: status,
            clockBaseEpochMillis: clockBase,
            elapsedMillis: elapsed,
            actions: actions,
            stopConfirmationWindowMillis: window
        )
    }

    var attributes: TimerActivityAttributes {
        TimerActivityAttributes(targetId: targetId, targetType: targetType)
    }

    func contentState(confirmingUntil: Date?) -> TimerActivityAttributes.ContentState {
        TimerActivityAttributes.ContentState(
            title: title,
            listName: listName,
            status: status,
            clockBase: Date(timeIntervalSince1970: TimeInterval(clockBaseEpochMillis) / 1000),
            elapsedSeconds: TimeInterval(elapsedMillis) / 1000,
            actions: actions,
            stopConfirmationWindowSeconds: TimeInterval(stopConfirmationWindowMillis) / 1000,
            confirmingUntil: confirmingUntil
        )
    }
}
