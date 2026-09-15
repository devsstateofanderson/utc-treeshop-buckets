import XCTest
@testable import Buckets

/// The shared fields' parsing contract (DECISIONS 30, 51).
final class FieldParsingTests: XCTestCase {
    func testDecimalFieldAcceptsPlainNumbersOnly() {
        XCTAssertEqual(DecimalField.parse(""), 0)
        XCTAssertEqual(DecimalField.parse("  "), 0)
        XCTAssertEqual(DecimalField.parse("8"), 8)
        XCTAssertEqual(DecimalField.parse("6.5"), Decimal(string: "6.5")!)
        XCTAssertEqual(DecimalField.parse("6.25"), Decimal(string: "6.25")!)
        XCTAssertEqual(DecimalField.parse(" 2.5 "), Decimal(string: "2.5")!)
        XCTAssertEqual(DecimalField.parse("999999.99"), Decimal(string: "999999.99")!)
        XCTAssertEqual(DecimalField.parse("99999.99", maximum: Decimal(string: "99999.99")!), Decimal(string: "99999.99")!)
        XCTAssertNil(DecimalField.parse("100000", maximum: Decimal(string: "99999.99")!))
        XCTAssertNil(DecimalField.parse("6.333"))
        XCTAssertNil(DecimalField.parse("-1"))
        XCTAssertNil(DecimalField.parse("."))
        XCTAssertNil(DecimalField.parse("-"))
        XCTAssertNil(DecimalField.parse("2,500"))
        XCTAssertNil(DecimalField.parse("2.5abc"))
        XCTAssertNil(DecimalField.parse("1e3"))
        XCTAssertNil(DecimalField.parse("abc"))
        XCTAssertNil(DecimalField.parse("1.5.5"))
        XCTAssertNil(DecimalField.parse("1000000"))
    }

    func testCentsFieldParsesDollars() {
        XCTAssertEqual(CentsField.parse(""), 0)
        XCTAssertEqual(CentsField.parse("54.08"), 5408)
        XCTAssertEqual(CentsField.parse("$2,500.00"), 250_000)
        XCTAssertEqual(CentsField.parse("2,500"), 250_000)
        XCTAssertEqual(CentsField.parse("85"), 8500)
        XCTAssertEqual(CentsField.parse("0.5"), 50)
        XCTAssertEqual(CentsField.parse("9999999.99"), 999_999_999)
        XCTAssertNil(CentsField.parse("10000000"))
        XCTAssertNil(CentsField.parse("54.085"))
        XCTAssertNil(CentsField.parse("-5"))
        XCTAssertNil(CentsField.parse("abc"))
        XCTAssertNil(CentsField.parse("1e3"))
    }

    func testFieldStrings() {
        XCTAssertEqual(DecimalField.string(0), "")
        XCTAssertEqual(DecimalField.string(Decimal(string: "6.5")!), "6.5")
        XCTAssertEqual(DecimalField.string(12345), "12345")
        XCTAssertEqual(CentsField.string(0), "")
        XCTAssertEqual(CentsField.string(5408), "54.08")
        XCTAssertEqual(CentsField.string(250_150), "2501.50")
        XCTAssertEqual(percentString(Decimal(string: "25.926")!), "25.9%")
        XCTAssertEqual(percentString(35), "35.0%")
    }
}
