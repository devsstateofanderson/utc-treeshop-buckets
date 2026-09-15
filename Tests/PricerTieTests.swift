import XCTest
@testable import Buckets

/// Exact half-cent ties in every rounding path (hourly × hours, overhead ÷ billable, qty × rate, cost × (1+markup) × multiplier).
/// Every tie sits on an EVEN integer so banker's rounding would give a different answer (BRIEF §5.2: half away from zero).
final class Probe_pricer_ties: XCTestCase {
    func testHourlyTies() {
        // 3065 × 0.5 = 1532.5 → 1533 (banker's 1532)
        XCTAssertEqual(Fixture.price([Fixture.miguel], hours: Decimal(string: "0.5")!, minimum: 0).labor, 1533)
        // 5 × 0.5 = 2.5 → 3 (banker's 2)
        XCTAssertEqual(Fixture.price([PriceLine(bucket: .equipment, rateCents: 5)], hours: Decimal(string: "0.5")!, markup: 0, minimum: 0).equipment, 3)
        // 1 × 0.5 = 0.5 → 1 (banker's 0)
        XCTAssertEqual(Fixture.price([PriceLine(bucket: .labor, rateCents: 1)], hours: Decimal(string: "0.5")!, markup: 0, minimum: 0).labor, 1)
        // a negative rate is treated as 0 (DECISIONS 49); negative ties are covered in MoneyRoundingTests
        XCTAssertEqual(Fixture.price([PriceLine(bucket: .equipment, rateCents: -5)], hours: Decimal(string: "0.5")!, markup: 0, minimum: 0).equipment, 0)
        // 3065 × 2.5 = 7662.5 → 7663 (banker's 7662)
        XCTAssertEqual(Fixture.price([Fixture.miguel], hours: Decimal(string: "2.5")!, minimum: 0).labor, 7663)
    }

    func testOverheadTies() {
        // 5 ¢/yr × 1 h ÷ 2 = 2.5 → 3 (banker's 2)
        XCTAssertEqual(Fixture.price([PriceLine(bucket: .overhead, rateCents: 5)], hours: 1, markup: 0, minimum: 0, billable: 2).overhead, 3)
        // 1 ¢/yr × 1 h ÷ 2 = 0.5 → 1
        XCTAssertEqual(Fixture.price([PriceLine(bucket: .overhead, rateCents: 1)], hours: 1, markup: 0, minimum: 0, billable: 2).overhead, 1)
        // a tie through a realistic divisor: 1,875 ¢ × 1 ÷ 750 = 2.5 → 3
        XCTAssertEqual(Fixture.price([PriceLine(bucket: .overhead, rateCents: 1875)], hours: 1, markup: 0, minimum: 0, billable: 750).overhead, 3)
        // negative rate → 0 (DECISIONS 49)
        XCTAssertEqual(Fixture.price([PriceLine(bucket: .overhead, rateCents: -5)], hours: 1, markup: 0, minimum: 0, billable: 2).overhead, 0)
    }

    func testQuantityTies() {
        // 5 × 0.5 = 2.5 → 3
        XCTAssertEqual(Fixture.price([PriceLine(bucket: .materials, rateCents: 5, isOn: true, qty: Decimal(string: "0.5")!)], hours: 0, markup: 0, minimum: 0).materials, 3)
        // 1 × 2.5 = 2.5 → 3
        XCTAssertEqual(Fixture.price([PriceLine(bucket: .consumables, rateCents: 1, isOn: true, qty: Decimal(string: "2.5")!)], hours: 0, markup: 0, minimum: 0).consumables, 3)
        // 7500 × 0.0001 = 0.75 → 1 (not a tie)
        XCTAssertEqual(Fixture.price([PriceLine(bucket: .consumables, rateCents: 7500, isOn: true, qty: Decimal(string: "0.0001")!)], hours: 0, markup: 0, minimum: 0).consumables, 1)
        // negative rate → 0 (DECISIONS 49)
        XCTAssertEqual(Fixture.price([PriceLine(bucket: .consumables, rateCents: -5, isOn: true, qty: Decimal(string: "0.5")!)], hours: 0, markup: 0, minimum: 0).consumables, 0)
        // the tie is on the SUM, not per row: 1×0.5 + 1×0.5 + 1×0.5 = 1.5 → 2 (per-row rounding: 1+1+1 = 3)
        let three = Array(repeating: PriceLine(bucket: .materials, rateCents: 1, isOn: true, qty: Decimal(string: "0.5")!), count: 3)
        XCTAssertEqual(Fixture.price(three, hours: 0, markup: 0, minimum: 0).materials, 2)
    }

    func testPriceTies() {
        // 15 × 1.35 × 2 = 40.5 → 41 (banker's 40)
        XCTAssertEqual(Fixture.price([PriceLine(bucket: .materials, rateCents: 15, isOn: true)], hours: 0, multiplier: 2, minimum: 0).price, 41)
        // 10 × 1.35 × 3 = 40.5 → 41
        XCTAssertEqual(Fixture.price([PriceLine(bucket: .materials, rateCents: 10, isOn: true)], hours: 0, multiplier: 3, minimum: 0).price, 41)
        // 100030 × 1.35 = 135040.5 → 135041 (banker's 135040)
        XCTAssertEqual(Fixture.price([PriceLine(bucket: .labor, rateCents: 100_030)], hours: 1, minimum: 0).price, 135_041)
        // 2 × 1.25 = 2.5 → 3
        XCTAssertEqual(Fixture.price([PriceLine(bucket: .materials, rateCents: 2, isOn: true)], hours: 0, markup: Decimal(string: "0.25")!, minimum: 0).price, 3)
        // a negative rate and a negative floor both clamp to 0 (DECISIONS 49)
        let neg = Fixture.price([PriceLine(bucket: .materials, rateCents: -15, isOn: true)], hours: 0, multiplier: 2, minimum: -1000)
        XCTAssertEqual(neg.price, 0)
        XCTAssertEqual(neg.profit, 0)
        XCTAssertEqual(neg.marginPct, 0)   // price 0 → margin 0
    }

    func testMarginDisplayTie() {
        // profit 1, price 8 → 12.5% exactly
        let b = Fixture.price([PriceLine(bucket: .materials, rateCents: 7, isOn: true)], hours: 0, markup: 0, minimum: 8)
        XCTAssertEqual(b.price, 8)
        XCTAssertEqual(b.profit, 1)
        XCTAssertEqual(b.marginPct, Decimal(string: "12.5")!)
        // profit 1, price 16 → 6.25% ; display one decimal: 62.5 → 63 (banker's 62)
        let c = Fixture.price([PriceLine(bucket: .materials, rateCents: 15, isOn: true)], hours: 0, markup: 0, minimum: 16)
        XCTAssertEqual(c.marginPct, Decimal(string: "6.25")!)
        XCTAssertEqual(Money.cents(c.marginPct * 10), 63)
    }
}
