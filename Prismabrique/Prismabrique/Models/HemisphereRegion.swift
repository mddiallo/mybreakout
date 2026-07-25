import Foundation
import SwiftUI

/// A coarse, non-identifying geographic classification derived client-side from a single
/// approximate location fix. Only this enum value is ever persisted — never the raw
/// latitude/longitude that produced it.
enum HemisphereRegion: String, Codable, CaseIterable {
    case northernTemperate
    case southernTemperate
    case tropical
    case polarNorth
    case polarSouth
    case unknown

    /// Buckets a latitude into a region using thresholds from `GameBalanceConfig.location`
    /// so the classification boundaries stay config-driven rather than hardcoded here.
    static func classify(latitude: Double, config: GameBalanceConfig = GameConfigLoader.shared) -> HemisphereRegion {
        let band = config.location.hemisphereLatitudeBandDegrees
        let polar = config.location.polarLatitudeThresholdDegrees
        let absLat = abs(latitude)

        if absLat >= polar {
            return latitude >= 0 ? .polarNorth : .polarSouth
        }
        if absLat <= band {
            return .tropical
        }
        return latitude >= 0 ? .northernTemperate : .southernTemperate
    }

    var displayName: String {
        switch self {
        case .northernTemperate: return "Northern Skies"
        case .southernTemperate: return "Southern Skies"
        case .tropical: return "Equatorial Glow"
        case .polarNorth: return "Aurora North"
        case .polarSouth: return "Aurora South"
        case .unknown: return "Classic Neon"
        }
    }
}

/// Purely cosmetic ambient color theme applied to the game board background/particles.
/// Never affects physics, scoring, or difficulty — only rendering.
struct AmbientTheme {
    let topColor: Color
    let bottomColor: Color
    let accentColor: Color

    static func theme(for region: HemisphereRegion, config: GameBalanceConfig = GameConfigLoader.shared) -> AmbientTheme {
        switch region {
        case .northernTemperate:
            return AmbientTheme(topColor: Color(hex: "#0b1e3d"), bottomColor: Color(hex: "#142850"), accentColor: Color(hex: "#4d96ff"))
        case .southernTemperate:
            return AmbientTheme(topColor: Color(hex: "#2d1b3d"), bottomColor: Color(hex: "#4a2a5c"), accentColor: Color(hex: "#a06cd5"))
        case .tropical:
            return AmbientTheme(topColor: Color(hex: "#1a3d2e"), bottomColor: Color(hex: "#0f5c4a"), accentColor: Color(hex: "#ffd166"))
        case .polarNorth, .polarSouth:
            return AmbientTheme(topColor: Color(hex: "#0a1a2e"), bottomColor: Color(hex: "#1b3a4b"), accentColor: Color(hex: "#00d4ff"))
        case .unknown:
            return AmbientTheme(topColor: Color(hex: config.colorPalette.backgroundTop), bottomColor: Color(hex: config.colorPalette.backgroundBottom), accentColor: Color(hex: config.colorPalette.ballColor))
        }
    }
}

extension Color {
    /// Convenience initializer so config-driven `"#rrggbb"` strings can be used directly.
    init(hex: String) {
        var sanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        sanitized.removeAll { $0 == "#" }
        var value: UInt64 = 0
        Scanner(string: sanitized).scanHexInt64(&value)
        let r = Double((value >> 16) & 0xFF) / 255.0
        let g = Double((value >> 8) & 0xFF) / 255.0
        let b = Double(value & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}
