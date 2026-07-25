import SwiftUI

struct MainMenuView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            VStack(spacing: 6) {
                Text("PRISMABRIQUE")
                    .font(.system(size: 40, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(colors: [Color(hex: "#00ff88"), Color(hex: "#00d4ff")], startPoint: .leading, endPoint: .trailing)
                    )
                    .shadow(color: Color(hex: "#00d4ff").opacity(0.5), radius: 12)
                Text("50 levels of neon brick-breaking")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Prismabrique. 50 levels of neon brick breaking.")

            Spacer()

            VStack(spacing: 14) {
                Button {
                    let resume = min(appState.progress.highestUnlockedLevel, appState.levels.count)
                    appState.startLevel(resume)
                } label: {
                    Label("Continue — Level \(min(appState.progress.highestUnlockedLevel, appState.levels.count))", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .neonButton(tint: Color(hex: "#00ff88"), highContrast: appState.progress.settings.highContrast)

                Button {
                    appState.screen = .levelSelect
                } label: {
                    Label("Level Select", systemImage: "square.grid.3x3.fill")
                        .frame(maxWidth: .infinity)
                }
                .neonButton(highContrast: appState.progress.settings.highContrast)

                Button {
                    appState.screen = .settings
                } label: {
                    Label("Settings", systemImage: "gearshape.fill")
                        .frame(maxWidth: .infinity)
                }
                .neonButton(tint: Color(hex: "#a06cd5"), highContrast: appState.progress.settings.highContrast)
            }
            .padding(.horizontal, 32)

            Spacer()

            Text("Total score: \(appState.progress.totalScore)")
                .font(.footnote.monospacedDigit())
                .foregroundStyle(.white.opacity(0.5))
                .padding(.bottom, 24)
        }
    }
}

#Preview {
    MainMenuView().environmentObject(AppState())
}
