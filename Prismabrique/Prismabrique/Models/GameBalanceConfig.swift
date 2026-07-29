import Foundation

/// Strongly-typed mirror of `GameBalance.json`. This is the single source of truth for every
/// tunable gameplay value in Prismabrique — level generation, physics, scoring, audio and
/// haptics all read from an instance of this struct instead of hardcoding literals inline.
struct GameBalanceConfig: Codable {
    struct Board: Codable {
        let columns: Int
        let baseRows: Int
        let maxRows: Int
        let rowsIncreaseEveryLevels: Int
        let brickAspectRatio: Double
        let brickSpacing: Double
        let topInset: Double
        let sideInset: Double
        let ballCeilingInset: Double
    }

    struct Paddle: Codable {
        let baseWidthFraction: Double
        let minWidthFraction: Double
        let widthShrinkPerLevel: Double
        let height: Double
        let baseSpeed: Double
        let cornerRadius: Double
        let bottomMargin: Double
        let maxWidthFraction: Double
    }

    struct Ball: Codable {
        let radius: Double
        let baseSpeed: Double
        let speedIncrementPerLevel: Double
        let inLevelSpeedGrowthPerBrick: Double
        let maxSpeed: Double
        let launchAngleDegrees: Double
        let maxBounceAngleDegrees: Double
    }

    struct Lives: Codable {
        let starting: Int
        let maxLives: Int
        let extraLifeScoreThreshold: Int
        let extraLifeScoreInterval: Int
    }

    struct Scoring: Codable {
        let baseScorePerBrick: Int
        let scorePerRowIndexBonus: Int
        let comboIncrementBonus: Int
        let comboResetSeconds: Double
        let levelClearBonus: Int
        let livesRemainingBonusEach: Int
        let powerUpCollectScore: Int
    }

    struct BrickHealth: Codable {
        let baseHitsRequired: Int
        let maxHitsRequired: Int
        let hitsIncreaseEveryLevels: Int
        let reinforcedRowChance: Double
        let reinforcedRowChanceIncrementPerLevel: Double
    }

    struct PowerUps: Codable {
        let baseDropChance: Double
        let dropChanceIncrementPerLevel: Double
        let maxDropChance: Double
        let fallSpeed: Double
        let effectDurationSeconds: Double
        let widenPaddleBoost: Double
        let slowBallFactor: Double
        let multiBallSpreadDegrees: Double
        let types: [String]
    }

    struct Patterns: Codable {
        let sequence: [String]
        let densityRampPerLevel: Double
        let baseDensity: Double
        let maxDensity: Double
    }

    struct ColorPalette: Codable {
        let hueRotationPerLevel: Double
        let baseColors: [String]
        let paddleColor: String
        let ballColor: String
        let backgroundTop: String
        let backgroundBottom: String
    }

    struct DifficultyCurve: Codable {
        let easyLevelCeiling: Int
        let mediumLevelCeiling: Int
        let speedCurveExponent: Double
    }

    struct AudioConfig: Codable {
        let paddleHitFrequency: Double
        let brickHitFrequency: Double
        let wallHitFrequency: Double
        let powerUpFrequency: Double
        let levelCompleteFrequency: Double
        let gameOverFrequency: Double
        let defaultToneDuration: Double
        let defaultVolume: Double
    }

    struct HapticsConfig: Codable {
        let brickHitStyle: String
        let paddleHitStyle: String
        let powerUpStyle: String
        let levelCompleteStyle: String
        let gameOverStyle: String
    }

    struct LocationConfig: Codable {
        let distanceFilterMeters: Double
        let desiredAccuracy: String
        let hemisphereLatitudeBandDegrees: Double
        let polarLatitudeThresholdDegrees: Double
    }

    let schemaVersion: Int
    let levelCount: Int
    let board: Board
    let paddle: Paddle
    let ball: Ball
    let lives: Lives
    let scoring: Scoring
    let brickHealth: BrickHealth
    let powerUps: PowerUps
    let patterns: Patterns
    let colorPalette: ColorPalette
    let difficultyCurve: DifficultyCurve
    let audio: AudioConfig
    let haptics: HapticsConfig
    let location: LocationConfig
}

/// Loads and caches `GameBalance.json` from the app bundle exactly once.
enum GameConfigLoader {
    static let shared: GameBalanceConfig = load()

    private static func load() -> GameBalanceConfig {
        guard
            let url = Bundle.main.url(forResource: "GameBalance", withExtension: "json"),
            let data = try? Data(contentsOf: url)
        else {
            assertionFailure("GameBalance.json missing from bundle — falling back to safe defaults")
            return fallbackConfig
        }
        do {
            return try JSONDecoder().decode(GameBalanceConfig.self, from: data)
        } catch {
            assertionFailure("GameBalance.json failed to decode: \(error)")
            return fallbackConfig
        }
    }

    /// Minimal safe fallback so the app never crashes if the bundled config is somehow
    /// missing or corrupted; values mirror GameBalance.json defaults.
    private static let fallbackConfig = GameBalanceConfig(
        schemaVersion: 1,
        levelCount: 50,
        board: .init(columns: 8, baseRows: 4, maxRows: 10, rowsIncreaseEveryLevels: 6, brickAspectRatio: 2.6, brickSpacing: 6.0, topInset: 90.0, sideInset: 14.0, ballCeilingInset: 18.0),
        paddle: .init(baseWidthFraction: 0.24, minWidthFraction: 0.14, widthShrinkPerLevel: 0.0018, height: 22.0, baseSpeed: 620.0, cornerRadius: 11.0, bottomMargin: 31.5, maxWidthFraction: 0.6),
        ball: .init(radius: 9.0, baseSpeed: 260.0, speedIncrementPerLevel: 6.5, inLevelSpeedGrowthPerBrick: 1.4, maxSpeed: 620.0, launchAngleDegrees: 62.0, maxBounceAngleDegrees: 68.0),
        lives: .init(starting: 3, maxLives: 5, extraLifeScoreThreshold: 15000, extraLifeScoreInterval: 25000),
        scoring: .init(baseScorePerBrick: 50, scorePerRowIndexBonus: 10, comboIncrementBonus: 5, comboResetSeconds: 1.6, levelClearBonus: 500, livesRemainingBonusEach: 250, powerUpCollectScore: 75),
        brickHealth: .init(baseHitsRequired: 1, maxHitsRequired: 4, hitsIncreaseEveryLevels: 8, reinforcedRowChance: 0.12, reinforcedRowChanceIncrementPerLevel: 0.006),
        powerUps: .init(baseDropChance: 0.10, dropChanceIncrementPerLevel: 0.0025, maxDropChance: 0.28, fallSpeed: 190.0, effectDurationSeconds: 9.0, widenPaddleBoost: 0.12, slowBallFactor: 1.6, multiBallSpreadDegrees: 18.0, types: ["widenPaddle", "slowBall", "multiBall", "extraLife", "magnetPaddle", "shield"]),
        patterns: .init(sequence: ["fullGrid", "checkerboard", "diamond", "pyramid", "fortress", "hourglass", "spiral", "columns", "waves", "randomSparse"], densityRampPerLevel: 0.01, baseDensity: 0.72, maxDensity: 0.98),
        colorPalette: .init(hueRotationPerLevel: 14.0, baseColors: ["#ff477e", "#ff9f45", "#ffd166", "#a06cd5", "#4d96ff", "#00d4ff"], paddleColor: "#00ff88", ballColor: "#00d4ff", backgroundTop: "#1a1a2e", backgroundBottom: "#16213e"),
        difficultyCurve: .init(easyLevelCeiling: 10, mediumLevelCeiling: 30, speedCurveExponent: 1.05),
        audio: .init(paddleHitFrequency: 220.0, brickHitFrequency: 440.0, wallHitFrequency: 180.0, powerUpFrequency: 660.0, levelCompleteFrequency: 880.0, gameOverFrequency: 110.0, defaultToneDuration: 0.09, defaultVolume: 0.22),
        haptics: .init(brickHitStyle: "light", paddleHitStyle: "medium", powerUpStyle: "soft", levelCompleteStyle: "success", gameOverStyle: "error"),
        location: .init(distanceFilterMeters: 50000.0, desiredAccuracy: "reduced", hemisphereLatitudeBandDegrees: 23.5, polarLatitudeThresholdDegrees: 60.0)
    )
}
