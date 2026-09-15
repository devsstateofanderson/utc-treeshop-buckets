import XCTest
@testable import Buckets

/// Money.cents is the single rounding gate; a NaN (any 0 ÷ 0 or x ÷ 0 in Decimal) comes out as 9, not 0 and not a trap.
/// Unreachable from Core today (every division is guarded); a Phase C hazard for "% of estimate" (DECISIONS 31).
final class Probe_spec_MoneyNaN: XCTestCase {
    func testMoneyCentsOfNaNIsGarbage() {
        let nan = Decimal(1) / Decimal(0)
        XCTAssertTrue(nan.isNaN)
        XCTAssertEqual(Money.cents(nan), 0, "NSDecimalNumber(decimal: .nan).intValue is not 0 on this toolchain")
    }
}
