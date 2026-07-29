import Foundation

/// Player settings that are not tied to a specific run — persisted alongside progress.
struct PlayerSettings: Codable, Equatable {
    var soundEnabled: Bool = true
    var hapticsEnabled: Bool = true
    var reduceMotion: Bool = false
    var highContrast: Bool = false
    /// User-facing toggle for the optional ambient-theme-by-location feature. `false` by
    /// default — the feature is strictly opt-in and never activates on first launch.
    var locationThemeEnabled: Bool = false
}

/// Everything persisted between app launches. Stored as JSON in `UserDefaults` — no raw
/// GPS coordinates are ever included here (see `LocationOptInManager`).
struct PlayerProgress: Codable, Equatable {
    var highestUnlockedLevel: Int = 1
    var starsByLevel: [Int: Int] = [:]
    var bestScoreByLevel: [Int: Int] = [:]
    var totalScore: Int = 0
    var settings: PlayerSettings = PlayerSettings()
    /// Last-derived coarse region (e.g. "northernTemperate"), never raw latitude/longitude.
    var lastHemisphereRegion: String?

    static let empty = PlayerProgress()
}

/// Persists `PlayerProgress` to `UserDefaults` as JSON. Using `UserDefaults` (rather than a
/// database) keeps the project fully dependency-free and simple to reason about; the store
/// is intentionally small (a few hundred bytes) so this remains an appropriate choice.
final class PersistenceStore {
    static let shared = PersistenceStore()

    private let defaultsKey = "com.prismabrique.playerProgress.v1"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> PlayerProgress {
        guard let data = defaults.data(forKey: defaultsKey) else { return .empty }
        return (try? JSONDecoder().decode(PlayerProgress.self, from: data)) ?? .empty
    }

    func save(_ progress: PlayerProgress) {
        guard let data = try? JSONEncoder().encode(progress) else { return }
        defaults.set(data, forKey: defaultsKey)
    }

    func reset() {
        defaults.removeObject(forKey: defaultsKey)
    }
}
