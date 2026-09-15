import XCTest
@testable import Buckets

/// BRIEF §1: multiplier = 1× normal / 2× after-hours / 3× emergency (STS standing rule; one picker). Pricer holds any value to 1…3 (DECISIONS 49).
final class Probe_pricer_multiplier: XCTestCase {
    func testBelowOneIsOne() {
        XCTAssertEqual(Fixture.price(Fixture.lines(), multiplier: 0).price, 250_150)
        XCTAssertEqual(Fixture.price(Fixture.lines(), multiplier: -7).price, 250_150)
    }

    func testFourIsHeldToThree() {
        // 185296 × 1.35 × 4 = 1,000,598.4 → 1,000,598 ; the STS rule allows at most 3× = 750,448.8 → 750,449
        XCTAssertEqual(Fixture.price(Fixture.lines(), multiplier: 4).price, 750_449)
        XCTAssertEqual(Fixture.price(Fixture.lines(), multiplier: 3).price, 750_449)
    }

    func testIntMaxMultiplierPricesBelowCost() {
        // 185296 × 1.35 × Int.max wraps modulo 2^64 to −3,689,348,814,742,160,473 → price = floor 75000 < cost
        let b = Fixture.price(Fixture.lines(), multiplier: Int.max)
        XCTAssertGreaterThanOrEqual(b.price, b.cost, "price \(b.price) below cost \(b.cost)")
    }
}
