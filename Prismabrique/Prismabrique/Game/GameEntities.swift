import Foundation
import CoreGraphics

/// Runtime power-up categories. The *set* of types is config-driven (`GameBalance.json`
/// → `powerUps.types`); this enum just gives Swift-side type safety for behavior dispatch.
enum PowerUpKind: String, CaseIterable {
    case widenPaddle, slowBall, multiBall, extraLife, magnetPaddle, shield

    var symbolName: String {
        switch self {
        case .widenPaddle: return "arrow.left.and.right.square.fill"
        case .slowBall: return "hourglass"
        case .multiBall: return "circle.grid.3x3.fill"
        case .extraLife: return "heart.fill"
        case .magnetPaddle: return "bolt.horizontal.circle.fill"
        case .shield: return "shield.lefthalf.filled"
        }
    }

    var displayName: String {
        switch self {
        case .widenPaddle: return "Wide Paddle"
        case .slowBall: return "Slow Ball"
        case .multiBall: return "Multi Ball"
        case .extraLife: return "Extra Life"
        case .magnetPaddle: return "Magnet"
        case .shield: return "Shield"
        }
    }
}

/// A falling collectible currently on the board.
struct FallingPowerUp: Identifiable {
    let id = UUID()
    var position: CGPoint
    let kind: PowerUpKind
}

/// A currently-active (timed) power-up effect applied to the paddle/ball.
struct ActiveEffect: Identifiable {
    let id = UUID()
    let kind: PowerUpKind
    var remainingSeconds: Double
}

/// Mutable runtime state for a single brick on the board (visibility + remaining hits).
struct RuntimeBrick: Identifiable {
    let spec: BrickSpec
    var remainingHits: Int
    var isVisible: Bool

    var id: Int { spec.id }
}

/// Paddle runtime state expressed in normalized board space (0...1 horizontally) plus
/// pixel geometry resolved against the current board size.
struct RuntimePaddle {
    var centerXFraction: Double
    var widthFraction: Double

    func rect(in boardSize: CGSize, config: GameBalanceConfig) -> CGRect {
        let width = boardSize.width * widthFraction
        let height = config.paddle.height
        let centerX = boardSize.width * centerXFraction
        let y = boardSize.height - config.paddle.bottomMargin - height
        return CGRect(x: centerX - width / 2, y: y, width: width, height: height)
    }
}

/// Ball runtime state in absolute board-space points.
struct RuntimeBall: Identifiable {
    let id = UUID()
    var position: CGPoint
    var velocity: CGVector
    var isLaunched: Bool
}
