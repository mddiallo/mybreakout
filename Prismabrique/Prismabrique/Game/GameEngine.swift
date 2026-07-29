import Foundation
import CoreGraphics
import Combine

/// Drives a single level's simulation: physics, collisions, scoring, power-ups and win/lose
/// state. Owned by `GameView` and stepped every frame from a `TimelineView`. All tunable
/// numbers come from `GameBalanceConfig`/`LevelConfig` — this file contains only mechanics.
@MainActor
final class GameEngine: ObservableObject {
    // MARK: Published runtime state
    @Published private(set) var paddle: RuntimePaddle
    @Published private(set) var balls: [RuntimeBall] = []
    @Published private(set) var bricks: [RuntimeBrick]
    @Published private(set) var fallingPowerUps: [FallingPowerUp] = []
    @Published private(set) var activeEffects: [ActiveEffect] = []
    @Published private(set) var score: Int = 0
    @Published private(set) var lives: Int
    @Published private(set) var combo: Int = 0
    @Published private(set) var isLevelComplete = false
    @Published private(set) var isGameOver = false
    @Published var boardSize: CGSize = .init(width: 390, height: 700)

    let level: LevelConfig
    let config: GameBalanceConfig
    private var currentBallSpeed: Double
    private var timeSinceLastHit: Double = 0
    private var scoreSinceLastExtraLife: Int = 0
    private var paddleWidenBoost: Double = 0
    private var shieldActive = false
    private var slowFactor: Double = 1.0

    var onBrickDestroyed: ((Int) -> Void)?
    var onPowerUpCollected: ((PowerUpKind) -> Void)?
    var onBallLost: (() -> Void)?
    var onLevelComplete: ((Int) -> Void)?
    var onGameOver: (() -> Void)?

    init(level: LevelConfig, startingLives: Int, config: GameBalanceConfig = GameConfigLoader.shared) {
        self.level = level
        self.config = config
        self.currentBallSpeed = level.ballSpeed
        self.lives = startingLives
        self.paddle = RuntimePaddle(centerXFraction: 0.5, widthFraction: level.paddleWidthFraction)
        self.bricks = level.bricks.map { RuntimeBrick(spec: $0, remainingHits: $0.hitsRequired, isVisible: true) }
        resetBall(launched: false)
    }

    var effectivePaddleWidthFraction: Double {
        min(config.paddle.maxWidthFraction, paddle.widthFraction + paddleWidenBoost)
    }

    // MARK: - Player input

    func movePaddle(toFraction fraction: Double) {
        let half = effectivePaddleWidthFraction / 2
        paddle.centerXFraction = min(1 - half, max(half, fraction))
    }

    func launchBallIfNeeded() {
        guard let idx = balls.firstIndex(where: { !$0.isLaunched }) else { return }
        let angle = (90.0 - config.ball.launchAngleDegrees) * .pi / 180
        let speed = currentBallSpeed
        balls[idx].velocity = CGVector(dx: cos(angle) * speed * (Bool.random() ? 1 : -1), dy: -sin(angle) * speed)
        balls[idx].isLaunched = true
    }

    // MARK: - Simulation step

    func step(deltaTime dt: Double) {
        guard !isLevelComplete, !isGameOver, dt > 0, dt.isFinite else { return }
        let clampedDt = min(dt, 1.0 / 30.0)
        updateCombo(dt: clampedDt)
        updateEffects(dt: clampedDt)
        updateBalls(dt: clampedDt)
        updatePowerUps(dt: clampedDt)
        checkLevelComplete()
    }

    private func updateCombo(dt: Double) {
        guard combo > 0 else { return }
        timeSinceLastHit += dt
        if timeSinceLastHit >= config.scoring.comboResetSeconds {
            combo = 0
        }
    }

    private func updateEffects(dt: Double) {
        guard !activeEffects.isEmpty else { return }
        for i in activeEffects.indices.reversed() {
            activeEffects[i].remainingSeconds -= dt
            if activeEffects[i].remainingSeconds <= 0 {
                let expired = activeEffects.remove(at: i)
                deactivate(expired.kind)
            }
        }
    }

    private func updateBalls(dt: Double) {
        let paddleRect = paddle.rect(in: boardSize, config: config)
        let radius = config.ball.radius

        for i in balls.indices {
            guard balls[i].isLaunched else {
                balls[i].position = CGPoint(x: paddleRect.midX, y: paddleRect.minY - radius - 1)
                continue
            }

            var pos = balls[i].position
            var vel = balls[i].velocity
            let effectiveDt = dt / slowFactor

            pos.x += vel.dx * effectiveDt
            pos.y += vel.dy * effectiveDt

            // Wall collisions
            if pos.x - radius < 0 { pos.x = radius; vel.dx = abs(vel.dx) }
            if pos.x + radius > boardSize.width { pos.x = boardSize.width - radius; vel.dx = -abs(vel.dx) }
            if pos.y - radius < config.board.ballCeilingInset {
                pos.y = config.board.ballCeilingInset + radius
                vel.dy = abs(vel.dy)
            }

            // Paddle collision (only moving downward)
            let ballRect = CGRect(x: pos.x - radius, y: pos.y - radius, width: radius * 2, height: radius * 2)
            if vel.dy > 0, ballRect.intersects(paddleRect) {
                let hitFraction = (pos.x - paddleRect.minX) / max(paddleRect.width, 1)
                let clamped = min(1, max(0, hitFraction))
                let bounceAngle = (clamped - 0.5) * 2 * config.ball.maxBounceAngleDegrees * .pi / 180
                let speed = hypot(vel.dx, vel.dy)
                vel = CGVector(dx: sin(bounceAngle) * speed, dy: -cos(bounceAngle) * speed)
                pos.y = paddleRect.minY - radius - 0.5
                HapticsBridge.play(style: config.haptics.paddleHitStyle)
                AudioBridge.playTone(frequency: config.audio.paddleHitFrequency, duration: config.audio.defaultToneDuration, volume: config.audio.defaultVolume)
            }

            // Brick collisions
            resolveBrickCollisions(position: &pos, velocity: &vel, radius: radius)

            // Ball lost off bottom
            if pos.y - radius > boardSize.height {
                balls[i].isLaunched = false
                balls[i].position = pos
                balls[i].velocity = .zero
                continue
            }

            balls[i].position = pos
            balls[i].velocity = vel
        }

        // Remove extra lost multi-balls, keep exactly one "resting" ball if all are lost.
        let launchedCount = balls.filter { $0.isLaunched }.count
        if launchedCount == 0 && balls.count > 0 {
            if balls.count > 1 {
                balls = [balls[0]]
            }
            if !balls[0].isLaunched {
                handleBallFullyLost()
            }
        }
    }

    private func resolveBrickCollisions(position pos: inout CGPoint, velocity vel: inout CGVector, radius: Double) {
        guard boardSize.width > 0, boardSize.height > 0 else { return }
        let cellWidth = (boardSize.width - config.board.sideInset * 2 - config.board.brickSpacing * Double(level.columns - 1)) / Double(level.columns)
        let cellHeight = cellWidth / config.board.brickAspectRatio

        for i in bricks.indices where bricks[i].isVisible {
            let brick = bricks[i]
            let x = config.board.sideInset + Double(brick.spec.column) * (cellWidth + config.board.brickSpacing)
            let y = config.board.topInset + Double(brick.spec.row) * (cellHeight + config.board.brickSpacing)
            let rect = CGRect(x: x, y: y, width: cellWidth, height: cellHeight)
            let ballRect = CGRect(x: pos.x - radius, y: pos.y - radius, width: radius * 2, height: radius * 2)
            guard rect.intersects(ballRect) else { continue }

            // Determine collision side using overlap penetration depth.
            let overlapX = min(ballRect.maxX, rect.maxX) - max(ballRect.minX, rect.minX)
            let overlapY = min(ballRect.maxY, rect.maxY) - max(ballRect.minY, rect.minY)
            if overlapX < overlapY {
                vel.dx = -vel.dx
            } else {
                vel.dy = -vel.dy
            }

            registerBrickHit(index: i)
            break // one brick per physics substep keeps behavior predictable
        }
    }

    private func registerBrickHit(index: Int) {
        bricks[index].remainingHits -= 1
        combo += 1
        timeSinceLastHit = 0

        HapticsBridge.play(style: config.haptics.brickHitStyle)
        AudioBridge.playTone(frequency: config.audio.brickHitFrequency, duration: config.audio.defaultToneDuration, volume: config.audio.defaultVolume)

        if bricks[index].remainingHits <= 0 {
            bricks[index].isVisible = false
            let rowBonus = bricks[index].spec.row * config.scoring.scorePerRowIndexBonus
            let comboBonus = combo * config.scoring.comboIncrementBonus
            score += config.scoring.baseScorePerBrick + rowBonus + comboBonus
            currentBallSpeed = min(config.ball.maxSpeed, currentBallSpeed + config.ball.inLevelSpeedGrowthPerBrick)
            maybeAwardExtraLife()
            onBrickDestroyed?(bricks[index].spec.id)
            maybeDropPowerUp(from: bricks[index].spec)
        }
    }

    private func maybeAwardExtraLife() {
        scoreSinceLastExtraLife += config.scoring.baseScorePerBrick
        let threshold = score <= config.lives.extraLifeScoreThreshold
            ? config.lives.extraLifeScoreThreshold
            : config.lives.extraLifeScoreInterval
        if scoreSinceLastExtraLife >= threshold {
            scoreSinceLastExtraLife = 0
            if lives < config.lives.maxLives {
                lives += 1
            }
        }
    }

    private func maybeDropPowerUp(from brick: BrickSpec) {
        var rng = SeededGenerator(seed: brick.id &+ level.id &* 31 &+ Int(score))
        guard rng.nextUnitDouble() <= level.powerUpDropChance else { return }
        guard let kindName = config.powerUps.types.randomElement(), let kind = PowerUpKind(rawValue: kindName) else { return }
        let cellWidth = (boardSize.width - config.board.sideInset * 2 - config.board.brickSpacing * Double(level.columns - 1)) / Double(level.columns)
        let cellHeight = cellWidth / config.board.brickAspectRatio
        let x = config.board.sideInset + Double(brick.column) * (cellWidth + config.board.brickSpacing) + cellWidth / 2
        let y = config.board.topInset + Double(brick.row) * (cellHeight + config.board.brickSpacing) + cellHeight / 2
        fallingPowerUps.append(FallingPowerUp(position: CGPoint(x: x, y: y), kind: kind))
    }

    private func updatePowerUps(dt: Double) {
        guard !fallingPowerUps.isEmpty else { return }
        let paddleRect = paddle.rect(in: boardSize, config: config)
        for i in fallingPowerUps.indices.reversed() {
            fallingPowerUps[i].position.y += config.powerUps.fallSpeed * dt
            let pt = fallingPowerUps[i].position
            if paddleRect.contains(pt) {
                collect(fallingPowerUps.remove(at: i))
            } else if pt.y > boardSize.height {
                fallingPowerUps.remove(at: i)
            }
        }
    }

    private func collect(_ powerUp: FallingPowerUp) {
        score += config.scoring.powerUpCollectScore
        HapticsBridge.play(style: config.haptics.powerUpStyle)
        AudioBridge.playTone(frequency: config.audio.powerUpFrequency, duration: config.audio.defaultToneDuration, volume: config.audio.defaultVolume)
        onPowerUpCollected?(powerUp.kind)

        switch powerUp.kind {
        case .extraLife:
            lives = min(config.lives.maxLives, lives + 1)
        case .multiBall:
            spawnExtraBalls()
        default:
            activate(powerUp.kind)
        }
    }

    private func activate(_ kind: PowerUpKind) {
        activeEffects.removeAll { $0.kind == kind }
        activeEffects.append(ActiveEffect(kind: kind, remainingSeconds: config.powerUps.effectDurationSeconds))
        switch kind {
        case .widenPaddle: paddleWidenBoost = config.powerUps.widenPaddleBoost
        case .slowBall: slowFactor = config.powerUps.slowBallFactor
        case .shield: shieldActive = true
        case .magnetPaddle: break // sticky-paddle catch behavior reserved for future iteration
        case .multiBall, .extraLife: break
        }
    }

    private func deactivate(_ kind: PowerUpKind) {
        switch kind {
        case .widenPaddle: paddleWidenBoost = 0
        case .slowBall: slowFactor = 1.0
        case .shield: shieldActive = false
        default: break
        }
    }

    private func spawnExtraBalls() {
        guard let template = balls.first(where: { $0.isLaunched }) ?? balls.first else { return }
        let speed = max(hypot(template.velocity.dx, template.velocity.dy), currentBallSpeed)
        for offsetDegrees in [-config.powerUps.multiBallSpreadDegrees, config.powerUps.multiBallSpreadDegrees] {
            let baseAngle = atan2(template.velocity.dy, template.velocity.dx)
            let angle = baseAngle + offsetDegrees * .pi / 180
            let vel = CGVector(dx: cos(angle) * speed, dy: sin(angle) * speed)
            balls.append(RuntimeBall(position: template.position, velocity: vel, isLaunched: true))
        }
    }

    private func handleBallFullyLost() {
        if shieldActive {
            shieldActive = false
            activeEffects.removeAll { $0.kind == .shield }
            resetBall(launched: false)
            return
        }
        lives -= 1
        onBallLost?()
        if lives <= 0 {
            isGameOver = true
            HapticsBridge.play(style: config.haptics.gameOverStyle)
            AudioBridge.playTone(frequency: config.audio.gameOverFrequency, duration: config.audio.defaultToneDuration * 3, volume: config.audio.defaultVolume)
            onGameOver?()
        } else {
            resetBall(launched: false)
        }
    }

    private func resetBall(launched: Bool) {
        let paddleRect = paddle.rect(in: boardSize, config: config)
        let start = CGPoint(x: paddleRect.midX, y: paddleRect.minY - config.ball.radius - 1)
        balls = [RuntimeBall(position: start, velocity: .zero, isLaunched: launched)]
    }

    private func checkLevelComplete() {
        guard !isLevelComplete else { return }
        if bricks.allSatisfy({ !$0.isVisible }) {
            isLevelComplete = true
            let livesBonus = lives * config.scoring.livesRemainingBonusEach
            score += config.scoring.levelClearBonus + livesBonus
            HapticsBridge.play(style: config.haptics.levelCompleteStyle)
            AudioBridge.playTone(frequency: config.audio.levelCompleteFrequency, duration: config.audio.defaultToneDuration * 2, volume: config.audio.defaultVolume)
            onLevelComplete?(score)
        }
    }
}
