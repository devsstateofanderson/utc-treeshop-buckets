import XCTest
@testable import Buckets

/// LaborCalc conformance probes. Expected values are exact rational arithmetic (python3 fractions), never the code's output.
final class Probe_calcs_Labor: XCTestCase {
    private let b30 = Decimal(string: "0.30")!

    // BRIEF §2.1 / PROMPT Layer 7: 3000 × 1.30 × 2080 ÷ 1500 = 5408 exactly.
    func testLayer7Vector5408() throws {
        XCTAssertEqual(try LaborCalc.rateCents(wage: 3000, paidHours: 2080, burden: b30, billable: 1500), 5408)
    }

    // David 59488/15 = 3965.8666… → 3966 ; Miguel 45968/15 = 3064.5333… → 3065 (0.0333¢ above the tie).
    // Both also round up under banker's rounding, so on their own they do not prove the mode (see the ties below).
    func testDavidAndMiguel() throws {
        XCTAssertEqual(try LaborCalc.rateCents(wage: 2200, paidHours: 2080, burden: b30, billable: 1500), 3966)
        XCTAssertEqual(try LaborCalc.rateCents(wage: 1700, paidHours: 2080, burden: b30, billable: 1500), 3065)
        XCTAssertEqual(try [3000, 2200, 1700].map { try LaborCalc.rateCents(wage: $0, paidHours: 2080, burden: b30, billable: 1500) }.reduce(0, +), 12_439)
    }

    func testBillableZeroAndNegativeThrowTyped() {
        for billable: Decimal in [0, -1, -1500, Decimal(string: "-0.01")!] {
            XCTAssertThrowsError(try LaborCalc.rateCents(wage: 3000, paidHours: 2080, burden: b30, billable: billable), "\(billable)") {
                XCTAssertEqual($0 as? LaborCalcError, .nonPositiveBillableHours)
            }
        }
    }

    func testZeroPaidHoursAndZeroWageGiveZero() throws {
        XCTAssertEqual(try LaborCalc.rateCents(wage: 3000, paidHours: 0, burden: b30, billable: 1500), 0)
        XCTAssertEqual(try LaborCalc.rateCents(wage: 0, paidHours: 2080, burden: b30, billable: 1500), 0)
        XCTAssertEqual(try LaborCalc.rateCents(wage: 0, paidHours: 0, burden: 0, billable: 1), 0)
    }

    // Exact half-cent ties with realistic inputs; half-away-from-zero rounds UP, banker's would round to even.
    func testRealisticHalfCentTiesRoundHalfAwayFromZero() throws {
        XCTAssertEqual(try LaborCalc.rateCents(wage: 2500, paidHours: 2079, burden: b30, billable: 1500), 4505)                         // 4504.5 (banker's 4504)
        XCTAssertEqual(try LaborCalc.rateCents(wage: 3000, paidHours: 2081, burden: Decimal(string: "0.25")!, billable: 1500), 5203)  // 5202.5 (banker's 5202)
        XCTAssertEqual(try LaborCalc.rateCents(wage: 3000, paidHours: 2079, burden: Decimal(string: "0.25")!, billable: 1500), 5198)  // 5197.5 (control)
        XCTAssertEqual(try LaborCalc.rateCents(wage: 1500, paidHours: 2080, burden: Decimal(string: "0.25")!, billable: 1600), 2438)  // 2437.5 (control)
        XCTAssertEqual(try LaborCalc.rateCents(wage: 1500, paidHours: 2080, burden: Decimal(string: "0.35")!, billable: 1600), 2633)  // 2632.5 (banker's 2632)
        XCTAssertEqual(try LaborCalc.rateCents(wage: 1500, paidHours: 2000, burden: Decimal(string: "0.325")!, billable: 2000), 1988) // 1987.5 (control)
        XCTAssertEqual(try LaborCalc.rateCents(wage: 1500, paidHours: 1950, burden: b30, billable: 1800), 2113)                         // 2112.5 (banker's 2112)
    }

    func testFractionalInputs() throws {
        XCTAssertEqual(try LaborCalc.rateCents(wage: 3000, paidHours: 2080, burden: Decimal(string: "0.325")!, billable: 1500), 5512)          // exact
        XCTAssertEqual(try LaborCalc.rateCents(wage: 3000, paidHours: Decimal(string: "2080.5")!, burden: b30, billable: 1500), 5409)        // 5409.3
        XCTAssertEqual(try LaborCalc.rateCents(wage: 3000, paidHours: 2080, burden: b30, billable: 1), 8_112_000)
        XCTAssertEqual(try LaborCalc.rateCents(wage: 3000, paidHours: 2080, burden: b30, billable: Decimal(string: "0.5")!), 16_224_000)
    }

    // NaN never passes a guard (Decimal orders NaN below every number) — the error names are the 'negative' ones.
    func testNaNInputsThrowTypedErrors() {
        XCTAssertThrowsError(try LaborCalc.rateCents(wage: 3000, paidHours: .nan, burden: b30, billable: 1500)) { XCTAssertEqual($0 as? LaborCalcError, .negativePaidHours) }
        XCTAssertThrowsError(try LaborCalc.rateCents(wage: 3000, paidHours: 2080, burden: .nan, billable: 1500)) { XCTAssertEqual($0 as? LaborCalcError, .negativeBurden) }
        XCTAssertThrowsError(try LaborCalc.rateCents(wage: 3000, paidHours: 2080, burden: b30, billable: .nan)) { XCTAssertEqual($0 as? LaborCalcError, .nonPositiveBillableHours) }
    }

    // Guard order: wage, then paid hours, burden, billable.
    func testGuardOrder() {
        XCTAssertThrowsError(try LaborCalc.rateCents(wage: -1, paidHours: -1, burden: -1, billable: 0)) { XCTAssertEqual($0 as? LaborCalcError, .negativeWage) }
        XCTAssertThrowsError(try LaborCalc.rateCents(wage: 0, paidHours: -1, burden: -1, billable: 0)) { XCTAssertEqual($0 as? LaborCalcError, .negativePaidHours) }
        XCTAssertThrowsError(try LaborCalc.rateCents(wage: 0, paidHours: 0, burden: -1, billable: 0)) { XCTAssertEqual($0 as? LaborCalcError, .negativeBurden) }
        XCTAssertThrowsError(try LaborCalc.rateCents(wage: 0, paidHours: 0, burden: 0, billable: 0)) { XCTAssertEqual($0 as? LaborCalcError, .nonPositiveBillableHours) }
    }
}
