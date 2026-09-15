import XCTest
@testable import Buckets

/// Every BRIEF §3.3 figure and the DECISIONS 15 cumulative sequence, recomputed independently
/// (exact rational arithmetic, half-away-from-zero once per figure) — never from the code's own output.
final class Probe_pricer_spec_numbers: XCTestCase {
    private func assertBreakdown(_ b: Breakdown, labor: Int, equipment: Int, overhead: Int, materials: Int, consumables: Int,
                                 cost: Int, price: Int, profit: Int, marginTenths: Int, _ label: String,
                                 file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(b.labor, labor, "\(label) labor", file: file, line: line)
        XCTAssertEqual(b.equipment, equipment, "\(label) equipment", file: file, line: line)
        XCTAssertEqual(b.overhead, overhead, "\(label) overhead", file: file, line: line)
        XCTAssertEqual(b.materials, materials, "\(label) materials", file: file, line: line)
        XCTAssertEqual(b.consumables, consumables, "\(label) consumables", file: file, line: line)
        XCTAssertEqual(b.cost, cost, "\(label) cost", file: file, line: line)
        XCTAssertEqual(b.price, price, "\(label) price", file: file, line: line)
        XCTAssertEqual(b.profit, profit, "\(label) profit", file: file, line: line)
        XCTAssertEqual(Money.cents(b.marginPct * 10), marginTenths, "\(label) margin one decimal", file: file, line: line)
        XCTAssertEqual(b.cost, b.labor + b.equipment + b.materials + b.consumables + b.overhead, "\(label) Cost = Σ subtotals", file: file, line: line)
        XCTAssertEqual(b.profit, b.price - b.cost, "\(label) Profit = Price − Cost", file: file, line: line)
    }

    func testSection33Base() {
        // 12439×8 = 99512 ; 7048×8 = 56384 ; 2,700,000×8/1500 = 14400 ; 2×7500 = 15000 ; cost 185296 ; ×1.35 = 2501.496 → 250150
        assertBreakdown(Fixture.price(Fixture.lines()), labor: 99_512, equipment: 56_384, overhead: 14_400, materials: 0,
                        consumables: 15_000, cost: 185_296, price: 250_150, profit: 64_854, marginTenths: 259, "base")
    }

    func testSection33CumulativeSequence() {
        // Miguel off: labor 9374×8 = 74992 ; cost 160776 ; ×1.35 = 2170.476 → 217048
        assertBreakdown(Fixture.price(Fixture.lines(miguelOn: false)), labor: 74_992, equipment: 56_384, overhead: 14_400, materials: 0,
                        consumables: 15_000, cost: 160_776, price: 217_048, profit: 56_272, marginTenths: 259, "miguel off")
        // Miguel on + skid steer on: equipment 8651×8 = 69208 ; cost 198120 ; ×1.35 = 2674.62 exactly
        assertBreakdown(Fixture.price(Fixture.lines(skidSteerOn: true)), labor: 99_512, equipment: 69_208, overhead: 14_400, materials: 0,
                        consumables: 15_000, cost: 198_120, price: 267_462, profit: 69_342, marginTenths: 259, "skid on")
        // + 3 stumps (skid steer still on): consumables 15000 + 27000 ; cost 225120 ; ×1.35 = 3039.12 exactly
        assertBreakdown(Fixture.price(Fixture.lines(skidSteerOn: true, stumps: 3)), labor: 99_512, equipment: 69_208, overhead: 14_400, materials: 0,
                        consumables: 42_000, cost: 225_120, price: 303_912, profit: 78_792, marginTenths: 259, "skid + stumps")
        // DECISIONS 15 aside: 3 stumps without the skid steer = 212296 × 1.35 = 2865.996 → 286600
        XCTAssertEqual(Fixture.price(Fixture.lines(stumps: 3)).price, 286_600)
    }

    func testTwoXOfSection33Is500299Not500300() {
        // 185296 × 1.35 × 2 = 500299.2 → 500299 (round once, DECISIONS 6); 3× = 750448.8 → 750449
        let two = Fixture.price(Fixture.lines(), multiplier: 2)
        XCTAssertEqual(two.price, 500_299)
        XCTAssertNotEqual(two.price, 2 * 250_150)
        XCTAssertEqual(two.profit, 315_003)
        XCTAssertEqual(Fixture.price(Fixture.lines(), multiplier: 3).price, 750_449)
    }

    func testMarginIsAWholePercentUnroundedAndZeroAtZeroPrice() {
        let b = Fixture.price(Fixture.lines())
        // 64854 / 250150 × 100 = 25.92604437…
        XCTAssertGreaterThan(b.marginPct, Decimal(string: "25.926044")!)
        XCTAssertLessThan(b.marginPct, Decimal(string: "25.926045")!)
        // skid-on case is exactly 700/27 = 25.925925…
        let skid = Fixture.price(Fixture.lines(skidSteerOn: true))
        XCTAssertEqual(Money.cents(skid.marginPct * 1_000_000), 25_925_926)
        // markup 35% is a 25.9% margin everywhere the floor does not bite
        XCTAssertEqual(Money.cents(b.marginPct * 10), 259)
        // price 0 → margin 0, not a division trap
        XCTAssertEqual(Fixture.price([], minimum: 0).marginPct, 0)
        XCTAssertEqual(Fixture.price([], minimum: 0).price, 0)
    }

    func testBreakdownSubscriptMatchesFields() {
        let b = Breakdown(labor: 1, equipment: 2, materials: 3, consumables: 4, overhead: 5, cost: 15, price: 20, profit: 5, marginPct: 25)
        XCTAssertEqual(b[.labor], 1)
        XCTAssertEqual(b[.equipment], 2)
        XCTAssertEqual(b[.materials], 3)
        XCTAssertEqual(b[.consumables], 4)
        XCTAssertEqual(b[.overhead], 5)
        XCTAssertEqual(Bucket.allCases.map { b[$0] }.reduce(0, +), b.cost)
        XCTAssertEqual(Breakdown.zero, Breakdown(labor: 0, equipment: 0, materials: 0, consumables: 0, overhead: 0, cost: 0, price: 0, profit: 0, marginPct: 0))
    }

    func testHourlyRowsIgnoreQtyAndQuantityRowsIgnoreHours() {
        // BRIEF §5.3: qty is "ignored for hourly rows"
        let laborQty0 = Fixture.price([PriceLine(bucket: .labor, rateCents: 5408, qty: 0)], hours: 8, minimum: 0)
        XCTAssertEqual(laborQty0.labor, 43_264)
        let laborQty7 = Fixture.price([PriceLine(bucket: .labor, rateCents: 5408, qty: 7)], hours: 8, minimum: 0)
        XCTAssertEqual(laborQty7.labor, 43_264)
        let overheadQty0 = Fixture.price([PriceLine(bucket: .overhead, rateCents: 2_700_000, qty: 0)], hours: 8, minimum: 0)
        XCTAssertEqual(overheadQty0.overhead, 14_400)
        // quantity rows contribute at zero hours
        let zeroHours = Fixture.price(Fixture.lines(), hours: 0)
        XCTAssertEqual(zeroHours.consumables, 15_000)
        XCTAssertEqual(zeroHours.cost, 15_000)
        XCTAssertEqual(zeroHours.price, 75_000)
        XCTAssertEqual(zeroHours.marginPct, 80)
    }
}
