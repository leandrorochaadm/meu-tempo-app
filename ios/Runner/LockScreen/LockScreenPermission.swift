import ActivityKit
import UIKit

/// Reads the system state; decides nothing.
enum LockScreenPermission {
    /// Live Activities on = granted. There is no permission dialog for them.
    static func status() -> LockScreenPermissionStatus {
        ActivityAuthorizationInfo().areActivitiesEnabled ? .granted : .denied
    }

    /// App page in Settings, where "Atividades ao Vivo" and "Notificações" are.
    @MainActor
    static func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}
