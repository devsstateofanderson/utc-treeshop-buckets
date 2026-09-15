import XCTest
@testable import Buckets

/// BRIEF §5.2 round half-away-from-zero once; DECISIONS 7 "sums the five exact Decimal components and rounds once".
/// Foundation.Decimal truncates a repeating quotient at 38 digits (1/600 = 0.0016…66, not …67), so a sum whose exact
/// value is a half cent can come out as x.4999… and round the wrong way.
final class Probe_spec_EquipmentTie: XCTestCase {
    func testRealisticHalfCentTieRoundsAwayFromZero() throws {
        // Chainsaw group $1,500, salvage $500, life 2,000 h (BRIEF §2.2 saws), 300 h/yr, repair factor 0.65,
        // insurance $200/yr, fuel $3.00/hr, cost of money 7%:
        //   depreciation 0.5 · costOfMoney 1500 × 43/60 × 0.07 ÷ 300 = 0.2508333… · insurance 0.6666… · fuel 3.00 · repairs 0.4875
        //   exact total = 4.905 exactly (the two repeating parts sum to 0.9175) → 491¢ half away from zero.
        let com = Decimal(string: "0.07")!
        let rate = try EquipmentCalc.rateCents(price: 150_000, salvage: 50_000, lifeHours: 2000, annualHours: 300,
                                               fuelOilPerHour: 300, repairFactor: Decimal(string: "0.65")!,
                                               insurancePerYear: 20_000, costOfMoney: com)
        XCTAssertEqual(rate, 491)
        // Reference: the same rate over the common denominator 2·L·A with a single division is exact:
        // total = [2A(c−s) + ((L−A)(c+s) + 2cA)·r + 2L·i + 2LA·f + 2A·c·rf] ÷ (2LA)
        let (c, s, i, f) = (Decimal(1500), Decimal(500), Decimal(200), Decimal(3))
        let (l, a) = (Decimal(2000), Decimal(300))
        let numerator = 2 * a * (c - s) + ((l - a) * (c + s) + 2 * c * a) * com + 2 * l * i + 2 * l * a * f
            + 2 * a * c * Decimal(string: "0.65")!
        XCTAssertEqual(numerator, 5_886_000)
        XCTAssertEqual(Money.cents(numerator / (2 * l * a) * 100), 491)
    }

    func testExactHalfCentTieBuiltFromRepeatingComponents() throws {
        // Price $1.00, salvage 0, life 600 h, annual 600 h, insurance $1.00/yr, repair factor 1, no fuel, no cost of money:
        // depreciation = insurance = repairs = 1/600 $/hr → exact total 3/600 = $0.005 = 0.5 cent → 1 cent.
        let r = try EquipmentCalc.rate(price: 100, salvage: 0, lifeHours: 600, annualHours: 600,
                                       fuelOilPerHour: 0, repairFactor: 1, insurancePerYear: 100, costOfMoney: 0)
        XCTAssertEqual(r.rateCents, 1, "exact 0.5¢ must round to 1¢; Foundation.Decimal truncates 1/600 so the sum is 0.4999…")
    }
}
