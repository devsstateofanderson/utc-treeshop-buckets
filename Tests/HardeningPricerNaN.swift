import XCTest
@testable import Buckets

/// Decimal.nan inputs and Decimal overflow (which yields NaN, not a trap). DECISIONS 10: "Pricer never throws";
/// a NaN must not become money. Expected: a NaN parameter contributes nothing (as negative inputs do).
final class Probe_pricer_nan: XCTestCase {
    func testNaNHoursQtyAndBillableContributeNothing() {
        let hours = Fixture.price(Fixture.lines(), hours: .nan)
        XCTAssertEqual(hours.labor, 0); XCTAssertEqual(hours.equipment, 0); XCTAssertEqual(hours.overhead, 0)
        XCTAssertEqual(hours.cost, 15_000); XCTAssertEqual(hours.price, 75_000)
        var lines = Fixture.lines()
        lines[lines.firstIndex(of: Fixture.dumpFee)!].qty = .nan
        XCTAssertEqual(Fixture.price(lines).consumables, 0)
        let billable = Fixture.price(Fixture.lines(), billable: .nan)
        XCTAssertEqual(billable.overhead, 0)
        XCTAssertEqual(billable.cost, 170_896)
    }

    func testNaNMarkupDoesNotBecomeNineCents() {
        // Money.cents(.nan) returns 9 on this toolchain (NSDecimalNumber.notANumber.intValue); with the floor off the price is $0.09.
        let b = Fixture.price(Fixture.lines(), markup: .nan, minimum: 0)
        XCTAssertNotEqual(b.price, 9, "NaN markup priced the §3.3 job at 9 cents")
        XCTAssertGreaterThanOrEqual(b.price, b.cost, "a NaN markup must not price below cost")
        // with the floor on, the floor masks it: price 75000, profit −110296
        let floored = Fixture.price(Fixture.lines(), markup: .nan)
        XCTAssertGreaterThanOrEqual(floored.price, floored.cost)
    }

    func testDecimalOverflowInHoursDoesNotBecomeNineCents() {
        // 12439 × greatestFiniteMagnitude overflows Decimal → NaN → Money.cents → 9
        let b = Fixture.price(Fixture.lines(), hours: .greatestFiniteMagnitude, minimum: 0)
        XCTAssertNotEqual(b.labor, 9, "labor subtotal became 9 cents from a NaN product")
        XCTAssertNotEqual(b.equipment, 9)
        XCTAssertNotEqual(b.overhead, 9)
    }

    func testMoneyCentsOfNaNIsNotNine() {
        XCTAssertEqual(Money.cents(.nan), 0)
        XCTAssertEqual(Money.cents(Decimal.greatestFiniteMagnitude * 10), 0)
    }
}
