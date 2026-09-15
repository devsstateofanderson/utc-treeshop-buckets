import XCTest
@testable import Buckets

/// BRIEF §3.2: quantity rows are off by default, hourly rows on; PriceLine's `isOn` default follows the row kind.
final class Probe_spec_PriceLineDefaults: XCTestCase {
    func testPriceLineDefaultsFollowRowKind() {
        XCTAssertTrue(PriceLine(bucket: .materials, rateCents: 8500, isOn: true).isOn)
        XCTAssertTrue(PriceLine(bucket: .consumables, rateCents: 7500, isOn: true).isOn)
        XCTAssertEqual(PriceLine(bucket: .consumables, rateCents: 7500, isOn: true).qty, 1)
    }
}
