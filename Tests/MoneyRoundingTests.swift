import XCTest
@testable import Buckets

/// Probe: everything that PASSED. Expected values from python3 decimal (ROUND_HALF_UP on |x|) and hand-computed strings.
/// Locale independence was additionally confirmed by running this class with `-testLanguage fr -testRegion FR`
/// (Locale.current became en_FR, the current-locale grouping became "1 000 000", Money.format stayed "$1,000,000.00").
final class Probe_money_Verified: XCTestCase {
    private func d(_ s: String) -> Decimal { Decimal(string: s)! }

    func testExactTiesPositiveAndNegative() {
        XCTAssertEqual(Money.cents(d("2.5")), 3);   XCTAssertEqual(Money.cents(d("-2.5")), -3)
        XCTAssertEqual(Money.cents(d("0.5")), 1);   XCTAssertEqual(Money.cents(d("-0.5")), -1)
        XCTAssertEqual(Money.cents(d("1.5")), 2);   XCTAssertEqual(Money.cents(d("-1.5")), -2)
        XCTAssertEqual(Money.cents(d("3.5")), 4);   XCTAssertEqual(Money.cents(d("-3.5")), -4)
        XCTAssertEqual(Money.cents(d("0.5")) + Money.cents(d("2.5")), 4, "banker's would give 2")
    }

    func testTiesComputedByDecimalArithmetic() {
        XCTAssertEqual(Money.cents(Decimal(5) / 2), 3)
        XCTAssertEqual(Money.cents(Decimal(-5) / 2), -3)
        XCTAssertEqual(Money.cents(Decimal(1) / 2), 1)
        XCTAssertEqual(Money.cents(Decimal(-1) / 2), -1)
        XCTAssertEqual(Money.cents(Decimal(3065) * d("0.5")), 1533)          // Miguel × ½ hr = 1532.5
        XCTAssertEqual(Money.cents(Decimal(100_030) * d("1.35")), 135_041)   // 135040.5
        XCTAssertEqual(Money.cents(Decimal(sign: .plus, exponent: -3, significand: 2500)), 3)
        XCTAssertEqual(Money.cents(Decimal(sign: .minus, exponent: -1, significand: 5)), -1)
        XCTAssertEqual(Money.cents(Decimal(sign: .plus, exponent: 2, significand: 3)), 300)
        XCTAssertEqual(Money.cents(d("25e-1")), 3)
        XCTAssertEqual(Money.cents(d("-25E-1")), -3)
    }

    func testJustAboveAndBelowATieWithTwentySignificantDigits() {
        XCTAssertEqual(Money.cents(d("2.5000000000000000001")), 3)
        XCTAssertEqual(Money.cents(d("2.4999999999999999999")), 2)
        XCTAssertEqual(Money.cents(d("-2.5000000000000000001")), -3)
        XCTAssertEqual(Money.cents(d("-2.4999999999999999999")), -2)
        XCTAssertEqual(Money.cents(d("0.49999999999999999999")), 0)
        XCTAssertEqual(Money.cents(d("-0.49999999999999999999")), 0)
        XCTAssertEqual(Money.cents(d("0.50000000000000000001")), 1)
    }

    func testThirtyEightSignificantDigits() {
        XCTAssertEqual(Money.cents(d("1234567890123456.7890123456789012345678")), 1_234_567_890_123_457)
        XCTAssertEqual(Money.cents(d("-1234567890123456.7890123456789012345678")), -1_234_567_890_123_457)
        XCTAssertEqual(Money.cents(d("0.12345678901234567890123456789012345678")), 0)
        XCTAssertEqual(Money.cents(d("0.50000000000000000000000000000000000001")), 1)
        XCTAssertEqual(Money.cents(d("0.49999999999999999999999999999999999999")), 0)
        XCTAssertEqual(Money.cents(d("2.49999999999999999999999999999999999999")), 2)   // 39 digits still fit below 2^128
        XCTAssertEqual(Money.cents(d("2.50000000000000000000000000000000000001")), 3)
        XCTAssertEqual(Money.cents(d("9223372036854775806.5")), Int.max)
        XCTAssertEqual(Money.cents(d("999999999999999999.5")), 1_000_000_000_000_000_000)
    }

    func testRepeatingDecimalsAndTinyValues() {
        XCTAssertEqual(Money.cents(Decimal(1) / 3 * 3), 1)                 // 0.999…9
        XCTAssertEqual(Money.cents(Decimal(2) / 3), 1)
        XCTAssertEqual(Money.cents(Decimal(100_000) * 8 / 1500), 533)
        XCTAssertEqual(Money.cents(Decimal(-100_000) * 8 / 1500), -533)
        XCTAssertEqual(Money.cents(d("1e-100")), 0)
        XCTAssertEqual(Money.cents(d("-1e-100")), 0)
        XCTAssertEqual(Money.cents(d("1e-128")), 0)
    }

    func testNegativeZeroDoesNotExist() {
        XCTAssertEqual(Money.cents(d("-0")), 0)
        XCTAssertEqual(Money.cents(d("-0.4")), 0)
        XCTAssertEqual(Money.cents(Decimal(sign: .minus, exponent: 0, significand: 0)), 0)
        XCTAssertEqual(d("-0").sign, .plus)
        XCTAssertEqual(Money.format(Money.cents(d("-0.4"))), "$0.00")
    }

    func testDecimalFromCentsIsExactEverywhere() {
        for c in stride(from: -100_000, through: 100_000, by: 7) {
            XCTAssertEqual(Money.cents(Money.decimal(cents: c) * 100), c)
            XCTAssertEqual(Money.decimal(cents: c), Decimal(string: "\(c)")! / 100)
        }
        XCTAssertEqual(Money.decimal(cents: -1), d("-0.01"))
        XCTAssertEqual(Money.decimal(cents: Int.max), d("92233720368547758.07"))
        XCTAssertEqual(Money.decimal(cents: Int.min), d("-92233720368547758.08"))
        XCTAssertEqual(Money.decimal(cents: Int.max) * 100, Decimal(Int.max))
        XCTAssertEqual(Money.decimal(cents: Int.min) * 100, Decimal(Int.min))
        XCTAssertEqual(Money.cents(Money.decimal(cents: Int.max) * 100), Int.max)
        XCTAssertEqual(Money.cents(Money.decimal(cents: Int.min) * 100), Int.min)
    }

    func testFormatStrings() {
        XCTAssertEqual(Money.format(0), "$0.00");        XCTAssertEqual(Money.format(1), "$0.01")
        XCTAssertEqual(Money.format(9), "$0.09");        XCTAssertEqual(Money.format(10), "$0.10")
        XCTAssertEqual(Money.format(99), "$0.99");       XCTAssertEqual(Money.format(100), "$1.00")
        XCTAssertEqual(Money.format(101), "$1.01");      XCTAssertEqual(Money.format(999), "$9.99")
        XCTAssertEqual(Money.format(99_999), "$999.99"); XCTAssertEqual(Money.format(100_000), "$1,000.00")
        XCTAssertEqual(Money.format(250_150), "$2,501.50")
        XCTAssertEqual(Money.format(-1), "-$0.01");      XCTAssertEqual(Money.format(-100), "-$1.00")
        XCTAssertEqual(Money.format(-64_854), "-$648.54"); XCTAssertEqual(Money.format(-100_000_000), "-$1,000,000.00")
        XCTAssertEqual(Money.format(123_456_789), "$1,234,567.89")
        XCTAssertEqual(Money.format(1_000_000_000_000), "$10,000,000,000.00")
        XCTAssertEqual(Money.format(999_999_999_999_999_999), "$9,999,999,999,999,999.99")
        XCTAssertEqual(Money.format(Int.max), "$92,233,720,368,547,758.07")
        XCTAssertEqual(Money.format(-Int.max), "-$92,233,720,368,547,758.07")
    }

    func testFormatIsASCIIOnlyAndPinnedToEnUS() {
        for c in [0, 1, 99, 100, 250_150, -64_854, 100_000_000, 123_456_789, Int.max, -Int.max] {
            let s = Money.format(c)
            XCTAssertTrue(s.unicodeScalars.allSatisfy { $0.isASCII }, "non-ASCII scalar in \(s)")
            XCTAssertTrue(s.allSatisfy { "$-,.0123456789".contains($0) }, "unexpected character in \(s)")
        }
        // The .locale() modifier is what decides grouping: other locales differ, Money.format does not.
        XCTAssertEqual(1_000_000.formatted(.number.grouping(.automatic).locale(Locale(identifier: "de_DE"))), "1.000.000")
        XCTAssertEqual(1_000_000.formatted(.number.grouping(.automatic).locale(Locale(identifier: "en_IN"))), "10,00,000")
        XCTAssertTrue(1_000_000.formatted(.number.grouping(.automatic).locale(Locale(identifier: "fr_FR"))).unicodeScalars.contains { $0.value == 0x202F })
        XCTAssertEqual(Money.format(100_000_000), "$1,000,000.00", "current locale: \(Locale.current.identifier)")
        XCTAssertEqual(String(format: "%02d", 5), "05")
    }

    func testFormatOfEverySection33Figure() {
        let pairs: [(String, String)] = [
            ("1852.96", "$1,852.96"), ("2501.496", "$2,501.50"), ("2170.476", "$2,170.48"), ("2674.62", "$2,674.62"),
            ("3039.12", "$3,039.12"), ("2865.996", "$2,866.00"), ("648.54", "$648.54"), ("5002.992", "$5,002.99"),
            ("-0.004", "$0.00"), ("-0.005", "-$0.01"), ("0.005", "$0.01"), ("0.004", "$0.00"),
        ]
        for (dollars, text) in pairs {
            XCTAssertEqual(Money.format(Money.cents(Decimal(string: dollars)! * 100)), text, dollars)
        }
    }
}
