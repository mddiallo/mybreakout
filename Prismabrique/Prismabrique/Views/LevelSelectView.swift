import SwiftUI

struct LevelSelectView: View {
    @EnvironmentObject private var appState: AppState
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 5)

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(appState.levels) { level in
                        levelTile(level)
                    }
                }
                .padding(16)
            }
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
            Text("Select Level")
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)
            Spacer()
            Color.clear.frame(width: 40)
        }
        .padding()
    }

    private func levelTile(_ level: LevelConfig) -> some View {
        let unlocked = level.id <= appState.progress.highestUnlockedLevel
        let stars = appState.progress.starsByLevel[level.id] ?? 0

        return Button {
            guard unlocked else { return }
            appState.startLevel(level.id)
        } label: {
            VStack(spacing: 4) {
                Text("\(level.id)")
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(unlocked ? .white : .white.opacity(0.3))
                if unlocked {
                    HStack(spacing: 1) {
                        ForEach(0..<3, id: \.self) { i in
                            Image(systemName: i < stars ? "star.fill" : "star")
                                .font(.system(size: 8))
                                .foregroundStyle(Color(hex: "#ffd166"))
                        }
                    }
                } else {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.3))
                }
            }
            .frame(maxWidth: .infinity, minHeight: 56)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(unlocked ? Color(hex: level.pattern.rawValue.isEmpty ? "#1a1a2e" : "#1a1a2e") : .white.opacity(0.03))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(unlocked ? Color(hex: "#00d4ff").opacity(0.5) : .white.opacity(0.08), lineWidth: 1)
            )
        }
        .disabled(!unlocked)
        .accessibilityLabel(unlocked ? "Level \(level.id), \(stars) stars" : "Level \(level.id), locked")
    }
}

#Preview {
    LevelSelectView().environmentObject(AppState())
}
