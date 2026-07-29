import Foundation

/// Describes a single brick position within a generated level layout.
struct BrickSpec: Identifiable, Hashable {
    let id: Int
    let row: Int
    let column: Int
    let hitsRequired: Int
    let colorIndex: Int
}

/// A fully-resolved, config-driven level definition. Every numeric field is derived from
/// `GameBalanceConfig` by `LevelGenerator` — nothing here is a hand-authored magic number.
struct LevelConfig: Identifiable, Hashable {
    let id: Int // 1...levelCount
    let rows: Int
    let columns: Int
    let pattern: BrickPattern
    let density: Double
    let ballSpeed: Double
    let paddleWidthFraction: Double
    let powerUpDropChance: Double
    let reinforcedRowChance: Double
    let maxBrickHits: Int
    let hueShiftDegrees: Double
    let bricks: [BrickSpec]

    var difficultyTier: String {
        if id <= 10 { return "Easy" }
        if id <= 30 { return "Medium" }
        return "Hard"
    }
}

/// Pure, deterministic generator that turns `GameBalanceConfig` into the full 50-level
/// campaign. Re-running this with the same config always yields identical levels, and
/// every difficulty knob (speed, density, brick toughness, power-up odds, paddle width)
/// scales smoothly from the config's base/increment/max triples — no per-level hardcoding.
enum LevelGenerator {
    static func generateAll(config: GameBalanceConfig = GameConfigLoader.shared) -> [LevelConfig] {
        (1...config.levelCount).map { generate(level: $0, config: config) }
    }

    static func generate(level: Int, config: GameBalanceConfig = GameConfigLoader.shared) -> LevelConfig {
        let board = config.board
        let patterns = config.patterns
        let ball = config.ball
        let paddle = config.paddle
        let brickHealth = config.brickHealth
        let powerUps = config.powerUps

        let rows = min(
            board.maxRows,
            board.baseRows + (level - 1) / max(board.rowsIncreaseEveryLevels, 1)
        )
        let columns = board.columns

        let pattern = BrickPattern(rawValue: patterns.sequence[(level - 1) % patterns.sequence.count]) ?? .fullGrid
        let density = min(patterns.maxDensity, patterns.baseDensity + Double(level - 1) * patterns.densityRampPerLevel)

        let speedCurveProgress = pow(Double(level - 1), config.difficultyCurve.speedCurveExponent)
        let ballSpeed = min(ball.maxSpeed, ball.baseSpeed + speedCurveProgress * ball.speedIncrementPerLevel)

        let paddleWidth = max(paddle.minWidthFraction, paddle.baseWidthFraction - Double(level - 1) * paddle.widthShrinkPerLevel)

        let powerUpChance = min(powerUps.maxDropChance, powerUps.baseDropChance + Double(level - 1) * powerUps.dropChanceIncrementPerLevel)

        let reinforcedChance = min(0.9, brickHealth.reinforcedRowChance + Double(level - 1) * brickHealth.reinforcedRowChanceIncrementPerLevel)

        let maxHits = min(
            brickHealth.maxHitsRequired,
            brickHealth.baseHitsRequired + (level - 1) / max(brickHealth.hitsIncreaseEveryLevels, 1)
        )

        let hueShift = Double(level - 1) * config.colorPalette.hueRotationPerLevel

        var rng = SeededGenerator(seed: level &* 7919)
        var bricks: [BrickSpec] = []
        var brickId = 0
        for row in 0..<rows {
            let isReinforcedRow = rng.nextUnitDouble() <= reinforcedChance
            for column in 0..<columns {
                guard pattern.includesBrick(row: row, column: column, rows: rows, columns: columns, density: density, rng: &rng) else { continue }
                let hits = isReinforcedRow ? maxHits : brickHealth.baseHitsRequired
                bricks.append(BrickSpec(id: brickId, row: row, column: column, hitsRequired: max(1, hits), colorIndex: (row + level) % config.colorPalette.baseColors.count))
                brickId += 1
            }
        }

        return LevelConfig(
            id: level,
            rows: rows,
            columns: columns,
            pattern: pattern,
            density: density,
            ballSpeed: ballSpeed,
            paddleWidthFraction: paddleWidth,
            powerUpDropChance: powerUpChance,
            reinforcedRowChance: reinforcedChance,
            maxBrickHits: maxHits,
            hueShiftDegrees: hueShift,
            bricks: bricks
        )
    }
}
