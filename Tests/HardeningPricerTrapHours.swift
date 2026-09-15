import XCTest
@testable import Buckets

/// The most typeable crashes: the §3.3 project with a 15- or 16-digit hours entry (two-decimal rule satisfied, DECISIONS 30 has no upper bound).
/// Both kill the process with "Swift runtime failure: arithmetic overflow" — DECISIONS 10 says Pricer never throws.
final class Probe_pricer_trap_hours: XCTestCase {
    /// hours = 7e14: labor = 12439 × 7e14 = 8,707,300,000,000,000,000 and equipment = 4,933,600,000,000,000,000 each fit in Int,
    /// but `cost = labor + equipment + materials + consumables + overhead` = 1.49e19 > Int.max → trap at Pricer.swift:93.
    /// Any hours ≥ ~433,300,000,000,000 traps on this fixture (per-hour cost 21,287 ¢ × hours > 2^63 − 1).
    func testFifteenDigitHoursTrapsInCostSum() {
        let b = Fixture.price(Fixture.lines(), hours: 700_000_000_000_000)
        XCTAssertGreaterThanOrEqual(b.cost, 0)   // never reached
    }

    /// hours = 1.5e15 at 2×: labor and equipment wrap in Money.cents (equipment → −7,874,744,073,709,551,616), cost = −4,962,988,147,419,088,232;
    /// cost × 1.35 × 2 = −1.34e19 wraps to +5,046,676,075,678,013,390 = price; `profit = price − cost` = 1.0e19 > Int.max → trap at Pricer.swift:96.
    func testSixteenDigitHoursAtTwoXTrapsInProfitSubtraction() {
        let b = Fixture.price(Fixture.lines(), hours: 1_500_000_000_000_000, multiplier: 2)
        XCTAssertEqual(b.profit, b.price - b.cost)   // never reached
    }
}
