import XCTest
@testable import Prismabrique

/// Verifies the config-driven 50-level campaign behaves as intended: correct count,
/// monotonically non-decreasing difficulty signals, and deterministic regeneration.
final class LevelGeneratorTests: XCTestCase {
    func testGeneratesExactlyConfiguredLevelCount() {
        let config = GameConfigLoader.shared
        let levels = LevelGenerator.generateAll(config: config)
        XCTAssertEqual(levels.count, config.levelCount)
        XCTAssertEqual(levels.first?.id, 1)
        XCTAssertEqual(levels.last?.id, config.levelCount)
    }

    func testBallSpeedNeverDecreasesAcrossLevels() {
        let levels = LevelGenerator.generateAll()
        for pair in zip(levels, levels.dropFirst()) {
            XCTAssertLessThanOrEqual(pair.0.ballSpeed, pair.1.ballSpeed, "Ball speed should never regress between consecutive levels")
        }
    }

    func testBallSpeedNeverExceedsConfiguredMaximum() {
        let config = GameConfigLoader.shared
        let levels = LevelGenerator.generateAll(config: config)
        for level in levels {
            XCTAssertLessThanOrEqual(level.ballSpeed, config.ball.maxSpeed)
        }
    }

    func testPaddleWidthShrinksButNeverBelowConfiguredMinimum() {
        let config = GameConfigLoader.shared
        let levels = LevelGenerator.generateAll(config: config)
        for level in levels {
            XCTAssertGreaterThanOrEqual(level.paddleWidthFraction, config.paddle.minWidthFraction)
            XCTAssertLessThanOrEqual(level.paddleWidthFraction, config.paddle.baseWidthFraction)
        }
    }

    func testEveryLevelHasAtLeastOneBrick() {
        let levels = LevelGenerator.generateAll()
        for level in levels {
            XCTAssertFalse(level.bricks.isEmpty, "Level \(level.id) generated with no bricks")
        }
    }

    func testGenerationIsDeterministic() {
        let first = LevelGenerator.generate(level: 25)
        let second = LevelGenerator.generate(level: 25)
        XCTAssertEqual(first.bricks.map(\.id), second.bricks.map(\.id))
        XCTAssertEqual(first.ballSpeed, second.ballSpeed)
        XCTAssertEqual(first.pattern, second.pattern)
    }

    func testDifficultyTierBoundaries() {
        XCTAssertEqual(LevelGenerator.generate(level: 1).difficultyTier, "Easy")
        XCTAssertEqual(LevelGenerator.generate(level: 10).difficultyTier, "Easy")
        XCTAssertEqual(LevelGenerator.generate(level: 11).difficultyTier, "Medium")
        XCTAssertEqual(LevelGenerator.generate(level: 30).difficultyTier, "Medium")
        XCTAssertEqual(LevelGenerator.generate(level: 31).difficultyTier, "Hard")
        XCTAssertEqual(LevelGenerator.generate(level: 50).difficultyTier, "Hard")
    }
}
