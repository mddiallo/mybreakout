import Foundation
import SwiftUI
import Combine

/// Which top-level screen is currently presented. Kept simple/enum-driven instead of a
/// heavier navigation framework since Prismabrique has no external dependencies.
enum AppScreen: Equatable {
    case menu
    case levelSelect
    case playing(level: Int)
    case settings
}

/// Root observable object owning persisted progress, settings, and cross-cutting managers
/// (audio/haptics enablement, optional location-based theme). Injected into the view
/// hierarchy as a single `@StateObject` from `PrismabriqueApp`.
@MainActor
final class AppState: ObservableObject {
    @Published var screen: AppScreen = .menu
    @Published private(set) var progress: PlayerProgress
    @Published var locationManager: LocationOptInManager

    let config: GameBalanceConfig = GameConfigLoader.shared
    let levels: [LevelConfig]
    private let store: PersistenceStore
    private var cancellables: Set<AnyCancellable> = []

    init(store: PersistenceStore = .shared) {
        self.store = store
        let loaded = store.load()
        self.progress = loaded
        self.levels = LevelGenerator.generateAll()
        self.locationManager = LocationOptInManager(
            storedRegion: loaded.lastHemisphereRegion.flatMap(HemisphereRegion.init(rawValue:))
        )
        AudioBridge.isEnabled = loaded.settings.soundEnabled
        HapticsBridge.isEnabled = loaded.settings.hapticsEnabled

        locationManager.onRegionResolved = { [weak self] region in
            self?.progress.lastHemisphereRegion = region.rawValue
            self?.persist()
        }

        // Forward the (independent) locationManager's own @Published changes into this
        // object's objectWillChange so views bound to `appState.locationManager.*` refresh.
        locationManager.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
    }

    var currentTheme: AmbientTheme {
        guard progress.settings.locationThemeEnabled, let region = locationManager.currentRegion else {
            return AmbientTheme.theme(for: .unknown, config: config)
        }
        return AmbientTheme.theme(for: region, config: config)
    }

    func level(_ id: Int) -> LevelConfig {
        levels[min(max(id, 1), levels.count) - 1]
    }

    // MARK: - Navigation

    func startLevel(_ id: Int) {
        screen = .playing(level: id)
    }

    func returnToMenu() {
        screen = .menu
    }

    // MARK: - Progress mutation

    func recordLevelResult(level: Int, score: Int, starsEarned: Int) {
        progress.bestScoreByLevel[level] = max(progress.bestScoreByLevel[level] ?? 0, score)
        progress.starsByLevel[level] = max(progress.starsByLevel[level] ?? 0, starsEarned)
        progress.totalScore += score
        if level >= progress.highestUnlockedLevel, level < levels.count {
            progress.highestUnlockedLevel = level + 1
        }
        persist()
    }

    func resetProgress() {
        progress = .empty
        store.reset()
        locationManager.disable()
    }

    // MARK: - Settings

    func setSoundEnabled(_ enabled: Bool) {
        progress.settings.soundEnabled = enabled
        AudioBridge.isEnabled = enabled
        persist()
    }

    func setHapticsEnabled(_ enabled: Bool) {
        progress.settings.hapticsEnabled = enabled
        HapticsBridge.isEnabled = enabled
        persist()
    }

    func setReduceMotion(_ enabled: Bool) {
        progress.settings.reduceMotion = enabled
        persist()
    }

    func setHighContrast(_ enabled: Bool) {
        progress.settings.highContrast = enabled
        persist()
    }

    /// Invoked only from the explicit opt-in UI. Enabling requests When-In-Use
    /// authorization and a single reduced-accuracy fix; disabling immediately stops
    /// location use and forgets the derived region (never the raw coordinates, which were
    /// never stored in the first place).
    func setLocationThemeEnabled(_ enabled: Bool) {
        progress.settings.locationThemeEnabled = enabled
        if enabled {
            locationManager.requestOptIn()
        } else {
            locationManager.disable()
            progress.lastHemisphereRegion = nil
        }
        persist()
    }

    private func persist() {
        store.save(progress)
    }
}
