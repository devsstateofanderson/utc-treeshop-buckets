import XCTest
@testable import Buckets

/// DECISIONS 49: negative markup, rate and minimum are treated as 0, like negative hours and qty (DECISIONS 10).
final class Probe_pricer_negatives: XCTestCase {
    private func check(_ b: Breakdown, _ e: (Int, Int, Int, Int, Int, Int, Int, Int), _ label: String,
                       file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual([b.labor, b.equipment, b.overhead, b.materials, b.consumables, b.cost, b.price, b.profit],
                       [e.0, e.1, e.2, e.3, e.4, e.5, e.6, e.7], label, file: file, line: line)
        XCTAssertEqual(b.cost, b.labor + b.equipment + b.materials + b.consumables + b.overhead, "\(label): Cost = Σ", file: file, line: line)
        XCTAssertEqual(b.profit, b.price - b.cost, "\(label): Profit = Price − Cost", file: file, line: line)
    }

    func testNegativeMarkupIsClampedToZero() {
        // −50% is treated as 0%: price = cost (above the floor), profit 0, margin 0
        let half = Fixture.price(Fixture.lines(), markup: Decimal(string: "-0.5")!)
        check(half, (99_512, 56_384, 14_400, 0, 15_000, 185_296, 185_296, 0), "markup -0.5")
        XCTAssertEqual(half.marginPct, 0)
        let minusOne = Fixture.price(Fixture.lines(), markup: -1)
        check(minusOne, (99_512, 56_384, 14_400, 0, 15_000, 185_296, 185_296, 0), "markup -1")
    }

    func testNegativeRateIsClampedLikeHoursAndQty() {
        // a −$54.08/hr row contributes nothing: cost 0, price = floor, profit = floor, margin 100%
        let b = Fixture.price([PriceLine(bucket: .labor, rateCents: -5408)])
        check(b, (0, 0, 0, 0, 0, 0, 75_000, 75_000), "negative rate")
        XCTAssertEqual(b.marginPct, 100)
        let noFloor = Fixture.price([PriceLine(bucket: .labor, rateCents: -5408)], minimum: 0)
        check(noFloor, (0, 0, 0, 0, 0, 0, 0, 0), "negative rate, no floor")
        XCTAssertEqual(noFloor.marginPct, 0)
        XCTAssertEqual(Fixture.price([PriceLine(bucket: .consumables, rateCents: -5, isOn: true, qty: Decimal(string: "0.5")!)], hours: 0, markup: 0, minimum: 0).consumables, 0)
    }

    func testNegativeMinimumIsClampedToZero() {
        let allOff = Fixture.lines().map { var l = $0; l.isOn = false; return l }
        check(Fixture.price(allOff, minimum: -1), (0, 0, 0, 0, 0, 0, 0, 0), "min -1 all off")
        // a negative floor never yields a negative price
        let neg = Fixture.price([PriceLine(bucket: .materials, rateCents: -15, isOn: true)], hours: 0, multiplier: 2, minimum: -1000)
        XCTAssertEqual(neg.price, 0)
        XCTAssertEqual(neg.profit, 0)
        XCTAssertEqual(neg.marginPct, 0)
    }
}
