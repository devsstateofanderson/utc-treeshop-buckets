import XCTest
@testable import Buckets

/// Probe: the wrap in Money.cents reached through Pricer's `cost × (1 + markup) × multiplier`.
final class Probe_money_PricerWrap: XCTestCase {
    private let markup = Decimal(string: "0.35")!

    func testRealisticCeilingIsExact() {
        // A $100,000,000 job at 3× emergency, 35% markup: 1e10 × 4.05 = 4.05e10 cents, far below Int64.
        let lines = [PriceLine(bucket: .consumables, rateCents: 10_000_000_000, isOn: true, qty: 1)]
        let b = Pricer.price(lines: lines, hours: 0, multiplier: 3, markup: markup, minimumJobCents: 75_000, billableHours: 1500)
        XCTAssertEqual(b.cost, 10_000_000_000)
        XCTAssertEqual(b.price, 40_500_000_000)
        XCTAssertEqual(b.profit, 30_500_000_000)
        XCTAssertEqual(Money.format(b.price), "$405,000,000.00")
    }

    func testPriceNeverBelowCostEvenForAbsurdCost() {
        // cost 3e18 fits Int; 3e18 × 1.35 × 3 = 1.215e19 does not → Money.cents wraps to −6296744073709551616 →
        // price = max(75000, negative) = 75000; profit = 75000 − 3e18. The invariant Price ≥ Cost (markup ≥ 0) breaks silently.
        let lines = [PriceLine(bucket: .consumables, rateCents: 3_000_000_000_000_000_000, isOn: true, qty: 1)]
        let b = Pricer.price(lines: lines, hours: 0, multiplier: 3, markup: markup, minimumJobCents: 75_000, billableHours: 1500)
        XCTAssertEqual(b.cost, 3_000_000_000_000_000_000)
        XCTAssertGreaterThanOrEqual(b.price, b.cost, "price wrapped: \(b.price)")   // observed 75000
        XCTAssertGreaterThanOrEqual(b.profit, 0)                                     // observed -2999999999999925000
    }
}
