import UIKit

/// Wraps `UIFeedbackGenerator` subclasses behind a single string-keyed API so config values
/// (`GameBalance.json` → `haptics.*Style`) can select a feedback style without gameplay code
/// depending on UIKit feedback types directly.
final class HapticsManager {
    private let light = UIImpactFeedbackGenerator(style: .light)
    private let medium = UIImpactFeedbackGenerator(style: .medium)
    private let soft = UIImpactFeedbackGenerator(style: .soft)
    private let notification = UINotificationFeedbackGenerator()

    func play(style: String) {
        switch style {
        case "light": light.impactOccurred()
        case "medium": medium.impactOccurred()
        case "soft": soft.impactOccurred()
        case "success": notification.notificationOccurred(.success)
        case "error": notification.notificationOccurred(.error)
        case "warning": notification.notificationOccurred(.warning)
        default: break
        }
    }
}

/// Process-wide façade mirroring `AudioBridge`, so non-view gameplay code can trigger
/// haptics while still honoring the player's accessibility/haptics setting.
enum HapticsBridge {
    static let shared = HapticsManager()
    static var isEnabled = true

    static func play(style: String) {
        guard isEnabled else { return }
        shared.play(style: style)
    }
}
