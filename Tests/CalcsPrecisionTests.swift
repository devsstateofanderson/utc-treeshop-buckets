import XCTest
@testable import Buckets

/// Non-tie inputs cannot be mis-rounded: with hours to 2 decimals and rates to 4, the exact rate is at least
/// 1/(2·L·H·10^4) cents from any half-cent unless it IS a half-cent, and Decimal's truncation drift is ≤ 1e-35.
/// These ten inputs are constructed (salvage 0, fuel/repair/insurance 0) so the exact value is exactly
/// 1/(2·L·H·10^4) ≈ 2.5e-12 … 1e-11 cents above (+1) or below (−1) a half-cent; the code agrees on all of them.
final class Probe_calcs_NearTies: XCTestCase {
    func testNearTiesAgreeWithExactArithmetic() throws {
        let rows: [(price: Int, life: Int, annual: Int, com: String, want: Int, side: Int)] = [
            (633_269_617, 10_000, 2001, "0.0047", 64_219, -1),
            (809_120_939, 10_000, 1499, "0.0041", 82_185, 1),
            (393_084_037, 7500, 1501, "0.0027", 52_835, -1),
            (459_644_203, 7500, 1201, "0.0033", 62_018, -1),
            (895_460_921, 6001, 1500, "0.0019", 149_927, -1),
            (911_483_137, 8000, 999, "0.0073", 117_681, -1),
            (746_931_433, 8000, 999, "0.0097", 97_445, -1),
            (772_197_799, 7500, 1001, "0.0699", 133_520, 1),
            (100_697_981, 10_000, 501, "0.0079", 10_903, -1),
            (329_260_999, 10_001, 500, "0.0501", 50_243, -1),
        ]
        for row in rows {
            let got = try EquipmentCalc.rateCents(price: row.price, salvage: 0, lifeHours: Decimal(row.life), annualHours: Decimal(row.annual),
                                                  fuelOilPerHour: 0, repairFactor: 0, insurancePerYear: 0, costOfMoney: Decimal(string: row.com)!)
            XCTAssertEqual(got, row.want, "\(row) (exact is \(row.side > 0 ? "just above" : "just below") a half-cent)")
        }
    }

    // LaborCalc: the only division is the last operation, so a tie is computed exactly and a non-tie is ≥ 5e-12¢ away.
    // The exact quotient here is 2.5e-38 below / above a half-cent and Decimal still gets it right.
    func testLaborThirtyEightDigitBoundary() throws {
        XCTAssertEqual(try LaborCalc.rateCents(wage: 1, paidHours: 1, burden: 0, billable: Decimal(string: "2.0000000000000000000000000000000000001")!), 0)
        XCTAssertEqual(try LaborCalc.rateCents(wage: 1, paidHours: 1, burden: 0, billable: Decimal(string: "1.9999999999999999999999999999999999999")!), 1)
    }

    // Decimal division truncates rather than rounds at the last kept digit (the root cause of the tie defect).
    func testDecimalDivisionTruncates() {
        XCTAssertEqual((Decimal(2) / 3).description, "0.66666666666666666666666666666666666666")
        XCTAssertLessThan(Decimal(1502) / 1500 * 1500, 1502)
        XCTAssertLessThan(Decimal(1502) / 1500 + Decimal(1001) / 3000, Decimal(string: "1.335")!)
    }
}
