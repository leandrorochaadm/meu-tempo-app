import AppIntents
import Foundation

// One intent per Live Activity button. iOS runs `perform()` in the app
// process (not in the extension); the extension only needs the types to build
// `Button(intent:)`. `LockScreenIntentHandler` has one version per target.
// Target membership: MeuTempoLiveActivity and Runner.

struct PauseTimerIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Pausar"
    static let isDiscoverable = false

    @Parameter(title: "Alvo") var targetId: String

    init() {}
    init(targetId: String) { self.targetId = targetId }

    func perform() async throws -> some IntentResult {
        await LockScreenIntentHandler.handle(.pause, targetId: targetId)
        return .result()
    }
}

struct ResumeTimerIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Continuar"
    static let isDiscoverable = false

    @Parameter(title: "Alvo") var targetId: String

    init() {}
    init(targetId: String) { self.targetId = targetId }

    func perform() async throws -> some IntentResult {
        await LockScreenIntentHandler.handle(.resume, targetId: targetId)
        return .result()
    }
}

/// First tap on "Parar": only shows "Confirmar".
struct StopTimerIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Parar"
    static let isDiscoverable = false

    @Parameter(title: "Alvo") var targetId: String

    init() {}
    init(targetId: String) { self.targetId = targetId }

    func perform() async throws -> some IntentResult {
        await LockScreenIntentHandler.handle(.stop, targetId: targetId)
        return .result()
    }
}

/// Second tap: really stops (and finishes) the target.
struct ConfirmStopTimerIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Confirmar"
    static let isDiscoverable = false

    @Parameter(title: "Alvo") var targetId: String

    init() {}
    init(targetId: String) { self.targetId = targetId }

    func perform() async throws -> some IntentResult {
        await LockScreenIntentHandler.handle(.confirm, targetId: targetId)
        return .result()
    }
}
