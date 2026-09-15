import XCTest
@testable import Buckets

/// DECISIONS 3 vs the literal BRIEF §1 formula. Expectations from python3 decimal: with the §3.3 rows and
/// two-decimal hours 0.01…100.00, Price(rounded Cost) ≠ Price(exact cost) for 4,351 of 10,000 values and the Cost
/// figure itself ≠ round-once-at-Cost for 3,200 of them. §3.3's own integer hours never diverge.
final class Probe_spec_RoundingPipeline: XCTestCase {
    private let markup = Decimal(string: "0.35")!

    func testSection33ExactCostIsIntegralSoTheChoiceIsInvisibleThere() {
        for (lines, expected) in [(Fixture.lines(), 185_296), (Fixture.lines(miguelOn: false), 160_776),
                                  (Fixture.lines(skidSteerOn: true), 198_120), (Fixture.lines(skidSteerOn: true, stumps: 3), 225_120)] {
            let b = Fixture.price(lines)
            XCTAssertEqual(b.cost, expected)
            // exact cost in cents: (Σ labor + Σ equipment) × 8 + Σ overhead × 8 ÷ 1500 + consumables — all whole numbers
            XCTAssertEqual(b.price, Money.cents(Decimal(expected) * (1 + markup)))
        }
    }

    func testPriceComesFromTheRoundedCostAtSixAndAHalfHours() {
        // exact cost 153,365.5¢ (labor 80,853.5 + 45,812 + 11,700 + 15,000); DECISIONS 3 rounds labor first → 153,366
        let b = Fixture.price(Fixture.lines(), hours: Decimal(string: "6.5")!)
        XCTAssertEqual(b.cost, 153_366)
        XCTAssertEqual(b.price, 207_044)                                     // 153366 × 1.35 = 207044.1
        let fromExactCost = Money.cents(Decimal(string: "153365.5")! * (1 + markup))
        XCTAssertEqual(fromExactCost, 207_043)                              // 207043.425 — one cent lower
        XCTAssertNotEqual(b.price, fromExactCost)
        XCTAssertEqual(b.profit, b.price - b.cost)                           // and the header reconciles
    }

    func testCostIsTheSumOfRoundedSubtotalsNotARoundedSum() {
        // 0.01 h: labor 124.39 → 124, equipment 70.48 → 70, overhead 18, consumables 15000 → 15,212;
        // the brief-literal single rounding of 15,212.87 would show 15,213.
        let b = Fixture.price(Fixture.lines(), hours: Decimal(string: "0.01")!)
        XCTAssertEqual(b.labor, 124); XCTAssertEqual(b.equipment, 70); XCTAssertEqual(b.overhead, 18)
        XCTAssertEqual(b.cost, 15_212)
        XCTAssertEqual(b.cost, b.labor + b.equipment + b.materials + b.consumables + b.overhead)
        XCTAssertEqual(Money.cents(Decimal(string: "15212.87")!), 15_213)
    }

    func testOneCentDivergenceJustAboveTheFloor() {
        // 1.91 h: rounded-cost price 75,138 vs exact-cost price 75,139 (first divergence above the $750 floor)
        let b = Fixture.price(Fixture.lines(), hours: Decimal(string: "1.91")!)
        XCTAssertEqual(b.price, 75_138)
        let exactCost = Decimal(12_439 + 7048) * Decimal(string: "1.91")! + Decimal(2_700_000) * Decimal(string: "1.91")! / 1500 + 15_000
        XCTAssertEqual(Money.cents(exactCost * (1 + markup)), 75_139)
    }
}
