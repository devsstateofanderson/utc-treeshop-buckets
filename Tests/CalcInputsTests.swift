import XCTest
@testable import Buckets

/// `calcInputs` is JSON in `BucketItem`; the Decimal fields must survive the round trip exactly.
final class CalcInputsTests: XCTestCase {
    func testLaborInputsRoundTrip() throws {
        let inputs = LaborCalcInputs(wageCents: 3000, paidHours: 2080, burdenPct: Decimal(string: "32.5")!)
        let data = try JSONEncoder().encode(inputs)
        let back = try JSONDecoder().decode(LaborCalcInputs.self, from: data)
        XCTAssertEqual(back, inputs)
        XCTAssertEqual(back.burdenPct, Decimal(string: "32.5")!)
    }

    func testEquipmentInputsRoundTrip() throws {
        let inputs = EquipmentCalcInputs(priceCents: 6_500_000, salvageCents: 1_500_000, lifeHours: 8000, annualHours: 1500,
                                         fuelOilPerHourCents: 728, repairFactor: Decimal(string: "0.80")!,
                                         insurancePerYearCents: 240_000, costOfMoneyPct: Decimal(string: "7")!)
        let data = try JSONEncoder().encode(inputs)
        let back = try JSONDecoder().decode(EquipmentCalcInputs.self, from: data)
        XCTAssertEqual(back, inputs)
        XCTAssertEqual(back.repairFactor, Decimal(string: "0.80")!)
        // The decoded factor must still produce the brief's rate.
        XCTAssertEqual(try EquipmentCalc.rateCents(price: back.priceCents, salvage: back.salvageCents, lifeHours: back.lifeHours,
                                                   annualHours: back.annualHours, fuelOilPerHour: back.fuelOilPerHourCents,
                                                   repairFactor: back.repairFactor, insurancePerYear: back.insurancePerYearCents,
                                                   costOfMoney: back.costOfMoneyPct / 100), 2372)
    }

    func testDecimalFromStringIsExactWhereDoubleIsNot() {
        XCTAssertEqual(Decimal(string: "0.07")! * 100, 7)
        XCTAssertEqual(Decimal(string: "0.35")! + 1, Decimal(string: "1.35")!)
        XCTAssertNotEqual(Decimal(0.07), Decimal(string: "0.07")!)   // the trap DECISIONS 11 forbids
    }
}
