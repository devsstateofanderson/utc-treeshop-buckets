import XCTest
@testable import Buckets

final class PricerTests: XCTestCase {
    // MARK: BRIEF §3.3 — the worked example, cumulative sequence (DECISIONS 15)

    func testBaseProjectIs250150() {
        let b = Fixture.price(Fixture.lines())
        XCTAssertEqual(b.labor, 99_512)          // $124.39 × 8
        XCTAssertEqual(b.equipment, 56_384)      // $70.48 × 8
        XCTAssertEqual(b.overhead, 14_400)       // $18.00 × 8
        XCTAssertEqual(b.materials, 0)
        XCTAssertEqual(b.consumables, 15_000)    // 2 × $75
        XCTAssertEqual(b.cost, 185_296)
        XCTAssertEqual(b.price, 250_150)         // exact 2501.496, rounded once
        XCTAssertEqual(b.profit, 64_854)
        XCTAssertEqual(Money.cents(b.marginPct * 10), 259)   // 25.9%
    }

    func testMiguelOffIs217048() {
        let b = Fixture.price(Fixture.lines(miguelOn: false))
        XCTAssertEqual(b.labor, 74_992)
        XCTAssertEqual(b.cost, 160_776)
        XCTAssertEqual(b.price, 217_048)         // exact 2170.476
    }

    func testMiguelOnSkidSteerOnIs267462() {
        let b = Fixture.price(Fixture.lines(skidSteerOn: true))
        XCTAssertEqual(b.equipment, 69_208)
        XCTAssertEqual(b.cost, 198_120)
        XCTAssertEqual(b.price, 267_462)
    }

    func testSkidSteerOnPlusThreeStumpsIs303912() {
        let b = Fixture.price(Fixture.lines(skidSteerOn: true, stumps: 3))
        XCTAssertEqual(b.consumables, 42_000)
        XCTAssertEqual(b.cost, 225_120)
        XCTAssertEqual(b.price, 303_912)
    }

    func testThreeStumpsWithoutSkidSteerIs286600() {
        // exact 2865.996 → rounds up to a whole dollar
        XCTAssertEqual(Fixture.price(Fixture.lines(stumps: 3)).price, 286_600)
    }

    // MARK: Floor and multiplier (DECISIONS 5, 6)

    func testFloorOneHourTwentyDollarRow() {
        let b = Fixture.price([PriceLine(bucket: .labor, rateCents: 2000)], hours: 1)
        XCTAssertEqual(b.cost, 2000)
        XCTAssertEqual(b.price, 75_000)
        XCTAssertEqual(b.profit, 73_000)
    }

    func testFloorAppliesAfterMultiplier() {
        let twenty = [PriceLine(bucket: .labor, rateCents: 2000)]
        XCTAssertEqual(Fixture.price(twenty, hours: 1, multiplier: 2).price, 75_000)       // $54 → floor
        let threeHundred = [PriceLine(bucket: .labor, rateCents: 30_000)]
        XCTAssertEqual(Fixture.price(threeHundred, hours: 1, multiplier: 1).price, 75_000) // $405 → floor
        XCTAssertEqual(Fixture.price(threeHundred, hours: 1, multiplier: 2).price, 81_000) // $810 clears it
    }

    func testFloorIsNeverMultiplied() {
        let twoHundred = [PriceLine(bucket: .labor, rateCents: 20_000)]
        XCTAssertEqual(Fixture.price(twoHundred, hours: 1, multiplier: 3).price, 81_000)   // 200 × 1.35 × 3
        let oneHundred = [PriceLine(bucket: .labor, rateCents: 10_000)]
        XCTAssertEqual(Fixture.price(oneHundred, hours: 1, multiplier: 3).price, 75_000)   // 405 < 750
    }

    func testTwoXDoublesAndThreeXTriplesACentExactPrice() {
        let lines = [PriceLine(bucket: .labor, rateCents: 10_000)]
        XCTAssertEqual(Fixture.price(lines, hours: 10, multiplier: 1).price, 135_000)
        XCTAssertEqual(Fixture.price(lines, hours: 10, multiplier: 2).price, 270_000)
        XCTAssertEqual(Fixture.price(lines, hours: 10, multiplier: 3).price, 405_000)
    }

    func testMultiplierIsInsideTheRoundOnceRule() {
        // 1852.96 × 1.35 × 2 = 5002.992 → 5002.99, not 2 × 2501.50
        XCTAssertEqual(Fixture.price(Fixture.lines(), multiplier: 2).price, 500_299)
        XCTAssertEqual(Fixture.price(Fixture.lines(), multiplier: 3).price, 750_449)
    }

    // MARK: Rounding (DECISIONS 3, 4)

    func testHalfCentRoundsAwayFromZero() {
        // 100030 × 1.35 = 135040.5 exactly
        let b = Fixture.price([PriceLine(bucket: .labor, rateCents: 100_030)], hours: 1)
        XCTAssertEqual(b.price, 135_041)
        // Miguel alone for half an hour: 3065 × 0.5 = 1532.5 → 1533 (banker's rounding would give 1532)
        let half = Fixture.price([Fixture.miguel], hours: Decimal(string: "0.5")!)
        XCTAssertEqual(half.labor, 1533)
    }

    func testFractionalHoursRoundEachSubtotalOnce() {
        let b = Fixture.price(Fixture.lines(), hours: Decimal(string: "6.5")!)
        XCTAssertEqual(b.labor, 80_854)      // 808.535 → 808.54
        XCTAssertEqual(b.equipment, 45_812)
        XCTAssertEqual(b.overhead, 11_700)
        XCTAssertEqual(b.consumables, 15_000)
        XCTAssertEqual(b.cost, 153_366)      // Σ of the rounded subtotals
        XCTAssertEqual(b.price, 207_044)     // 153366 × 1.35 = 207044.1
        XCTAssertEqual(b.profit, b.price - b.cost)
    }

    func testOverheadIsSummedThenDividedOnce() {
        // A single $1,000/yr row for 8 hours: 100000¢ × 8 ÷ 1500 = 533.33…¢ → 533 (per-row $0.67/hr × 8 would give 536)
        let b = Fixture.price([PriceLine(bucket: .overhead, rateCents: 100_000)])
        XCTAssertEqual(b.overhead, 533)
        // Three $1,000/yr rows: 300000¢ × 8 ÷ 1500 = 1600¢ exactly (not 3 × 533 = 1599)
        let three = Fixture.price(Array(repeating: PriceLine(bucket: .overhead, rateCents: 100_000), count: 3))
        XCTAssertEqual(three.overhead, 1600)
    }

    func testHeaderAlwaysReconciles() {
        for hours in ["0.25", "1", "6.5", "7.33", "8", "100"] {
            let b = Fixture.price(Fixture.lines(skidSteerOn: true, stumps: Decimal(string: "2.5")!),
                                  hours: Decimal(string: hours)!)
            XCTAssertEqual(b.cost, b.labor + b.equipment + b.materials + b.consumables + b.subcontractors + b.overhead, hours)
            XCTAssertEqual(b.profit, b.price - b.cost, hours)
        }
    }

    // MARK: Edge cases (PROMPT Layer 6 Phase B)

    func testZeroHoursPricesAtTheFloor() {
        var lines = Fixture.lines()
        lines = lines.map { var l = $0; if l.bucket == .consumables { l.isOn = false }; return l }
        let b = Fixture.price(lines, hours: 0)
        XCTAssertEqual(b.cost, 0)
        XCTAssertEqual(b.price, 75_000)
        XCTAssertEqual(b.profit, 75_000)
        XCTAssertEqual(b.marginPct, 100)
    }

    func testAllRowsOffPricesAtTheFloor() {
        let lines = Fixture.lines().map { var l = $0; l.isOn = false; return l }
        let b = Fixture.price(lines)
        XCTAssertEqual(b.cost, 0)
        XCTAssertEqual(b.price, 75_000)
    }

    func testQuantityZeroContributesNothing() {
        var lines = Fixture.lines()
        lines[lines.firstIndex(of: Fixture.dumpFee)!].qty = 0
        let b = Fixture.price(lines)
        XCTAssertEqual(b.consumables, 0)
        XCTAssertEqual(b.cost, 170_296)
        XCTAssertEqual(b.price, 229_900)     // 2298.996 → 2299.00
    }

    func testZeroDollarOverheadRowChangesNothing() {
        let b = Fixture.price(Fixture.lines() + [PriceLine(bucket: .overhead, rateCents: 0)])
        XCTAssertEqual(b.price, 250_150)
    }

    func testOffLinesAreIgnoredRegardlessOfQty() {
        let b = Fixture.price(Fixture.lines() + [PriceLine(bucket: .consumables, rateCents: 180_000, isOn: false, qty: 50)])
        XCTAssertEqual(b.price, 250_150)
    }

    func testNegativeInputsAreClampedNotCrashed() {
        let negHours = Fixture.price(Fixture.lines(), hours: -5)
        XCTAssertEqual(negHours.labor, 0)
        XCTAssertEqual(negHours.cost, 15_000)
        var lines = Fixture.lines()
        lines[lines.firstIndex(of: Fixture.dumpFee)!].qty = -3
        XCTAssertEqual(Fixture.price(lines).consumables, 0)
        XCTAssertEqual(Fixture.price(Fixture.lines(), multiplier: 0).price, 250_150)
        XCTAssertEqual(Fixture.price(Fixture.lines(), multiplier: -1).price, 250_150)
    }

    func testBillableHoursZeroMakesOverheadZeroWithoutThrowing() {
        let b = Fixture.price(Fixture.lines(), billable: 0)
        XCTAssertEqual(b.overhead, 0)
        XCTAssertEqual(b.cost, 170_896)
    }

    func testMarginIsZeroWhenPriceIsZero() {
        let b = Fixture.price([], hours: 8, minimum: 0)
        XCTAssertEqual(b.price, 0)
        XCTAssertEqual(b.marginPct, 0)
    }

    func testEmptyProject() {
        let b = Fixture.price([], hours: 8)
        XCTAssertEqual(b, Breakdown(labor: 0, equipment: 0, materials: 0, consumables: 0, subcontractors: 0, overhead: 0,
                                    cost: 0, price: 75_000, profit: 75_000, marginPct: 100))
    }

    func testMarkupToMargin() {
        // 35% markup = 25.9% margin (7/27)
        let b = Fixture.price(Fixture.lines())
        XCTAssertEqual(Money.cents(b.marginPct * 100), 2593)   // 25.93% to two decimals
    }

    func testSnapshotValuesAreWhatIsPriced() {
        // A PriceLine is a copy; changing the source number after the copy exists changes nothing.
        var marcusRate = 5408
        let line = PriceLine(bucket: .labor, rateCents: marcusRate)
        marcusRate = 9999
        XCTAssertEqual(Fixture.price([line], hours: 8).labor, 43_264)
        XCTAssertNotEqual(marcusRate, line.rateCents)
    }
}
