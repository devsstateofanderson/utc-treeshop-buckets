import XCTest
@testable import Buckets

/// DECISIONS 12: Core takes a FRACTION. Passing the whole percent (30) is accepted without error:
/// 3000 × (1 + 30) × 2080 / 1500 = 128,960 cents = $1,289.60/hr — 23.8× Marcus's real rate.
final class Probe_calcs_BurdenUnits: XCTestCase {
    func testWholePercentBurdenIsSilentlyAccepted() throws {
        XCTAssertEqual(try LaborCalc.rateCents(wage: 3000, paidHours: 2080, burden: 30, billable: 1500), 128_960)
        // the correct call from a whole-percent store (LaborCalcInputs.burdenPct) is burdenPct / 100:
        XCTAssertEqual(try LaborCalc.rateCents(wage: 3000, paidHours: 2080, burden: Decimal(30) / 100, billable: 1500), 5408)
        // same for equipment: costOfMoneyPct 7 vs fraction 0.07 → 6.25 + 65000×0.6875×7/1500 (= 208.54) + 1.6 + 7.28 + 6.5 = 230.17…
        XCTAssertEqual(try EquipmentCalc.rateCents(price: 6_500_000, salvage: 1_500_000, lifeHours: 8000, annualHours: 1500, fuelOilPerHour: 728,
                                                   repairFactor: Decimal(string: "0.80")!, insurancePerYear: 240_000, costOfMoney: 7), 23_017)
        XCTAssertEqual(try EquipmentCalc.rateCents(price: 6_500_000, salvage: 1_500_000, lifeHours: 8000, annualHours: 1500, fuelOilPerHour: 728,
                                                   repairFactor: Decimal(string: "0.80")!, insurancePerYear: 240_000, costOfMoney: Decimal(7) / 100), 2372)
    }
}
