import XCTest
@testable import Buckets

/// Probe: pins `Decimal(string:)` / `Decimal(string:locale:)` on Xcode 26.6 / macOS 26.4 so the Views layer
/// (DECISIONS 11, 30) is written against the real behaviour. Every assertion below PASSES today; it is documentation.
final class Probe_money_TextParsing: XCTestCase {
    private func p(_ s: String) -> Decimal? { Decimal(string: s) }

    func testCleanInputs() {
        XCTAssertEqual(p("2.5"), Decimal(sign: .plus, exponent: -1, significand: 25))
        XCTAssertEqual(p("+2.5"), p("2.5"))
        XCTAssertEqual(p(".5"), p("0.5"))
        XCTAssertEqual(p("-.5"), p("-0.5"))
        XCTAssertEqual(p("5."), 5)
        XCTAssertEqual(p("-0"), 0)
        XCTAssertEqual(p("-0")?.sign, .plus)          // Decimal has no negative zero
        XCTAssertEqual(p("1e3"), 1000)
        XCTAssertEqual(p("1E3"), 1000)
        XCTAssertEqual(p("1e+16"), Decimal(string: "10000000000000000"))
        XCTAssertEqual(p("25e-1"), p("2.5"))
    }

    func testRejectedInputsReturnNil() {
        XCTAssertNil(p(""))
        XCTAssertNil(p("abc"))
        XCTAssertNil(p("$2.50"))
        XCTAssertNil(p("NaN")); XCTAssertNil(p("nan")); XCTAssertNil(p("∞"))
        XCTAssertNil(p("٣"), "Arabic-Indic digits rejected")
        XCTAssertNil(p("１"), "full-width digits rejected")
        XCTAssertNil(p("1e128"), "exponent > 127 rejected, not clamped")
        XCTAssertNil(p("1e-129"), "exponent < -128 rejected")
    }

    func testPartialParsesSilentlyStopAtTheFirstBadCharacter() {
        XCTAssertEqual(p("2,500.00"), 2, "a user typing $2,500.00 gets $2")
        XCTAssertEqual(p("1,5"), 1)
        XCTAssertEqual(p("1 000"), 1)
        XCTAssertEqual(p("1'000"), 1)
        XCTAssertEqual(p("1_000"), 1)
        XCTAssertEqual(p("2.5abc"), p("2.5"))
        XCTAssertEqual(p("1.5.5"), p("1.5"))
        XCTAssertEqual(p("1..5"), 1)
        XCTAssertEqual(p("1e"), 1)
        XCTAssertEqual(p("0x10"), 0)
        XCTAssertEqual(p("3 "), 3)
    }

    func testWhitespaceAndLoneSymbolsAreNotRejected() {
        XCTAssertEqual(p(" 2.5"), p("2.5"), "leading whitespace skipped")
        XCTAssertEqual(p("\t3"), 3)
        XCTAssertEqual(p("  "), 0, "whitespace-only parses as 0, not nil")
        XCTAssertEqual(p("-"), 0, "a lone minus parses as 0, not nil")
        XCTAssertEqual(p("."), 0)
        XCTAssertEqual(p("-."), 0)
        XCTAssertEqual(p("--1"), 0)
        XCTAssertEqual(p("e3"), 0, "'e3' parses as 0 × 10^3")
    }

    func testExcessDigitsAreTruncatedNotRoundedAndNeverNil() {
        XCTAssertEqual(p(String(repeating: "9", count: 40)), Decimal(string: "99999999999999999999999999999999999999e2"))   // truncation, not 1e40
        XCTAssertEqual(p(String(repeating: "9", count: 38)), Decimal(string: "99999999999999999999999999999999999999"))
        XCTAssertEqual(p("1." + String(repeating: "0", count: 100) + "1"), 1, "digits past the 38th are dropped")
        XCTAssertEqual(p("12.3456789012345678901234567890123456789012345"), Decimal(string: "12.3456789012345678901234567890123456789"))
        XCTAssertEqual(p("0." + String(repeating: "0", count: 50) + "5"), Decimal(sign: .plus, exponent: -51, significand: 5))
        XCTAssertEqual(p("1e127")?.exponent, 127)
        XCTAssertEqual(p("1e-128")?.exponent, -128)
    }

    func testLocaleAwareParsingHonoursTheDecimalSeparatorButNotGrouping() {
        let de = Locale(identifier: "de_DE")
        XCTAssertEqual(Decimal(string: "1,5", locale: de), Decimal(string: "1.5"))
        XCTAssertEqual(Decimal(string: "2,5abc", locale: de), Decimal(string: "2.5"))
        XCTAssertEqual(Decimal(string: "1.5", locale: de), 1, "'.' is not a separator in de_DE: parse stops")
        XCTAssertEqual(Decimal(string: "1.234,5", locale: de), 1, "grouping separators are NOT understood even with a locale")
        XCTAssertEqual(Decimal(string: "1,234.5", locale: de), Decimal(string: "1.234"))
        XCTAssertEqual(Decimal(string: "1e3", locale: de), 1000)
        let en = Locale(identifier: "en_US")
        XCTAssertEqual(Decimal(string: "1,234.5", locale: en), 1, "en_US grouping comma also ends the parse")
        XCTAssertEqual(Decimal(string: "2,500.00", locale: en), 2)
        XCTAssertEqual(Decimal(string: "1,5", locale: en), 1)
    }

    func testFormatStyleParsingHandlesGroupingButAlsoIgnoresTrailingJunk() throws {
        // `Decimal.FormatStyle` parsing (what `TextField(value:format: .number)` uses) understands grouping and rejects
        // leading junk, but is lenient about trailing junk in the same way as Decimal(string:).
        let strategy = Decimal.FormatStyle(locale: Locale(identifier: "en_US")).parseStrategy
        XCTAssertEqual(try strategy.parse("2,500.00"), 2500)
        XCTAssertEqual(try strategy.parse("1,000,000.999"), Decimal(string: "1000000.999"))
        XCTAssertEqual(try strategy.parse("1 000"), 1000)
        XCTAssertEqual(try strategy.parse("6.5"), Decimal(string: "6.5"))
        XCTAssertEqual(try strategy.parse("1e3"), 1000)
        XCTAssertEqual(try strategy.parse("٣"), 3, "FormatStyle accepts Arabic-Indic digits")
        XCTAssertThrowsError(try strategy.parse("abc"))
        XCTAssertThrowsError(try strategy.parse(""))
        XCTAssertThrowsError(try strategy.parse("abc2.5"))
        XCTAssertThrowsError(try strategy.parse("$2.50"))
        XCTAssertEqual(try strategy.parse("2.5abc"), Decimal(string: "2.5"), "trailing junk ignored")
        XCTAssertEqual(try strategy.parse("1,5"), 1)
        XCTAssertEqual(try strategy.parse("-"), 0)
        XCTAssertEqual(try strategy.parse("."), 0)
    }
}
