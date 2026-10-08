import Flutter
import Foundation

/// Channels of the lock screen timer. Registered only in the main engine
/// (the background engine does not get this plugin).
final class LockScreenTimerPlugin: NSObject, FlutterPlugin {
    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: LockScreenContract.timerChannel,
            binaryMessenger: registrar.messenger()
        )
        registrar.addMethodCallDelegate(LockScreenTimerPlugin(), channel: channel)

        let taps = FlutterEventChannel(
            name: LockScreenContract.tapChannel,
            binaryMessenger: registrar.messenger()
        )
        taps.setStreamHandler(LockScreenTapStreamHandler.shared)
    }

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let method = LockScreenTimerMethod(rawValue: call.method) else {
            result(FlutterMethodNotImplemented)
            return
        }
        switch method {
        case .show:
            guard let payload = LockScreenTimerPayload.from(call.arguments) else {
                result(FlutterError(code: LockScreenContract.invalidPayload, message: nil, details: nil))
                return
            }
            Task { @MainActor in
                do {
                    try await LiveActivityController.shared.show(payload)
                    result(nil)
                } catch {
                    result(FlutterError(
                        code: LockScreenContract.activityFailed,
                        message: String(describing: type(of: error)),
                        details: nil
                    ))
                }
            }
        case .clear:
            // Answers only after ending, so the next `show` never updates an
            // activity that is still being ended.
            Task { @MainActor in
                await LiveActivityController.shared.clear()
                result(nil)
            }
        case .getPermissionStatus, .requestPermission:
            result(LockScreenPermission.status().rawValue)
        case .openNotificationSettings:
            Task { @MainActor in
                LockScreenPermission.openSettings()
                result(nil)
            }
        }
    }
}
