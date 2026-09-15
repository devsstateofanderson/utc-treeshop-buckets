import XCTest
@testable import Buckets

/// BRIEF §2.2 five components, the N ≤ 1 guard, DECISIONS 7/8. Expectations are exact rationals from python3 fractions.
final class Probe_spec_EquipmentGuards: XCTestCase {
    private let rf = Decimal(string: "0.80")!
    private let com = Decimal(string: "0.07")!

    private func truck(annual: Decimal = 1500, life: Decimal = 8000) throws -> EquipmentRate {
        try EquipmentCalc.rate(price: 6_500_000, salvage: 1_500_000, lifeHours: life, annualHours: annual,
                               fuelOilPerHour: 728, repairFactor: rf, insurancePerYear: 240_000, costOfMoney: com)
    }

    func testFiveComponentsMatchTheBriefToTheCent() throws {
        let r = try truck()
        XCTAssertEqual(r.depreciation, Decimal(string: "6.25")!)                 // (65000 − 15000) ÷ 8000
        XCTAssertEqual(Money.cents(r.costOfMoney * 100), 209)                     // 65000 × 11/16 × 0.07 ÷ 1500 = 2.0854166…
        XCTAssertEqual(r.insurance, Decimal(string: "1.6")!)                      // 2400 ÷ 1500
        XCTAssertEqual(r.fuelOil, Decimal(string: "7.28")!)
        XCTAssertEqual(r.repairs, Decimal(string: "6.5")!)                        // 65000 × 0.80 ÷ 8000
        XCTAssertEqual(r.rateCents, 2372)                                         // 23.7154166… rounded once
        XCTAssertEqual(r.rateCents, Money.cents(r.total * 100))
    }

    func testAVFIsExactlyOneAtNEqualOneAndBelow() throws {
        // N = 1 (annual 8000): CostOfMoney = 65000 × 1 × 0.07 ÷ 8000 = 0.56875 exactly
        XCTAssertEqual(try truck(annual: 8000).costOfMoney, Decimal(string: "0.56875")!)
        // N = 0.8 (annual 10000): 65000 × 1 × 0.07 ÷ 10000 = 0.455 exactly (formula AVF 1.096… would give 0.49875)
        XCTAssertEqual(try truck(annual: 10_000).costOfMoney, Decimal(string: "0.455")!)
        XCTAssertNotEqual(try truck(annual: 10_000).costOfMoney, Decimal(string: "0.49875")!)
    }

    func testAVFUsesTheFormulaJustAboveOne() throws {
        // N = 8000/7999: AVF = ((N−1)(1 + 3/13) + 2) ÷ 2N = 20799/20800 = 0.99995192…
        let r = try truck(annual: 7999)
        let avf = r.costOfMoney * 7999 / (65_000 * com)
        XCTAssertEqual(Money.cents(avf * 1_000_000), 999_952)
        XCTAssertLessThan(avf, 1)
    }

    func testNegativeAnnualHoursThrows() {
        // DECISIONS 8 says annual hours ≤ 0; the suite only exercises 0.
        XCTAssertThrowsError(try truck(annual: -1)) { XCTAssertEqual($0 as? EquipmentCalcError, .nonPositiveAnnualHours) }
        XCTAssertThrowsError(try truck(life: -1)) { XCTAssertEqual($0 as? EquipmentCalcError, .nonPositiveLifeHours) }
    }
}
