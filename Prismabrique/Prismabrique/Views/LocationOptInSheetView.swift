import SwiftUI

/// Explicit, standalone consent screen for the optional ambient-region-theme feature.
/// This is the *only* place in the app that ever triggers a CoreLocation authorization
/// request, and only in response to the player tapping "Enable" here.
struct LocationOptInSheetView: View {
    @EnvironmentObject private var appState: AppState
    @Binding var isPresented: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Image(systemName: "location.circle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(Color(hex: "#00d4ff"))
                        .frame(maxWidth: .infinity)

                    Text("Ambient Region Theme")
                        .font(.title2.weight(.bold))
                        .frame(maxWidth: .infinity, alignment: .center)

                    disclosureRow(icon: "checkmark.circle.fill", text: "Cosmetic only — never affects gameplay, scoring, or difficulty.")
                    disclosureRow(icon: "location.slash.fill", text: "Uses approximate (reduced-accuracy) location for a single, one-time check — not precise GPS tracking.")
                    disclosureRow(icon: "moon.zzz.fill", text: "Never runs in the background. Location is only requested while you're actively enabling this feature in the app.")
                    disclosureRow(icon: "externaldrive.badge.xmark", text: "Your exact coordinates are never saved. Only a broad classification (e.g. \"Northern Skies\") is stored on this device.")
                    disclosureRow(icon: "hand.raised.fill", text: "Fully optional and off by default. You can disable it at any time from Settings — the game is complete without it.")

                    Text("When you tap Enable, iOS will ask you to allow Prismabrique to use your location \"While Using the App.\" You can decline or revoke this later in the iOS Settings app.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    VStack(spacing: 12) {
                        Button {
                            appState.setLocationThemeEnabled(true)
                            isPresented = false
                        } label: {
                            Label("Enable Ambient Theme", systemImage: "location.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .neonButton(tint: Color(hex: "#00ff88"))

                        Button {
                            isPresented = false
                        } label: {
                            Text("Not Now").frame(maxWidth: .infinity)
                        }
                        .neonButton()
                    }
                    .padding(.top, 8)
                }
                .padding(24)
            }
            .background(Color(hex: "#16213e").ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { isPresented = false }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func disclosureRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(Color(hex: "#00ff88"))
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.85))
        }
    }
}

#Preview {
    LocationOptInSheetView(isPresented: .constant(true))
        .environmentObject(AppState())
}
