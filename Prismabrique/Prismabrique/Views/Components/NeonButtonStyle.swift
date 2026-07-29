import SwiftUI

/// Shared neon glassmorphism button style matching the web version's aesthetic
/// (`styles.css` glass panels + neon glow). Respects the high-contrast accessibility
/// setting by falling back to solid, higher-contrast fills.
struct NeonButtonStyle: ButtonStyle {
    var tint: Color = Color(hex: "#00d4ff")
    var highContrast: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.vertical, 14)
            .padding(.horizontal, 28)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(highContrast ? tint.opacity(0.9) : .white.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(tint, lineWidth: highContrast ? 2 : 1.4)
            )
            .shadow(color: tint.opacity(highContrast ? 0 : 0.6), radius: configuration.isPressed ? 2 : 10)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

extension View {
    func neonButton(tint: Color = Color(hex: "#00d4ff"), highContrast: Bool = false) -> some View {
        buttonStyle(NeonButtonStyle(tint: tint, highContrast: highContrast))
    }
}
