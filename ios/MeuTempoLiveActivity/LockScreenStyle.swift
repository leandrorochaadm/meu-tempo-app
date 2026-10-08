import SwiftUI

/// Mirrors `AppColors.dark` (Dart): if a token changes, change both.
enum LockScreenPalette {
    static let surface = Color(red: 0x18 / 255, green: 0x1B / 255, blue: 0x21 / 255)
    static let accent = Color(red: 0x4F / 255, green: 0xD1 / 255, blue: 0xC5 / 255)
    static let textPrimary = Color(red: 0xEC / 255, green: 0xEE / 255, blue: 0xF3 / 255)
    static let textSecondary = Color(red: 0xA2 / 255, green: 0xA9 / 255, blue: 0xB8 / 255)
    static let danger = Color(red: 0xF8 / 255, green: 0x71 / 255, blue: 0x71 / 255)
}

/// Screen text (pt-BR, simple).
enum LockScreenStrings {
    static let pause = "Pausar"
    static let resume = "Continuar"
    static let stop = "Parar"
    static let confirm = "Confirmar"
    static let paused = "Pausado"
}
