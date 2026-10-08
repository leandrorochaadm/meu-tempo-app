import Flutter
import Foundation
import os

enum LockScreenActionOutcome {
    case show(LockScreenTimerPayload)
    case clear
    case unchanged
}

/// Takes the button tap to the Dart entrypoint (`lockScreenActionMain`) in a
/// second engine, following the background channel protocol. Sends the action
/// and relays the reply; decides nothing.
@MainActor
final class LockScreenActionEngine {
    static let shared = LockScreenActionEngine()

    private struct PendingAction {
        let action: LockScreenAction
        let targetId: String
        let continuation: CheckedContinuation<LockScreenActionOutcome, Never>
    }

    private let logger = Logger(
        subsystem: LockScreenContract.logSubsystem,
        category: LockScreenContract.logCategory
    )
    private var engine: FlutterEngine?
    private var channel: FlutterMethodChannel?
    private var isReady = false
    private var queue: [PendingAction] = []
    private var isSending = false
    private var readyTimeoutTask: Task<Void, Never>?
    private var idleTask: Task<Void, Never>?

    func dispatch(_ action: LockScreenAction, targetId: String) async -> LockScreenActionOutcome {
        idleTask?.cancel()
        return await withCheckedContinuation { continuation in
            queue.append(PendingAction(action: action, targetId: targetId, continuation: continuation))
            if engine == nil {
                startEngine()
            }
            drainIfReady()
        }
    }

    // MARK: - Engine

    private func startEngine() {
        let engine = FlutterEngine(
            name: LockScreenContract.engineName,
            project: nil,
            allowHeadlessExecution: true
        )
        self.engine = engine
        isReady = false

        // The channel handler must be registered AFTER `run`: on iOS a handler
        // set before the shell exists is dropped. The Dart messages are only
        // processed when this method returns the main thread, so nothing is lost.
        guard engine.run(withEntrypoint: LockScreenContract.entrypoint) else {
            logger.error("Background engine did not start")
            failEngine()
            return
        }
        GeneratedPluginRegistrant.register(with: engine)

        let channel = FlutterMethodChannel(
            name: LockScreenContract.actionChannel,
            binaryMessenger: engine.binaryMessenger
        )
        channel.setMethodCallHandler { [weak self] call, result in
            Task { @MainActor in
                self?.handleDartCall(call)
                result(nil)
            }
        }
        self.channel = channel

        readyTimeoutTask = Task { [weak self] in
            try? await Task.sleep(for: LockScreenContract.engineReadyTimeout)
            guard !Task.isCancelled else { return }
            await self?.engineReadyTimedOut()
        }
    }

    private func handleDartCall(_ call: FlutterMethodCall) {
        switch LockScreenActionMethod(rawValue: call.method) {
        case .backgroundReady:
            readyTimeoutTask?.cancel()
            isReady = true
            logger.info("Background engine ready")
            drainIfReady()
        case .backgroundFailed:
            logger.error("Background engine reported failure")
            failEngine()
        case .handleAction, .none:
            break
        }
    }

    private func engineReadyTimedOut() {
        guard !isReady, engine != nil else { return }
        logger.error("Background engine did not become ready in time")
        failEngine()
    }

    /// Whole queue goes back to the last drawing and the engine is destroyed.
    private func failEngine() {
        readyTimeoutTask?.cancel()
        let waiting = queue
        queue = []
        destroyEngine()
        for item in waiting {
            item.continuation.resume(returning: .unchanged)
        }
    }

    private func destroyEngine() {
        channel?.setMethodCallHandler(nil)
        channel = nil
        engine?.destroyContext()
        engine = nil
        isReady = false
        isSending = false
    }

    // MARK: - Queue

    private func drainIfReady() {
        guard isReady, !isSending, !queue.isEmpty, let channel else { return }
        isSending = true
        let item = queue.removeFirst()
        logger.info("Sending action \(item.action.rawValue, privacy: .public)")

        var finished = false
        let finish: (LockScreenActionOutcome) -> Void = { [weak self] outcome in
            guard !finished else { return }
            finished = true
            item.continuation.resume(returning: outcome)
            Task { @MainActor in
                self?.isSending = false
                self?.drainIfReady()
                self?.scheduleIdleIfNeeded()
            }
        }

        let timeoutTask = Task {
            try? await Task.sleep(for: LockScreenContract.actionReplyTimeout)
            guard !Task.isCancelled else { return }
            finish(.unchanged)
        }

        channel.invokeMethod(
            LockScreenActionMethod.handleAction.rawValue,
            arguments: [
                LockScreenContract.action: item.action.rawValue,
                LockScreenContract.targetId: item.targetId,
            ]
        ) { reply in
            timeoutTask.cancel()
            Task { @MainActor in
                finish(Self.outcome(from: reply))
            }
        }
    }

    private static func outcome(from reply: Any?) -> LockScreenActionOutcome {
        guard let map = reply as? [String: Any],
              let rawReply = map[LockScreenContract.reply] as? String,
              let kind = LockScreenReply(rawValue: rawReply)
        else { return .unchanged }
        switch kind {
        case .show:
            guard let payload = LockScreenTimerPayload.from(map[LockScreenContract.timer]) else {
                return .unchanged
            }
            return .show(payload)
        case .clear:
            return .clear
        case .unchanged:
            return .unchanged
        }
    }

    private func scheduleIdleIfNeeded() {
        guard queue.isEmpty, !isSending, engine != nil else { return }
        idleTask?.cancel()
        idleTask = Task { [weak self] in
            try? await Task.sleep(for: LockScreenContract.engineIdle)
            guard !Task.isCancelled else { return }
            await self?.destroyIfIdle()
        }
    }

    private func destroyIfIdle() {
        guard queue.isEmpty, !isSending else { return }
        logger.info("Background engine idle, destroying")
        destroyEngine()
    }
}
