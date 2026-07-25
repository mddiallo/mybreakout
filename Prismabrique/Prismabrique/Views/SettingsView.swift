import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    @State private var showingLocationOptIn = false

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(spacing: 16) {
                    section(title: "Audio & Feedback") {
                        toggleRow(title: "Sound Effects", systemImage: "speaker.wave.2.fill", isOn: appState.progress.settings.soundEnabled) {
                            appState.setSoundEnabled($0)
                        }
                        toggleRow(title: "Haptics", systemImage: "waveform", isOn: appState.progress.settings.hapticsEnabled) {
                            appState.setHapticsEnabled($0)
                        }
                    }

                    section(title: "Accessibility") {
                        toggleRow(title: "Reduce Motion", systemImage: "figure.walk.motion", isOn: appState.progress.settings.reduceMotion) {
                            appState.setReduceMotion($0)
                        }
                        toggleRow(title: "High Contrast", systemImage: "circle.lefthalf.filled", isOn: appState.progress.settings.highContrast) {
                            appState.setHighContrast($0)
                        }
                    }

                    section(title: "Ambient Region Theme (Optional)") {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Adapts the background colors to your broad region (e.g. Northern or Southern hemisphere) using approximate, one-time location. Off by default. No exact location is ever stored, and location is never used in the background.")
                                .font(.footnote)
                                .foregroundStyle(.white.opacity(0.7))

                            toggleRow(
                                title: "Use Approximate Location",
                                systemImage: "location.fill",
                                isOn: appState.progress.settings.locationThemeEnabled
                            ) { newValue in
                                if newValue {
                                    showingLocationOptIn = true
                                } else {
                                    appState.setLocationThemeEnabled(false)
                                }
                            }

                            if let region = appState.locationManager.currentRegion, appState.progress.settings.locationThemeEnabled {
                                Text("Current theme: \(region.displayName)")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.6))
                            }
                            if let error = appState.locationManager.lastError {
                                Text(error)
                                    .font(.caption)
                                    .foregroundStyle(Color(hex: "#ff477e"))
                            }

                            NavigationLinkStyleButton(title: "Privacy Details") {
                                showingLocationOptIn = true
                            }
                        }
                    }

                    section(title: "Data") {
                        Button(role: .destructive) {
                            appState.resetProgress()
                        } label: {
                            Label("Reset Progress", systemImage: "trash.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .neonButton(tint: Color(hex: "#ff477e"), highContrast: appState.progress.settings.highContrast)
                    }
                }
                .padding(16)
            }
        }
        .sheet(isPresented: $showingLocationOptIn) {
            LocationOptInSheetView(isPresented: $showingLocationOptIn)
        }
    }

    private var header: some View {
        HStack {
            Button {
                appState.returnToMenu()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(10)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .accessibilityLabel("Back to menu")
            Spacer()
            Text("Settings")
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)
            Spacer()
            Color.clear.frame(width: 40)
        }
        .padding()
    }

    private func section(title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(.caption.weight(.bold))
                .foregroundStyle(.white.opacity(0.5))
            VStack(spacing: 10) { content() }
                .padding(14)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
    }

    private func toggleRow(title: String, systemImage: String, isOn: Bool, onChange: @escaping (Bool) -> Void) -> some View {
        Toggle(isOn: Binding(get: { isOn }, set: onChange)) {
            Label(title, systemImage: systemImage)
                .foregroundStyle(.white)
        }
        .tint(Color(hex: "#00ff88"))
    }
}

private struct NavigationLinkStyleButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                Spacer()
                Image(systemName: "chevron.right")
            }
            .font(.footnote.weight(.semibold))
            .foregroundStyle(Color(hex: "#00d4ff"))
        }
    }
}

#Preview {
    SettingsView().environmentObject(AppState())
}
