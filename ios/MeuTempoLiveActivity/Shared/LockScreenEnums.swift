import Foundation

// Closed sets of the lock screen protocol. The raw value is the text outside
// the app (Dart side); never derive it from the case name. `init?(rawValue:)`
// returns nil for an unknown value, and the caller decides what to do.
// Target membership: MeuTempoLiveActivity and Runner.

enum LockScreenAction: String, Codable, Hashable {
    case pause = "pause"
    case resume = "resume"
    case stopConfirmed = "stop_confirmed"
}

enum LockScreenReply: String, Codable, Hashable {
    case show = "show"
    case clear = "clear"
    case unchanged = "unchanged"
}

enum LockScreenTimerStatus: String, Codable, Hashable {
    case running = "running"
    case paused = "paused"
}

enum LockScreenPermissionStatus: String, Codable, Hashable {
    case granted = "granted"
    case denied = "denied"
}

enum TimerTargetType: String, Codable, Hashable {
    case task = "task"
    case appointment = "appointment"
}

/// Mirrors `LockScreenTimerChannelMethodEnum` (Dart).
enum LockScreenTimerMethod: String, Codable, Hashable {
    case show = "show"
    case clear = "clear"
    case getPermissionStatus = "getPermissionStatus"
    case requestPermission = "requestPermission"
    case openNotificationSettings = "openNotificationSettings"
}

/// Mirrors `LockScreenChannelMethodEnum` (Dart).
enum LockScreenActionMethod: String, Codable, Hashable {
    case backgroundReady = "backgroundReady"
    case backgroundFailed = "backgroundFailed"
    case handleAction = "handleAction"
}

/// What a Live Activity button asks for. Internal, no outside value.
enum LockScreenIntentCommand {
    case pause, resume, stop, confirm
}
