import SwiftUI

/// Glassmorphism HUD showing score, lives, level and active combo — mirrors the web
/// version's `#gameInfo` panel but as a native SwiftUI overlay.
struct ScoreHUD: View {
    let score: Int
    let lives: Int
    let levelId: Int
    let combo: Int

    var body: some View {
        HStack {
            hudChip(title: "LEVEL", value: "\(levelId)")
            Spacer()
            hudChip(title: "SCORE", value: "\(score)")
            Spacer()
            livesView
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Level \(levelId), score \(score), \(lives) lives remaining")
    }

    private var livesView: some View {
        HStack(spacing: 4) {
            ForEach(0..<lives, id: \.self) { _ in
                Image(systemName: "heart.fill")
                    .foregroundStyle(Color(hex: "#ff477e"))
            }
        }
        .accessibilityHidden(true)
    }

    private func hudChip(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2.weight(.bold))
                .foregroundStyle(.white.opacity(0.6))
            Text(value)
                .font(.title3.monospacedDigit().weight(.bold))
                .foregroundStyle(.white)
        }
    }
}

#Preview {
    ZStack {
        Color.black
        ScoreHUD(score: 1250, lives: 3, levelId: 4, combo: 6)
    }
}
