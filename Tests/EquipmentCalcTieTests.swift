import XCTest
@testable import Buckets

/// EquipmentCalc rounds exact half-cent ties DOWN whenever a component or the AVF chain is a non-terminating
/// decimal: NSDecimal truncates quotients at 38-39 significant digits, so 1012/1500 becomes 0.67466…66 (low),
/// the exact sum x.xx5 becomes x.xx4999…, and Money.cents rounds it to the wrong cent.
/// Expected values are exact rational arithmetic (fractions in comments), rounded half away from zero once.
final class Probe_calcs_TieTruncation: XCTestCase {
    private let r80 = Decimal(string: "0.80")!
    private let c07 = Decimal(string: "0.07")!

    /// What the fix must produce: absorb the <=1e-35 drift, then round once to cents.
    private func centsPreRounded(_ total: Decimal) -> Int {
        var scaled = total * 100
        var cleaned = Decimal()
        NSDecimalRound(&cleaned, &scaled, 30, .plain)
        return Money.cents(cleaned)
    }

    // BRIEF §2.2 truck ($65,000, 8,000 h, 1,500 h/yr, $7.28 fuel, 0.80 repair, 7%) with salvage $2,600 and
    // insurance $1,012/yr. dep 7.8 ; AVF (13*1.04+6)/32 = 0.61 ; com 65000*0.61*0.07/1500 = 5551/3000 = 1.850333…
    // ins 1012/1500 = 0.674666… ; fuel 7.28 ; rep 6.5 → exact total 4821/200 = 24.105 → 2410.5¢ → 2411.
    func testBriefTruckWholeDollarInsurance() throws {
        let r = try EquipmentCalc.rate(price: 6_500_000, salvage: 260_000, lifeHours: 8000, annualHours: 1500, fuelOilPerHour: 728,
                                       repairFactor: r80, insurancePerYear: 101_200, costOfMoney: c07)
        XCTAssertEqual(r.rateCents, 2411, "exact 24.105; code total \(r.total)")
        XCTAssertEqual(centsPreRounded(r.total), 2411)
    }

    // Same truck, salvage $13,000, insurance $2,396.25/yr: every component terminates (6.5, 2.0475, 1.5975, 7.28, 6.5;
    // total 23.925) but N = 16/3 is truncated inside the AVF chain and com comes out 2.04749999…95.
    func testBriefTruckAVFChain() throws {
        let r = try EquipmentCalc.rate(price: 6_500_000, salvage: 1_300_000, lifeHours: 8000, annualHours: 1500, fuelOilPerHour: 728,
                                       repairFactor: r80, insurancePerYear: 239_625, costOfMoney: c07)
        XCTAssertEqual(r.costOfMoney, Decimal(string: "2.0475")!, "com is exactly 819/400")
        XCTAssertEqual(r.rateCents, 2393, "exact 23.925; code total \(r.total)")
        XCTAssertEqual(centsPreRounded(r.total), 2393)
    }

    // $10,400 truck, $2,400 salvage, insurance $1,502/yr, 7%: 1 + 1001/3000 + 751/750 + 7.28 + 1.04 = 2131/200 = 10.655 → 1066
    func testTenThousandFourHundredTruck() throws {
        let r = try EquipmentCalc.rate(price: 1_040_000, salvage: 240_000, lifeHours: 8000, annualHours: 1500, fuelOilPerHour: 728,
                                       repairFactor: r80, insurancePerYear: 150_200, costOfMoney: c07)
        XCTAssertEqual(r.rateCents, 1066, "exact 10.655; code total \(r.total)")
        XCTAssertEqual(centsPreRounded(r.total), 1066)
    }

    // $26,000 truck, $6,500 salvage, insurance $605/yr, 8%: 2.4375 + 1157/1200 + 121/300 + 7.28 + 2.6 = 2737/200 = 13.685 → 1369
    func testTwentySixThousandTruck() throws {
        let r = try EquipmentCalc.rate(price: 2_600_000, salvage: 650_000, lifeHours: 8000, annualHours: 1500, fuelOilPerHour: 728,
                                       repairFactor: r80, insurancePerYear: 60_500, costOfMoney: Decimal(string: "0.08")!)
        XCTAssertEqual(r.rateCents, 1369, "exact 13.685; code total \(r.total)")
        XCTAssertEqual(centsPreRounded(r.total), 1369)
    }

    // Minimal: dep 5/1500 = 1/300 and ins 2.50/1500 = 1/600 sum to exactly 0.005 → 0.5¢ → 1
    func testMinimal() throws {
        let r = try EquipmentCalc.rate(price: 1000, salvage: 500, lifeHours: 1500, annualHours: 1500, fuelOilPerHour: 0,
                                       repairFactor: 0, insurancePerYear: 250, costOfMoney: 0)
        XCTAssertEqual(r.rateCents, 1, "exact 0.005; code total \(r.total)")
        XCTAssertEqual(centsPreRounded(r.total), 1)
    }

    // Control: the existing test's tie (annual 10,000 → 20.725) survives only because every component terminates.
    func testControlTerminatingTieSurvives() throws {
        let r = try EquipmentCalc.rate(price: 6_500_000, salvage: 1_500_000, lifeHours: 8000, annualHours: 10_000, fuelOilPerHour: 728,
                                       repairFactor: r80, insurancePerYear: 240_000, costOfMoney: c07)
        XCTAssertEqual(r.total, Decimal(string: "20.725")!)
        XCTAssertEqual(r.rateCents, 2073)
    }

    // Sweep: the brief's truck with salvage $2,600 and insurance $1,012 + $15·k, k = 0…19 — every one is an exact tie
    // (24.105, 24.115, …) and every one comes back one cent low.
    func testWholeDollarInsuranceSweep() throws {
        var low = 0
        for k in 0..<20 {
            let r = try EquipmentCalc.rate(price: 6_500_000, salvage: 260_000, lifeHours: 8000, annualHours: 1500, fuelOilPerHour: 728,
                                           repairFactor: r80, insurancePerYear: 101_200 + 1500 * k, costOfMoney: c07)
            if r.rateCents != 2411 + k { low += 1 }
            XCTAssertEqual(centsPreRounded(r.total), 2411 + k)
        }
        XCTAssertEqual(low, 0, "\(low) of 20 exact ties rounded down")
    }
}
