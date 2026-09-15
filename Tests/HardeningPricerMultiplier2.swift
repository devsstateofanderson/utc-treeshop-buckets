import XCTest
@testable import Buckets

/// BRIEF §5.3 `multiplier: Int // 1 | 2 | 3`: Pricer holds any other value to 1…3 (DECISIONS 49).
final class Probe_spec_Multiplier: XCTestCase {
    func testMultiplierOutsideOneToThree() {
        XCTAssertEqual(Fixture.price(Fixture.lines(), multiplier: 0).price, 250_150)
        XCTAssertEqual(Fixture.price(Fixture.lines(), multiplier: -7).price, 250_150)
        XCTAssertEqual(Fixture.price(Fixture.lines(), multiplier: 4).price, 750_449)   // held to 3× (DECISIONS 49)
    }
}
