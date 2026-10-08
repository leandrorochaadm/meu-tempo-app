import Flutter
import Foundation
import os

/// Delivers the Live Activity tap to Dart. Singleton: it exists before the
/// engine, so the tap that opened the app is kept until the first listener.
final class LockScreenTapStreamHandler: NSObject, FlutterStreamHandler {
    static let shared = LockScreenTapStreamHandler()

    private let logger = Logger(
        subsystem: LockScreenContract.logSubsystem,
        category: LockScreenContract.logCategory
    )
    private var sink: FlutterEventSink?
    private var pending: [String: String]?

    /// Returns false for URLs of other schemes (they go on to the plugins,
    /// e.g. Google sign-in). Our own URL is always consumed.
    @discardableResult
    func offer(_ url: URL) -> Bool {
        guard url.scheme == LockScreenContract.tapScheme else { return false }
        guard let (type, id) = LockScreenContract.parseTap(url) else {
            logger.error("Invalid tap URL ignored")
            return true
        }
        let event = [
            LockScreenContract.targetType: type.rawValue,
            LockScreenContract.targetId: id,
        ]
        if let sink {
            sink(event)
        } else {
            pending = event
        }
        return true
    }

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        sink = events
        if let pending {
            events(pending)
            self.pending = nil
        }
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        sink = nil
        return nil
    }
}
