import XCTest
@testable import Buckets

/// EquipmentRate components that are exact terminating decimals are reproduced bit-for-bit because each is one
/// division over its own denominator (DECISIONS 7), so the sheet's per-component display has no tie hazard.
final class Probe_calcs_ComponentDrift: XCTestCase {
    func testComponentsAreExactForTerminatingValues() throws {
        // brief truck, salvage $13,000: N = 16/3 (truncated), AVF = 27/40 exactly, com = 65000 × 0.675 × 0.07 / 1500 = 2.0475 exactly
        let r = try EquipmentCalc.rate(price: 6_500_000, salvage: 1_300_000, lifeHours: 8000, annualHours: 1500, fuelOilPerHour: 728,
                                       repairFactor: Decimal(string: "0.80")!, insurancePerYear: 240_000, costOfMoney: Decimal(string: "0.07")!)
        XCTAssertEqual(r.costOfMoney, Decimal(string: "2.0475")!, "got \(r.costOfMoney)")
        // annual 0.5 h: N = 16000, AVF = 25601/41600 (non-terminating), com exact 5600.21875, total exact 10420.24875
        let tiny = try EquipmentCalc.rate(price: 6_500_000, salvage: 1_500_000, lifeHours: 8000, annualHours: Decimal(string: "0.5")!, fuelOilPerHour: 728,
                                          repairFactor: Decimal(string: "0.80")!, insurancePerYear: 240_000, costOfMoney: Decimal(string: "0.07")!)
        XCTAssertEqual(tiny.costOfMoney, Decimal(string: "5600.21875")!, "got \(tiny.costOfMoney)")
        XCTAssertEqual(tiny.total, Decimal(string: "10420.24875")!, "got \(tiny.total)")
        XCTAssertEqual(tiny.rateCents, 1_042_025)
    }
}
