import XCTest
@testable import Prismabrique

final class HemisphereRegionTests: XCTestCase {
    func testTropicalBandAroundEquator() {
        XCTAssertEqual(HemisphereRegion.classify(latitude: 0), .tropical)
        XCTAssertEqual(HemisphereRegion.classify(latitude: 10), .tropical)
        XCTAssertEqual(HemisphereRegion.classify(latitude: -10), .tropical)
    }

    func testNorthernAndSouthernTemperateBands() {
        XCTAssertEqual(HemisphereRegion.classify(latitude: 40), .northernTemperate)
        XCTAssertEqual(HemisphereRegion.classify(latitude: -40), .southernTemperate)
    }

    func testPolarThresholds() {
        XCTAssertEqual(HemisphereRegion.classify(latitude: 75), .polarNorth)
        XCTAssertEqual(HemisphereRegion.classify(latitude: -75), .polarSouth)
    }

    func testClassificationIsPureFunctionOfLatitudeOnly() {
        // Same latitude must always classify identically regardless of call order/state,
        // reinforcing that no longitude or persisted state influences the result.
        let a = HemisphereRegion.classify(latitude: 51.5)
        let b = HemisphereRegion.classify(latitude: 51.5)
        XCTAssertEqual(a, b)
    }
}
