import XCTest
@testable import Buckets

/// Probe: NaN through the rounding pipeline. NSDecimalRound propagates NaN; NSDecimalNumber(decimal: .nan).intValue is 9.
final class Probe_money_NaN: XCTestCase {
    func testNaNRoundsToNaNAndCentsShouldBeZeroOrGuard() {
        var value = Decimal.nan
        var rounded = Decimal()
        NSDecimalRound(&rounded, &value, 0, .plain)
        XCTAssertTrue(rounded.isNaN, "NSDecimalRound propagates NaN")
        XCTAssertEqual(Money.cents(.nan), 0, "Money.cents(.nan) should be 0 (or a precondition), not an arbitrary number")   // observed 9
    }

    func testNaNIsProducedSilentlyByDecimalOverflowAndDivisionByZero() {
        let overflow = Decimal.greatestFiniteMagnitude * 10
        XCTAssertTrue(overflow.isNaN, "Decimal overflow does not trap; it yields NaN")
        let divByZero = Decimal(1) / Decimal(0)
        XCTAssertTrue(divByZero.isNaN, "Decimal ÷ 0 does not trap; it yields NaN")
        XCTAssertEqual(Money.cents(overflow), 0)      // observed 9
        XCTAssertEqual(Money.cents(divByZero), 0)     // observed 9
        XCTAssertEqual(Money.cents(Decimal(Double.nan)), 0)   // observed 9
    }
}
