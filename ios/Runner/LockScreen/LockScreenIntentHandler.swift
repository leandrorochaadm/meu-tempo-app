import Foundation

/// Runner version (the one that runs: iOS executes the intents in the app
/// process). The extension has an empty version with the same name.
/// Target membership: Runner only.
enum LockScreenIntentHandler {
    @MainActor
    static func handle(_ command: LockScreenIntentCommand, targetId: String) async {
        let controller = LiveActivityController.shared
        switch command {
        case .pause: await controller.perform(.pause, targetId: targetId)
        case .resume: await controller.perform(.resume, targetId: targetId)
        case .stop: await controller.beginStopConfirmation(targetId: targetId)
        case .confirm: await controller.confirmStop(targetId: targetId)
        }
    }
}
