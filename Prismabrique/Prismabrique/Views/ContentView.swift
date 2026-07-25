import SwiftUI

/// Root view that switches between the app's top-level screens based on `AppState.screen`.
struct ContentView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        ZStack {
            BackgroundGradientView(theme: appState.currentTheme)
                .ignoresSafeArea()

            switch appState.screen {
            case .menu:
                MainMenuView()
                    .transition(.opacity)
            case .levelSelect:
                LevelSelectView()
                    .transition(.opacity)
            case .playing(let level):
                GameView(level: appState.level(level))
                    .transition(.opacity)
            case .settings:
                SettingsView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: appState.progress.settings.reduceMotion ? 0.05 : 0.35), value: appState.screen)
    }
}

/// Ambient animated background gradient, purely cosmetic and driven either by the config's
/// default palette or (if the player opted in) a coarse-region ambient theme.
struct BackgroundGradientView: View {
    let theme: AmbientTheme

    var body: some View {
        LinearGradient(
            colors: [theme.topColor, theme.bottomColor],
            startPoint: .top,
            endPoint: .bottom
        )
        .animation(.easeInOut(duration: 0.6), value: theme.topColor)
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}
