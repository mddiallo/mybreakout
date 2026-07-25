import SwiftUI

struct PauseOverlayView: View {
    let onResume: () -> Void
    let onQuit: () -> Void

    var body: some View {
        OverlayCard(title: "Paused", systemImage: "pause.circle.fill") {
            VStack(spacing: 12) {
                Button { onResume() } label: {
                    Label("Resume", systemImage: "play.fill").frame(maxWidth: .infinity)
                }
                .neonButton(tint: Color(hex: "#00ff88"))

                Button { onQuit() } label: {
                    Label("Quit to Menu", systemImage: "house.fill").frame(maxWidth: .infinity)
                }
                .neonButton()
            }
        }
    }
}

struct LevelCompleteOverlayView: View {
    let score: Int
    let onNext: () -> Void
    let onMenu: () -> Void

    var body: some View {
        OverlayCard(title: "Level Complete!", systemImage: "checkmark.seal.fill") {
            VStack(spacing: 12) {
                Text("Score: \(score)")
                    .font(.title3.monospacedDigit().weight(.bold))
                    .foregroundStyle(.white)

                Button { onNext() } label: {
                    Label("Next Level", systemImage: "arrow.right.circle.fill").frame(maxWidth: .infinity)
                }
                .neonButton(tint: Color(hex: "#00ff88"))

                Button { onMenu() } label: {
                    Label("Menu", systemImage: "house.fill").frame(maxWidth: .infinity)
                }
                .neonButton()
            }
        }
    }
}

struct GameOverOverlayView: View {
    let score: Int
    let onRetry: () -> Void
    let onMenu: () -> Void

    var body: some View {
        OverlayCard(title: "Game Over", systemImage: "xmark.octagon.fill") {
            VStack(spacing: 12) {
                Text("Score: \(score)")
                    .font(.title3.monospacedDigit().weight(.bold))
                    .foregroundStyle(.white)

                Button { onRetry() } label: {
                    Label("Retry", systemImage: "arrow.clockwise").frame(maxWidth: .infinity)
                }
                .neonButton(tint: Color(hex: "#ff477e"))

                Button { onMenu() } label: {
                    Label("Menu", systemImage: "house.fill").frame(maxWidth: .infinity)
                }
                .neonButton()
            }
        }
    }
}

/// Shared glass card layout for all in-game overlays.
private struct OverlayCard<Content: View>: View {
    let title: String
    let systemImage: String
    @ViewBuilder var content: Content

    var body: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()

            VStack(spacing: 18) {
                Image(systemName: systemImage)
                    .font(.system(size: 44))
                    .foregroundStyle(Color(hex: "#00d4ff"))
                Text(title)
                    .font(.title.weight(.heavy))
                    .foregroundStyle(.white)
                content
            }
            .padding(28)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))
            .padding(32)
        }
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
    }
}
