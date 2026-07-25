import Foundation

/// One of the ten structural brick-layout templates referenced by `GameBalance.json`.
/// The *shape* rules below are structural pattern definitions (analogous to picking a
/// tile grid formula), not tunable gameplay balance values, so they live in code while
/// every numeric knob that controls difficulty (density, hit points, speeds…) still comes
/// from `GameBalanceConfig` / `LevelConfig`.
enum BrickPattern: String, CaseIterable, Codable {
    case fullGrid, checkerboard, diamond, pyramid, fortress
    case hourglass, spiral, columns, waves, randomSparse

    /// Deterministically decides whether a brick exists at (row, column) for this pattern,
    /// given the level's target density (0...1) and a seeded generator for the "random" case.
    func includesBrick(row: Int, column: Int, rows: Int, columns: Int, density: Double, rng: inout SeededGenerator) -> Bool {
        let rMid = Double(rows - 1) / 2.0
        let cMid = Double(columns - 1) / 2.0
        switch self {
        case .fullGrid:
            return true
        case .checkerboard:
            return (row + column) % 2 == 0
        case .diamond:
            let dist = abs(Double(row) - rMid) / max(rMid, 1) + abs(Double(column) - cMid) / max(cMid, 1)
            return dist <= density * 2.0
        case .pyramid:
            let widthAtRow = density * Double(columns) * (Double(row + 1) / Double(rows))
            let distFromCenter = abs(Double(column) - cMid)
            return distFromCenter <= widthAtRow / 2.0
        case .fortress:
            let isEdge = row == 0 || row == rows - 1 || column == 0 || column == columns - 1
            return isEdge || (row % 2 == 0 && column % 2 == 0 && density > 0.6)
        case .hourglass:
            let normalizedRow = Double(row) / Double(max(rows - 1, 1))
            let waist = abs(normalizedRow - 0.5) * 2.0
            let distFromCenter = abs(Double(column) - cMid) / max(cMid, 1)
            return distFromCenter <= waist + (1 - density)
        case .spiral:
            let angle = (Double(row) * Double(columns) + Double(column)) * 0.6
            let radius = sqrt(Double(row * row + column * column))
            return (sin(angle + radius) + 1.0) / 2.0 <= density
        case .columns:
            return column % 2 == 0 || Double(row).truncatingRemainder(dividingBy: 3) < density * 3
        case .waves:
            let wave = sin(Double(column) * 0.9 + Double(row) * 0.4)
            return (wave + 1.0) / 2.0 <= density
        case .randomSparse:
            return rng.nextUnitDouble() <= density
        }
    }
}

/// A tiny deterministic PRNG (xorshift) so brick layouts are reproducible per level/seed
/// instead of relying on global randomness — important for consistent, fair, testable levels.
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: Int) {
        state = UInt64(bitPattern: Int64(seed)) &+ 0x9E3779B97F4A7C15
        if state == 0 { state = 0x9E3779B97F4A7C15 }
    }

    mutating func next() -> UInt64 {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }

    mutating func nextUnitDouble() -> Double {
        Double(next() % 1_000_000) / 1_000_000.0
    }
}
