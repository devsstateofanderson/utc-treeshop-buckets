import XCTest
@testable import Buckets

/// Two hourly rows whose Int rateCents sum past Int.max: `on.reduce(0) { $0 + $1.rateCents }` is checked Int
/// arithmetic and traps ("Swift runtime failure: arithmetic overflow"), killing the process — DECISIONS 10 says Pricer never throws.
final class Probe_pricer_trap_ratesum: XCTestCase {
    func testTwoIntMaxLaborRowsTrapInsteadOfPricing() {
        let lines = [PriceLine(bucket: .labor, rateCents: Int.max), PriceLine(bucket: .labor, rateCents: Int.max)]
        let b = Pricer.price(lines: lines, hours: 1, multiplier: 1, markup: Decimal(string: "0.35")!, minimumJobCents: 75_000, billableHours: 1500)
        XCTAssertGreaterThanOrEqual(b.labor, 0)   // never reached: the reduce traps before a Breakdown exists
    }
}

/// One Int.max labor row for 1 hour prices labor at exactly Int.max cents (Money.cents is exact at the Int64 edge);
/// adding a single 1-cent consumable makes `cost = labor + equipment + materials + consumables + overhead` overflow and trap.
final class Probe_pricer_trap_cost: XCTestCase {
    func testIntMaxLaborPlusOneCentConsumableTrapsInCostSum() {
        let lines = [PriceLine(bucket: .labor, rateCents: Int.max), PriceLine(bucket: .consumables, rateCents: 1, isOn: true, qty: 1)]
        let b = Pricer.price(lines: lines, hours: 1, multiplier: 1, markup: Decimal(string: "0.35")!, minimumJobCents: 75_000, billableHours: 1500)
        XCTAssertGreaterThanOrEqual(b.cost, 0)   // never reached
    }
}

/// A single Int.min labor row (a negative rate is not clamped) for 1 hour: labor = Int.min, cost = Int.min;
/// Int.min × 1.35 = −12,451,552,249,753,947,340.8 → Money.cents wraps modulo 2^64 to +5,995,191,823,955,604,275 → price;
/// `profit = price − cost` = 5.99e18 + 9.22e18 overflows Int and traps.
final class Probe_pricer_trap_profit: XCTestCase {
    func testIntMinLaborRateTrapsInProfitSubtraction() {
        let lines = [PriceLine(bucket: .labor, rateCents: Int.min)]
        let b = Pricer.price(lines: lines, hours: 1, multiplier: 1, markup: Decimal(string: "0.35")!, minimumJobCents: 75_000, billableHours: 1500)
        XCTAssertEqual(b.profit, b.price - b.cost)   // never reached
    }
}
