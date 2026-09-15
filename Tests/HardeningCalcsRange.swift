import XCTest
@testable import Buckets

/// Results outside Int range saturate at Int.max / Int.min and a non-finite Decimal becomes 0 (DECISIONS 49);
/// an absurd input can never yield a plausible-looking or negative $/hr.
final class Probe_calcs_Overflow: XCTestCase {
    func testLaborIntMaxWageSaturates() throws {
        // exact: Int.max × 1.3 × 2080 / 1500 = 16,626,665,325,103,542,521.42¢ ; observed = that − 2^64
        let r = try LaborCalc.rateCents(wage: Int.max, paidHours: 2080, burden: Decimal(string: "0.30")!, billable: 1500)
        XCTAssertEqual(r, Int.max)
        XCTAssertGreaterThanOrEqual(r, 0, "a labor rate came back negative with no error")
        // the edge at the brief's defaults: rate = wage × 1.80266…; wage 5.1165e18 still fits, 5.1175e18 saturates
        XCTAssertLessThan(try LaborCalc.rateCents(wage: 5_116_500_000_000_000_000, paidHours: 2080, burden: Decimal(string: "0.30")!, billable: 1500), Int.max)
        XCTAssertEqual(try LaborCalc.rateCents(wage: 5_117_500_000_000_000_000, paidHours: 2080, burden: Decimal(string: "0.30")!, billable: 1500), Int.max)
    }

    func testEquipmentIntMaxPriceSaturates() throws {
        // price Int.max¢, salvage 0, life 1 h, repair 0.80: exact 1.8 × price = 16,602,069,666,338,596,452.6¢
        let r = try EquipmentCalc.rateCents(price: Int.max, salvage: 0, lifeHours: 1, annualHours: 1500, fuelOilPerHour: 0,
                                            repairFactor: Decimal(string: "0.80")!, insurancePerYear: 0, costOfMoney: 0)
        XCTAssertEqual(r, Int.max)
        XCTAssertGreaterThanOrEqual(r, 0, "an equipment rate came back negative with no error")
    }

    func testMoneyCentsOutOfRange() {
        XCTAssertEqual(Money.cents(Decimal(string: "1e19")!), Int.max)
        XCTAssertEqual(Money.cents(Decimal(string: "9223372036854775807")!), Int.max)
        XCTAssertEqual(Money.cents(Decimal(string: "9223372036854775808")!), Int.max)
        XCTAssertEqual(Money.cents(Decimal(string: "-9223372036854775809")!), Int.min)
        XCTAssertEqual(Money.cents(Decimal.nan), 0)
        XCTAssertEqual(Money.cents(Decimal.greatestFiniteMagnitude), Int.max)
    }

    func testDecimalOverflowInsideLaborProductIsNeutralised() throws {
        // 2 × (1+1) × 3.4e38 overflows Decimal → NaN → 0 cents ; 1 × 3.4e38 saturates
        XCTAssertEqual(try LaborCalc.rateCents(wage: 2, paidHours: Decimal.greatestFiniteMagnitude, burden: 1, billable: 1), 0)
        XCTAssertEqual(try LaborCalc.rateCents(wage: 1, paidHours: Decimal.greatestFiniteMagnitude, burden: 0, billable: 1), Int.max)
    }
}
