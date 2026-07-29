import XCTest
@testable import Prismabrique

final class PersistenceStoreTests: XCTestCase {
    private var suiteName: String!
    private var suite: UserDefaults!
    private var store: PersistenceStore!

    override func setUp() {
        super.setUp()
        suiteName = "com.prismabrique.tests.\(UUID().uuidString)"
        suite = UserDefaults(suiteName: suiteName)
        store = PersistenceStore(defaults: suite)
    }

    override func tearDown() {
        suite.removePersistentDomain(forName: suiteName)
        store = nil
        suite = nil
        super.tearDown()
    }

    func testLoadWithoutPriorSaveReturnsEmptyDefaults() {
        let loaded = store.load()
        XCTAssertEqual(loaded, .empty)
        XCTAssertEqual(loaded.highestUnlockedLevel, 1)
    }

    func testSaveAndLoadRoundTripsAllFields() {
        var progress = PlayerProgress.empty
        progress.highestUnlockedLevel = 12
        progress.totalScore = 4200
        progress.starsByLevel = [1: 3, 2: 2]
        progress.bestScoreByLevel = [1: 900]
        progress.settings.soundEnabled = false
        progress.settings.locationThemeEnabled = true
        progress.lastHemisphereRegion = HemisphereRegion.tropical.rawValue

        store.save(progress)
        let reloaded = store.load()

        XCTAssertEqual(reloaded, progress)
    }

    func testResetClearsStoredProgress() {
        var progress = PlayerProgress.empty
        progress.totalScore = 999
        store.save(progress)
        store.reset()
        XCTAssertEqual(store.load(), .empty)
    }

    func testPlayerProgressNeverPersistsRawCoordinateFields() {
        // Guard against regressions: PlayerProgress must only ever expose a coarse region
        // string, never latitude/longitude — this is asserted structurally: the Codable
        // implementation only round-trips known keys, so encoding+decoding a region string
        // must not require or produce numeric coordinate fields.
        var progress = PlayerProgress.empty
        progress.lastHemisphereRegion = HemisphereRegion.northernTemperate.rawValue
        let data = try! JSONEncoder().encode(progress)
        let json = String(data: data, encoding: .utf8) ?? ""
        XCTAssertFalse(json.lowercased().contains("latitude"))
        XCTAssertFalse(json.lowercased().contains("longitude"))
    }
}
