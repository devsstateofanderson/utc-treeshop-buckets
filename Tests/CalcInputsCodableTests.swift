import XCTest
@testable import Buckets

/// Does `calcInputs` JSON carry Decimal exactly? Inspect the bytes, not just equality.
final class Probe_calcs_Codable: XCTestCase {
    private func json<T: Encodable>(_ v: T) throws -> String {
        let enc = JSONEncoder()
        enc.outputFormatting = [.sortedKeys]
        return String(decoding: try enc.encode(v), as: UTF8.self)
    }

    func testLaborInputsBytesAreExactDecimalDigits() throws {
        for (s, expectedText) in [("0.1", "0.1"), ("0.80", "0.8"), ("32.5", "32.5"), ("7", "7"), ("0.001", "0.001"), ("30", "30"), ("0.07", "0.07"),
                                  ("0.12345678901234567890123456789012345678", "0.12345678901234567890123456789012345678")] {
            let inputs = LaborCalcInputs(wageCents: 3000, paidHours: 2080, burdenPct: Decimal(string: s)!)
            let text = try json(inputs)
            XCTAssertEqual(text, "{\"burdenPct\":\(expectedText),\"paidHours\":2080,\"wageCents\":3000}", s)
            XCTAssertFalse(text.contains("0000000000000"), text)   // never a Double artifact
            XCTAssertFalse(text.contains("9999999999999"), text)
            let back = try JSONDecoder().decode(LaborCalcInputs.self, from: Data(text.utf8))
            XCTAssertEqual(back, inputs, s)
            XCTAssertEqual(back.burdenPct.description, expectedText, s)
        }
    }

    func testEquipmentInputsBytesAreExactDecimalDigits() throws {
        let inputs = EquipmentCalcInputs(priceCents: 6_500_000, salvageCents: 1_500_000, lifeHours: 8000, annualHours: Decimal(string: "1500.50")!,
                                         fuelOilPerHourCents: 728, repairFactor: Decimal(string: "0.80")!, insurancePerYearCents: 240_000,
                                         costOfMoneyPct: Decimal(string: "7.25")!)
        let text = try json(inputs)
        XCTAssertEqual(text, "{\"annualHours\":1500.5,\"costOfMoneyPct\":7.25,\"fuelOilPerHourCents\":728,\"insurancePerYearCents\":240000,\"lifeHours\":8000,\"priceCents\":6500000,\"repairFactor\":0.8,\"salvageCents\":1500000}")
        let back = try JSONDecoder().decode(EquipmentCalcInputs.self, from: Data(text.utf8))
        XCTAssertEqual(back, inputs)
        XCTAssertEqual(back.costOfMoneyPct / 100, Decimal(string: "0.0725")!)
    }

    // Decoding parses the number text directly: a literal a Double could not hold survives verbatim; 0.1 is exactly 0.1.
    func testDecodingDoesNotGoThroughDouble() throws {
        let long = try JSONDecoder().decode(LaborCalcInputs.self, from: Data("{\"wageCents\":3000,\"paidHours\":2080,\"burdenPct\":0.10000000000000000000000000000000000001}".utf8))
        XCTAssertEqual(long.burdenPct, Decimal(string: "0.10000000000000000000000000000000000001")!)
        XCTAssertNotEqual(long.burdenPct, Decimal(string: "0.1")!)
        let tenth = try JSONDecoder().decode(LaborCalcInputs.self, from: Data("{\"wageCents\":3000,\"paidHours\":2080,\"burdenPct\":0.1}".utf8))
        XCTAssertEqual(tenth.burdenPct, Decimal(string: "0.1")!)
        XCTAssertEqual(tenth.burdenPct * 10, 1)
        let exp = try JSONDecoder().decode(LaborCalcInputs.self, from: Data("{\"wageCents\":3000,\"paidHours\":2080,\"burdenPct\":3E1}".utf8))
        XCTAssertEqual(exp.burdenPct, 30)
        XCTAssertThrowsError(try JSONDecoder().decode(LaborCalcInputs.self, from: Data("{\"wageCents\":3000,\"paidHours\":2080,\"burdenPct\":\"30\"}".utf8)))
    }

    func testRoundTripStillPricesTheBrief() throws {
        let labor = try JSONDecoder().decode(LaborCalcInputs.self, from: JSONEncoder().encode(LaborCalcInputs(wageCents: 3000, paidHours: 2080, burdenPct: 30)))
        XCTAssertEqual(try LaborCalc.rateCents(wage: labor.wageCents, paidHours: labor.paidHours, burden: labor.burdenPct / 100, billable: 1500), 5408)
        let eq = try JSONDecoder().decode(EquipmentCalcInputs.self, from: JSONEncoder().encode(
            EquipmentCalcInputs(priceCents: 6_500_000, salvageCents: 1_500_000, lifeHours: 8000, annualHours: 1500, fuelOilPerHourCents: 728,
                                repairFactor: Decimal(string: "0.80")!, insurancePerYearCents: 240_000, costOfMoneyPct: 7)))
        XCTAssertEqual(try EquipmentCalc.rateCents(price: eq.priceCents, salvage: eq.salvageCents, lifeHours: eq.lifeHours, annualHours: eq.annualHours,
                                                   fuelOilPerHour: eq.fuelOilPerHourCents, repairFactor: eq.repairFactor,
                                                   insurancePerYear: eq.insurancePerYearCents, costOfMoney: eq.costOfMoneyPct / 100), 2372)
    }

    func testTrailingZeroIsNormalisedNotPreserved() throws {
        let text = try json(LaborCalcInputs(wageCents: 1, paidHours: 1, burdenPct: Decimal(string: "0.80")!))
        XCTAssertTrue(text.contains("\"burdenPct\":0.8,"), text)
    }
}
