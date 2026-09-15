import XCTest
@testable import Buckets

final class LaborCalcTests: XCTestCase {
    private let burden = Decimal(string: "0.30")!

    func testMarcusIs5408() throws {
        XCTAssertEqual(try LaborCalc.rateCents(wage: 3000, paidHours: 2080, burden: burden, billable: 1500), 5408)
    }

    func testDavidAndMiguelRoundHalfAwayFromZero() throws {
        XCTAssertEqual(try LaborCalc.rateCents(wage: 2200, paidHours: 2080, burden: burden, billable: 1500), 3966) // 39.6587
        XCTAssertEqual(try LaborCalc.rateCents(wage: 1700, paidHours: 2080, burden: burden, billable: 1500), 3065) // 30.6453
    }

    func testStoredRatesSumToTheBriefsLaborTotal() throws {
        let rates = try [3000, 2200, 1700].map { try LaborCalc.rateCents(wage: $0, paidHours: 2080, burden: burden, billable: 1500) }
        XCTAssertEqual(rates.reduce(0, +), 12_439)   // Σ rounded = 124.39 (exact Σ would be 124.384)
    }

    func testZeroBurdenAndZeroPaidHours() throws {
        XCTAssertEqual(try LaborCalc.rateCents(wage: 3000, paidHours: 1500, burden: 0, billable: 1500), 3000)
        XCTAssertEqual(try LaborCalc.rateCents(wage: 3000, paidHours: 0, burden: burden, billable: 1500), 0)
        XCTAssertEqual(try LaborCalc.rateCents(wage: 0, paidHours: 2080, burden: burden, billable: 1500), 0)
    }

    func testExactHalfCentTie() throws {
        // 1000 × 1.0 × 1 ÷ 2000 = 0.5 cent → 1 (half away from zero)
        XCTAssertEqual(try LaborCalc.rateCents(wage: 1, paidHours: 1, burden: 0, billable: 2), 1)
        // 3 × 1 ÷ 2 = 1.5 → 2, not banker's 2 by luck: 5 ÷ 2 = 2.5 → 3 (banker's would give 2)
        XCTAssertEqual(try LaborCalc.rateCents(wage: 5, paidHours: 1, burden: 0, billable: 2), 3)
    }

    func testErrors() {
        XCTAssertThrowsError(try LaborCalc.rateCents(wage: 3000, paidHours: 2080, burden: burden, billable: 0)) {
            XCTAssertEqual($0 as? LaborCalcError, .nonPositiveBillableHours)
        }
        XCTAssertThrowsError(try LaborCalc.rateCents(wage: 3000, paidHours: 2080, burden: burden, billable: -1))
        XCTAssertThrowsError(try LaborCalc.rateCents(wage: -1, paidHours: 2080, burden: burden, billable: 1500)) {
            XCTAssertEqual($0 as? LaborCalcError, .negativeWage)
        }
        XCTAssertThrowsError(try LaborCalc.rateCents(wage: 3000, paidHours: -1, burden: burden, billable: 1500)) {
            XCTAssertEqual($0 as? LaborCalcError, .negativePaidHours)
        }
        XCTAssertThrowsError(try LaborCalc.rateCents(wage: 3000, paidHours: 2080, burden: -Decimal(string: "0.1")!, billable: 1500)) {
            XCTAssertEqual($0 as? LaborCalcError, .negativeBurden)
        }
    }
}
