import XCTest
@testable import Buckets

/// Money.format at the Int extremes, including Int.min (formatted through the unsigned magnitude, so no trap).
final class Probe_money_FormatIntMin: XCTestCase {
    func testIntMaxAndNegativeIntMaxFormatExactly() {
        XCTAssertEqual(Money.format(Int.max), "$92,233,720,368,547,758.07")
        XCTAssertEqual(Money.format(-Int.max), "-$92,233,720,368,547,758.07")
        XCTAssertEqual(Money.format(Int.min + 1), "-$92,233,720,368,547,758.07")
    }

    func testIntMinFormats() {
        XCTAssertEqual(Money.format(Int.min), "-$92,233,720,368,547,758.08")
    }

    func testChainFromCentsToFormatSaturates() {
        let saturated = Money.cents(Decimal(string: "9223372036854775808")!)
        XCTAssertEqual(saturated, Int.max)
        XCTAssertEqual(Money.format(saturated), "$92,233,720,368,547,758.07")
        XCTAssertEqual(Money.format(Money.cents(Decimal(string: "-1e30")!)), "-$92,233,720,368,547,758.08")
    }
}
