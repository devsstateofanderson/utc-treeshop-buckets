import XCTest
@testable import Buckets

final class EquipmentCalcTests: XCTestCase {
    private let repair = Decimal(string: "0.80")!
    private let sevenPct = Decimal(string: "0.07")!

    private func bucketTruck(annualHours: Decimal = 1500, costOfMoney: Decimal? = nil) throws -> EquipmentRate {
        try EquipmentCalc.rate(price: 6_500_000, salvage: 1_500_000, lifeHours: 8000, annualHours: annualHours,
                               fuelOilPerHour: 728, repairFactor: repair, insurancePerYear: 240_000,
                               costOfMoney: costOfMoney ?? sevenPct)
    }

    func testBucketTruckIs2372() throws {
        XCTAssertEqual(try EquipmentCalc.rateCents(price: 6_500_000, salvage: 1_500_000, lifeHours: 8000, annualHours: 1500,
                                                   fuelOilPerHour: 728, repairFactor: repair, insurancePerYear: 240_000,
                                                   costOfMoney: sevenPct), 2372)
    }

    func testBucketTruckComponents() throws {
        let r = try bucketTruck()
        XCTAssertEqual(r.depreciation, Decimal(string: "6.25")!)
        XCTAssertEqual(Money.cents(r.costOfMoney * 100), 209)      // exact 2.0854166…
        XCTAssertEqual(r.insurance, Decimal(string: "1.60")!)
        XCTAssertEqual(r.fuelOil, Decimal(string: "7.28")!)
        XCTAssertEqual(r.repairs, Decimal(string: "6.50")!)
        XCTAssertEqual(Money.cents(r.total * 100), 2372)           // exact 23.7154166…
        XCTAssertEqual(r.rateCents, 2372)
    }

    func testAVFIsElevenSixteenthsForTheBucketTruck() throws {
        // CostOfMoney = 65000 × AVF × 0.07 ÷ 1500 with AVF = 11/16 → 2.0854166…
        let r = try bucketTruck()
        let avf = r.costOfMoney * 1500 / (65_000 * sevenPct)
        XCTAssertEqual(Money.cents(avf * 10_000), 6875)
    }

    func testCostOfMoneyZeroIsTheAppDefault() throws {
        XCTAssertEqual(try bucketTruck(costOfMoney: 0).rateCents, 2163)
    }

    func testNEqualsOneUsesAVFOne() throws {
        // annual 8000 = life 8000 → N = 1 → AVF = 1: 6.25 + 0.56875 + 0.30 + 7.28 + 6.50 = 20.89875
        XCTAssertEqual(try bucketTruck(annualHours: 8000).rateCents, 2090)
    }

    func testNBelowOneUsesAVFOneAndRoundsHalfAwayFromZero() throws {
        // annual 10000 > life → N = 0.8 → AVF = 1: 6.25 + 0.455 + 0.24 + 7.28 + 6.50 = 20.725 exactly
        XCTAssertEqual(try bucketTruck(annualHours: 10_000).rateCents, 2073)   // banker's rounding would give 2072
    }

    func testSumIsRoundedOnceNotPerComponent() throws {
        // depreciation 6.255 and repairs 6.255: per-component rounding gives 6.26 + 6.26 = 12.52; the exact sum is 12.51
        let r = try EquipmentCalc.rate(price: 1_251_000, salvage: 625_500, lifeHours: 1000, annualHours: 1000,
                                       fuelOilPerHour: 0, repairFactor: Decimal(string: "0.5")!, insurancePerYear: 0,
                                       costOfMoney: 0)
        XCTAssertEqual(r.depreciation, Decimal(string: "6.255")!)
        XCTAssertEqual(r.repairs, Decimal(string: "6.255")!)
        XCTAssertEqual(r.rateCents, 1251)
    }

    func testLowAnnualHoursRecoverMoreCostOfMoneyAndInsurance() throws {
        // A unit that runs 500 hrs/yr recovers insurance at 2400/500 = $4.80/hr instead of $1.60
        let r = try bucketTruck(annualHours: 500)
        XCTAssertEqual(r.insurance, Decimal(string: "4.80")!)
        XCTAssertGreaterThan(r.rateCents, 2372)
    }

    func testErrors() {
        func rate(price: Int = 6_500_000, salvage: Int = 1_500_000, life: Decimal = 8000, annual: Decimal = 1500,
                  fuel: Int = 728, repair: Decimal = Decimal(string: "0.80")!, insurance: Int = 240_000,
                  com: Decimal = Decimal(string: "0.07")!) throws -> Int {
            try EquipmentCalc.rateCents(price: price, salvage: salvage, lifeHours: life, annualHours: annual,
                                        fuelOilPerHour: fuel, repairFactor: repair, insurancePerYear: insurance, costOfMoney: com)
        }
        XCTAssertThrowsError(try rate(salvage: 6_500_000)) { XCTAssertEqual($0 as? EquipmentCalcError, .salvageNotBelowPrice) }
        XCTAssertThrowsError(try rate(salvage: 6_500_001)) { XCTAssertEqual($0 as? EquipmentCalcError, .salvageNotBelowPrice) }
        XCTAssertThrowsError(try rate(salvage: -1)) { XCTAssertEqual($0 as? EquipmentCalcError, .negativeSalvage) }
        XCTAssertThrowsError(try rate(price: 0, salvage: 0)) { XCTAssertEqual($0 as? EquipmentCalcError, .nonPositivePrice) }
        XCTAssertThrowsError(try rate(life: 0)) { XCTAssertEqual($0 as? EquipmentCalcError, .nonPositiveLifeHours) }
        XCTAssertThrowsError(try rate(life: -8000)) { XCTAssertEqual($0 as? EquipmentCalcError, .nonPositiveLifeHours) }
        XCTAssertThrowsError(try rate(annual: 0)) { XCTAssertEqual($0 as? EquipmentCalcError, .nonPositiveAnnualHours) }
        XCTAssertThrowsError(try rate(fuel: -1)) { XCTAssertEqual($0 as? EquipmentCalcError, .negativeFuelOil) }
        XCTAssertThrowsError(try rate(repair: -1)) { XCTAssertEqual($0 as? EquipmentCalcError, .negativeRepairFactor) }
        XCTAssertThrowsError(try rate(insurance: -1)) { XCTAssertEqual($0 as? EquipmentCalcError, .negativeInsurance) }
        XCTAssertThrowsError(try rate(com: -1)) { XCTAssertEqual($0 as? EquipmentCalcError, .negativeCostOfMoney) }
        XCTAssertNoThrow(try rate(salvage: 0))
        XCTAssertNoThrow(try rate(fuel: 0, repair: 0, insurance: 0, com: 0))
    }
}
