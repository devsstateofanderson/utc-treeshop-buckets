import XCTest
@testable import Buckets

final class MoneyTests: XCTestCase {
    func testRoundsHalfAwayFromZero() {
        XCTAssertEqual(Money.cents(Decimal(string: "2.5")!), 3)
        XCTAssertEqual(Money.cents(Decimal(string: "3.5")!), 4)
        XCTAssertEqual(Money.cents(Decimal(string: "-2.5")!), -3)
        XCTAssertEqual(Money.cents(Decimal(string: "250149.6")!), 250150)
        XCTAssertEqual(Money.cents(Decimal(string: "250149.4999")!), 250149)
        XCTAssertEqual(Money.cents(0), 0)
    }

    func testDecimalFromCentsIsExact() {
        XCTAssertEqual(Money.decimal(cents: 5408), Decimal(string: "54.08")!)
        XCTAssertEqual(Money.decimal(cents: 1), Decimal(string: "0.01")!)
    }

    func testFormat() {
        XCTAssertEqual(Money.format(250150), "$2,501.50")
        XCTAssertEqual(Money.format(5), "$0.05")
        XCTAssertEqual(Money.format(0), "$0.00")
        XCTAssertEqual(Money.format(-64854), "-$648.54")
        XCTAssertEqual(Money.format(100000000), "$1,000,000.00")
    }
}
