import Foundation

/// Extension version: never runs (iOS executes the intent in the app process,
/// where the Runner version of this type is used). It only exists so the
/// extension compiles without linking Flutter.
/// Target membership: MeuTempoLiveActivity only.
enum LockScreenIntentHandler {
    static func handle(_ command: LockScreenIntentCommand, targetId: String) async {}
}
