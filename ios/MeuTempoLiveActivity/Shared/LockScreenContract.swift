import Foundation

/// Constants of the lock screen protocol. Mirrors
/// `lock_screen_timer_channel_constants.dart` and
/// `lock_screen_channel_constants.dart` (Dart): changing a name there requires
/// changing it here. Method names live in `LockScreenEnums.swift`.
/// Target membership: MeuTempoLiveActivity and Runner.
enum LockScreenContract {
    static let timerChannel = "br.com.tekton.meutempo/lock_screen_timer"
    static let tapChannel = "br.com.tekton.meutempo/lock_screen_taps"
    static let actionChannel = "br.com.tekton.meutempo/lock_screen_action"
    static let entrypoint = "lockScreenActionMain"
    static let engineName = "lock_screen_action"
    static let pluginKey = "LockScreenTimerPlugin"

    // Payload keys.
    static let targetId = "targetId"
    static let targetType = "targetType"
    static let title = "title"
    static let listName = "listName"
    static let status = "status"
    static let clockBaseEpochMillis = "clockBaseEpochMillis"
    static let elapsedMillis = "elapsedMillis"
    static let actions = "actions"
    static let stopConfirmationWindowMillis = "stopConfirmationWindowMillis"
    static let action = "action"
    static let reply = "reply"
    static let timer = "timer"

    // Channel error codes.
    static let invalidPayload = "invalid_payload"
    static let activityFailed = "activity_failed"

    // Deadlines (same as Android).
    static let engineReadyTimeout: Duration = .seconds(20)
    static let actionReplyTimeout: Duration = .seconds(20)
    static let engineIdle: Duration = .seconds(60)

    // Tap URL: meutempo://timer-target?type=<task|appointment>&id=<id>
    static let tapScheme = "meutempo"
    static let tapHost = "timer-target"
    static let tapTypeQuery = "type"
    static let tapIdQuery = "id"

    // Log.
    static let logSubsystem = "br.com.tekton.meutempo"
    static let logCategory = "LockScreen"

    static func tapURL(targetType: TimerTargetType, targetId: String) -> URL {
        var components = URLComponents()
        components.scheme = tapScheme
        components.host = tapHost
        components.queryItems = [
            URLQueryItem(name: tapTypeQuery, value: targetType.rawValue),
            URLQueryItem(name: tapIdQuery, value: targetId),
        ]
        return components.url ?? URL(string: "\(tapScheme)://\(tapHost)")!
    }

    /// Not our scheme/host, unknown type or empty id returns nil.
    static func parseTap(_ url: URL) -> (TimerTargetType, String)? {
        guard url.scheme == tapScheme, url.host == tapHost,
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let items = components.queryItems,
              let rawType = items.first(where: { $0.name == tapTypeQuery })?.value,
              let type = TimerTargetType(rawValue: rawType),
              let id = items.first(where: { $0.name == tapIdQuery })?.value,
              !id.isEmpty
        else { return nil }
        return (type, id)
    }
}
