import SwiftUI

/// The primary gameplay screen: renders the board with `Canvas`, reads paddle drag gestures,
/// and steps `GameEngine` every frame via `TimelineView`. No SpriteKit/third-party engine is
/// used, keeping the project dependency-free while still hitting 60fps on-device.
struct GameView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var engine: GameEngineHolder
    @State private var isPaused = false
    @State private var starsEarned = 0
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion

    private let level: LevelConfig

    init(level: LevelConfig) {
        self.level = level
        _engine = StateObject(wrappedValue: GameEngineHolder(level: level))
    }

    var body: some View {
        GeometryReader { geo in
            let boardSize = CGSize(width: geo.size.width, height: geo.size.height)

            ZStack {
                TimelineView(.animation(paused: isPaused)) { timeline in
                    Canvas { context, size in
                        drawBoard(context: &context, size: size)
                    }
                    .onChange(of: timeline.date) { _, newDate in
                        guard !isPaused else { return }
                        engine.tick(at: newDate)
                    }
                }
                .onAppear { engine.engine.boardSize = boardSize }
                .onChange(of: boardSize) { _, newValue in engine.engine.boardSize = newValue }
                .gesture(dragGesture(boardWidth: boardSize.width))
                .onTapGesture { engine.engine.launchBallIfNeeded() }

                VStack {
                    ScoreHUD(score: engine.engine.score, lives: engine.engine.lives, levelId: level.id, combo: engine.engine.combo)
                        .padding(.top, 8)
                    Spacer()
                }

                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            isPaused.toggle()
                        } label: {
                            Image(systemName: isPaused ? "play.fill" : "pause.fill")
                                .foregroundStyle(.white)
                                .padding(12)
                                .background(.ultraThinMaterial, in: Circle())
                        }
                        .padding()
                        .accessibilityLabel(isPaused ? "Resume" : "Pause")
                    }
                }

                if isPaused && !engine.engine.isGameOver && !engine.engine.isLevelComplete {
                    PauseOverlayView(onResume: { isPaused = false }, onQuit: { appState.returnToMenu() })
                }

                if engine.engine.isLevelComplete {
                    LevelCompleteOverlayView(
                        score: engine.engine.score,
                        onNext: {
                            finishLevel()
                            if level.id < appState.levels.count {
                                appState.startLevel(level.id + 1)
                            } else {
                                appState.returnToMenu()
                            }
                        },
                        onMenu: {
                            finishLevel()
                            appState.returnToMenu()
                        }
                    )
                }

                if engine.engine.isGameOver {
                    GameOverOverlayView(
                        score: engine.engine.score,
                        onRetry: { engine.reset(level: level) },
                        onMenu: { appState.returnToMenu() }
                    )
                }
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .background(BackgroundGradientView(theme: appState.currentTheme))
        .onAppear {
            AudioBridge.isEnabled = appState.progress.settings.soundEnabled
            HapticsBridge.isEnabled = appState.progress.settings.hapticsEnabled
        }
    }

    private func dragGesture(boardWidth: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                guard boardWidth > 0 else { return }
                engine.engine.movePaddle(toFraction: value.location.x / boardWidth)
            }
    }

    private func finishLevel() {
        let livesFraction = Double(engine.engine.lives) / Double(max(appState.config.lives.starting, 1))
        starsEarned = livesFraction >= 0.99 ? 3 : (livesFraction >= 0.5 ? 2 : 1)
        appState.recordLevelResult(level: level.id, score: engine.engine.score, starsEarned: starsEarned)
    }

    private func drawBoard(context: inout GraphicsContext, size: CGSize) {
        let cfg = appState.config
        let cellWidth = (size.width - cfg.board.sideInset * 2 - cfg.board.brickSpacing * Double(level.columns - 1)) / Double(level.columns)
        let cellHeight = cellWidth / cfg.board.brickAspectRatio

        for brick in engine.engine.bricks where brick.isVisible {
            let x = cfg.board.sideInset + Double(brick.spec.column) * (cellWidth + cfg.board.brickSpacing)
            let y = cfg.board.topInset + Double(brick.spec.row) * (cellHeight + cfg.board.brickSpacing)
            let rect = CGRect(x: x, y: y, width: cellWidth, height: cellHeight)
            let color = Color(hex: cfg.colorPalette.baseColors[brick.spec.colorIndex])
            let path = Path(roundedRect: rect, cornerRadius: 4)
            context.fill(path, with: .color(color))
            if brick.remainingHits > 1 {
                context.stroke(path, with: .color(.white.opacity(0.5)), lineWidth: 1.5)
            }
        }

        let paddleRect = engine.engine.paddle.rect(in: size, config: cfg)
        let widePaddleRect = CGRect(
            x: paddleRect.midX - size.width * engine.engine.effectivePaddleWidthFraction / 2,
            y: paddleRect.minY,
            width: size.width * engine.engine.effectivePaddleWidthFraction,
            height: paddleRect.height
        )
        context.fill(Path(roundedRect: widePaddleRect, cornerRadius: cfg.paddle.cornerRadius), with: .color(Color(hex: cfg.colorPalette.paddleColor)))

        for ball in engine.engine.balls {
            let ballRect = CGRect(x: ball.position.x - cfg.ball.radius, y: ball.position.y - cfg.ball.radius, width: cfg.ball.radius * 2, height: cfg.ball.radius * 2)
            context.fill(Path(ellipseIn: ballRect), with: .color(Color(hex: cfg.colorPalette.ballColor)))
        }

        for powerUp in engine.engine.fallingPowerUps {
            let rect = CGRect(x: powerUp.position.x - 12, y: powerUp.position.y - 12, width: 24, height: 24)
            context.fill(Path(ellipseIn: rect), with: .color(.white.opacity(0.85)))
        }
    }
}

/// Bridges `TimelineView`'s per-frame date into `GameEngine.step(deltaTime:)`.
@MainActor
final class GameEngineHolder: ObservableObject {
    @Published private(set) var engine: GameEngine
    private var lastTick: Date?

    init(level: LevelConfig) {
        self.engine = GameEngine(level: level, startingLives: GameConfigLoader.shared.lives.starting)
    }

    func tick(at date: Date) {
        defer { lastTick = date }
        guard let last = lastTick else { return }
        engine.step(deltaTime: date.timeIntervalSince(last))
    }

    func reset(level: LevelConfig) {
        engine = GameEngine(level: level, startingLives: GameConfigLoader.shared.lives.starting)
        lastTick = nil
    }
}
