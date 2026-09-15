import XCTest
@testable import Buckets

/// Probe: Money.cents outside the Int64 range. Expected values are the sane clamp; observed values wrap mod 2^64.
final class Probe_money_RangeWrap: XCTestCase {
    private func d(_ s: String) -> Decimal { Decimal(string: s)! }

    func testIntMaxPlusOneWrapsToIntMin() {
        XCTAssertEqual(Money.cents(d("9223372036854775808")), Int.max)      // observed Int.min
        XCTAssertEqual(Money.cents(d("9223372036854775807.5")), Int.max)    // rounds to Int.max + 1 first; observed Int.min
        XCTAssertEqual(Money.cents(d("-9223372036854775809")), Int.min)     // observed Int.max
        XCTAssertEqual(Money.cents(d("-9223372036854775808.5")), Int.min)   // observed Int.max
    }

    func testValuesWellBeyondInt64() {
        XCTAssertEqual(Money.cents(d("1e19")), Int.max)                                     // observed -8446744073709551616 (= 1e19 - 2^64)
        XCTAssertEqual(Money.cents(d("-1e19")), Int.min)                                    // observed 8446744073709551616
        XCTAssertEqual(Money.cents(d("1e20")), Int.max)                                     // observed 7766279631452241920 (= 1e20 - 5*2^64)
        XCTAssertEqual(Money.cents(d("9.3e18")), Int.max)                                   // observed -9146744073709551616
        XCTAssertEqual(Money.cents(d("12345678901234567890123456789012345678")), Int.max)   // 38 digits; observed -4302749291975740594
    }

    func testGreatestFiniteMagnitudeDoesNotBecomeZero() {
        XCTAssertEqual(Money.cents(Decimal.greatestFiniteMagnitude), Int.max)   // observed 0
        XCTAssertEqual(Money.cents(-Decimal.greatestFiniteMagnitude), Int.min)  // observed 0
        XCTAssertEqual(Money.cents(Decimal.leastFiniteMagnitude), Int.min)      // observed 0
    }

    func testInsideInt64IsExactAndDoesNotGoThroughDouble() {
        XCTAssertEqual(Money.cents(d("9223372036854775807")), Int.max)
        XCTAssertEqual(Money.cents(d("-9223372036854775808")), Int.min)
        XCTAssertEqual(Money.cents(d("9223372036854775806.5")), Int.max)
        XCTAssertEqual(Money.cents(d("9007199254740993")), 9_007_199_254_740_993)   // 2^53 + 1
        XCTAssertEqual(Money.cents(d("1234567890123456789")), 1_234_567_890_123_456_789)
        XCTAssertEqual(Money.cents(d("9e18")), 9_000_000_000_000_000_000)
        XCTAssertEqual(Money.cents(d("9.2e18")), 9_200_000_000_000_000_000)
        XCTAssertEqual(Money.cents(d("1e18")), 1_000_000_000_000_000_000)
        XCTAssertEqual(Money.cents(d("123e16")), 1_230_000_000_000_000_000)
    }
}
