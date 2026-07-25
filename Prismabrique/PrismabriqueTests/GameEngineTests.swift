import XCTest
@testable import Prismabrique

@MainActor
final class GameEngineTests: XCTestCase {
    func testEngineInitializesWithConfiguredStartingLives() {
        let level = LevelGenerator.generate(level: 1)
        let engine = GameEngine(level: level, startingLives: GameConfigLoader.shared.lives.starting)
        XCTAssertEqual(engine.lives, GameConfigLoader.shared.lives.starting)
        XCTAssertFalse(engine.isGameOver)
        XCTAssertFalse(engine.isLevelComplete)
    }

    func testLaunchingBallSetsVelocity() {
        let level = LevelGenerator.generate(level: 1)
        let engine = GameEngine(level: level, startingLives: 3)
        engine.boardSize = CGSize(width: 390, height: 700)
        XCTAssertFalse(engine.balls[0].isLaunched)
        engine.launchBallIfNeeded()
        XCTAssertTrue(engine.balls[0].isLaunched)
        XCTAssertNotEqual(engine.balls[0].velocity.dx, 0)
    }

    func testMovePaddleClampsWithinBounds() {
        let level = LevelGenerator.generate(level: 1)
        let engine = GameEngine(level: level, startingLives: 3)
        engine.movePaddle(toFraction: -5)
        XCTAssertGreaterThanOrEqual(engine.paddle.centerXFraction, 0)
        engine.movePaddle(toFraction: 5)
        XCTAssertLessThanOrEqual(engine.paddle.centerXFraction, 1)
    }

    func testStepDoesNotCrashWithZeroBoardSize() {
        let level = LevelGenerator.generate(level: 1)
        let engine = GameEngine(level: level, startingLives: 3)
        engine.boardSize = .zero
        engine.launchBallIfNeeded()
        engine.step(deltaTime: 1.0 / 60.0)
        // No crash means success; state should remain internally consistent.
        XCTAssertFalse(engine.isGameOver)
    }
}
