import XCTest
@testable import Buckets

/// Probe: the DECISIONS 11/12 lift from @AppStorage Double to Decimal, for the Views/Models author.
final class Probe_money_DoubleLift: XCTestCase {
    func testDecimalFromDoubleCorruptsOnlySomeLiterals() {
        XCTAssertNotEqual(Decimal(0.07), Decimal(string: "0.07")!)     // 0.07000000000000001024
        XCTAssertEqual(Decimal(0.35), Decimal(string: "0.35")!)        // coincidentally exact
        XCTAssertEqual(Decimal(1.35), Decimal(string: "1.35")!)        // coincidentally exact
        XCTAssertEqual(Decimal(2.675), Decimal(string: "2.675")!)      // coincidentally exact
        XCTAssertEqual(Money.cents(Decimal(2.675) * 100), 268)
    }

    func testLiftingThroughTheDescriptionIsExact() {
        for (double, text) in [(35.0, "35"), (30.0, "30"), (7.0, "7"), (0.07, "0.07"), (32.5, "32.5"), (1e-7, "0.0000001"), (1e16, "10000000000000000")] {
            XCTAssertEqual(Decimal(string: "\(double)"), Decimal(string: text), "\(double)")
        }
        XCTAssertEqual(Decimal(string: "\(35.0)")! / 100, Decimal(string: "0.35"))
    }

    func testNonFiniteDoublesAreNotSafe() throws {
        XCTAssertTrue(Decimal(Double.nan).isNaN)
        XCTAssertTrue(Decimal(1e300).isNaN, "a Double beyond Decimal's range becomes NaN silently")
        XCTAssertTrue(Decimal(Double.greatestFiniteMagnitude).isNaN)
        XCTAssertEqual(Money.cents(Decimal(Double.nan)), 0, "a NaN amount is 0 cents (DECISIONS 49)")
        XCTAssertEqual(Money.decimal(from: Double.nan), 0)
        XCTAssertEqual(Money.decimal(from: Double.infinity), 0)
        XCTAssertEqual(Money.decimal(from: 32.5), Decimal(string: "32.5")!)
        // Decimal(Double.infinity) traps the process (exit 133 / SIGTRAP). Guarded; set PROBE_TRAPS=1 to observe in isolation.
        try XCTSkipUnless(ProcessInfo.processInfo.environment["PROBE_TRAPS"] == "1", "Decimal(Double.infinity) traps")
        _ = Decimal(Double.infinity)
    }
}
