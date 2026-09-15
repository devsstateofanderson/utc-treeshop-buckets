import XCTest
@testable import Buckets

/// EquipmentCalc conformance probes. Every expected value is exact rational arithmetic (fractions in comments).
final class Probe_calcs_Equipment: XCTestCase {
    private let r80 = Decimal(string: "0.80")!
    private let c07 = Decimal(string: "0.07")!

    private func truck(price: Int = 6_500_000, salvage: Int = 1_500_000, life: Decimal = 8000, annual: Decimal = 1500,
                       fuel: Int = 728, repair: Decimal? = nil, ins: Int = 240_000, com: Decimal? = nil) throws -> EquipmentRate {
        try EquipmentCalc.rate(price: price, salvage: salvage, lifeHours: life, annualHours: annual, fuelOilPerHour: fuel,
                               repairFactor: repair ?? r80, insurancePerYear: ins, costOfMoney: com ?? c07)
    }

    /// |a − b| ≤ tol
    private func assertClose(_ a: Decimal, _ b: String, tol: Decimal = Decimal(string: "1e-20")!, _ msg: String = "",
                             file: StaticString = #filePath, line: UInt = #line) {
        let e = Decimal(string: b)!
        let d = a > e ? a - e : e - a
        XCTAssertLessThanOrEqual(d, tol, "\(msg) got \(a) expected \(b) (|Δ| = \(d))", file: file, line: line)
    }

    // Layer 7 vector: 25/4, 1001/480, 8/5, 182/25, 13/2; total 56917/2400 = 23.7154166…
    func testLayer7VectorComponentsExact() throws {
        let r = try truck()
        XCTAssertEqual(r.depreciation, Decimal(string: "6.25")!)
        assertClose(r.costOfMoney, "2.0854166666666666666666666666666666666667", "costOfMoney")
        XCTAssertEqual(r.insurance, Decimal(string: "1.6")!)
        XCTAssertEqual(r.fuelOil, Decimal(string: "7.28")!)
        XCTAssertEqual(r.repairs, Decimal(string: "6.5")!)
        assertClose(r.total, "23.715416666666666666666666666666666666667", "total")
        XCTAssertEqual(r.rateCents, 2372)
        XCTAssertEqual(try EquipmentCalc.rateCents(price: 6_500_000, salvage: 1_500_000, lifeHours: 8000, annualHours: 1500, fuelOilPerHour: 728,
                                                   repairFactor: r80, insurancePerYear: 240_000, costOfMoney: c07), 2372)
        assertClose(r.depreciation + r.costOfMoney + r.insurance + r.fuelOil + r.repairs, "23.715416666666666666666666666666666666667", "component sum")
    }

    func testCostOfMoneyZeroIs2163Exactly() throws {
        let r = try truck(com: 0)
        XCTAssertEqual(r.costOfMoney, 0)
        XCTAssertEqual(r.total, Decimal(string: "21.63")!)
        XCTAssertEqual(r.rateCents, 2163)
    }

    // N = 1 → AVF = 1: com 0.56875, ins 0.3, total 16719/800 = 20.89875 → 2090
    func testNEqualsOne() throws {
        let r = try truck(annual: 8000)
        XCTAssertEqual(r.costOfMoney, Decimal(string: "0.56875")!)
        XCTAssertEqual(r.total, Decimal(string: "20.89875")!)
        XCTAssertEqual(r.rateCents, 2090)
    }

    // N = 0.8 → AVF = 1: total 829/40 = 20.725 exact tie → 2073
    func testNBelowOneExactTie() throws {
        let r = try truck(annual: 10_000)
        XCTAssertEqual(r.costOfMoney, Decimal(string: "0.455")!)
        XCTAssertEqual(r.total, Decimal(string: "20.725")!)
        XCTAssertEqual(r.rateCents, 2073)
    }

    // Continuity at N = 1: annual 7999 → AVF 20799/20800, com 145593/255968, total 133735801/6399200 → 2090;
    // annual 8001 → AVF 1, com 650/1143, total 16721003/800100 → 2090.
    func testAVFIsContinuousAtNEqualsOne() throws {
        let above = try truck(annual: 7999), at = try truck(annual: 8000), below = try truck(annual: 8001)
        assertClose(above.costOfMoney, "0.56879375546943367920990123765470683835", "com@7999")
        assertClose(above.total, "20.898831260157519689961245155644455569", "total@7999")
        assertClose(below.costOfMoney, "0.56867891513560804899387576552930883639", "com@8001")
        assertClose(below.total, "20.898641419822522184726909136357955256", "total@8001")
        XCTAssertEqual(above.rateCents, 2090); XCTAssertEqual(at.rateCents, 2090); XCTAssertEqual(below.rateCents, 2090)
        let avfAbove = above.costOfMoney * 7999 / (65_000 * c07)
        assertClose(avfAbove, "0.99995192307692307692307692307692307692", tol: Decimal(string: "1e-18")!, "AVF@7999")
        XCTAssertGreaterThan(above.costOfMoney, at.costOfMoney)
        XCTAssertGreaterThan(at.costOfMoney, below.costOfMoney)
        XCTAssertLessThan(1 - avfAbove, Decimal(string: "0.00005")!)
    }

    // AVF vs USACE §4.3 semantics (SLV = S/C; AVF = ((N−1)(1+SLV)+2)/(2N)) on five hand-computed inputs, r = 7%.
    func testAVFHandComputed() throws {
        struct Case { let price: Int; let salvage: Int; let life: Decimal; let annual: Decimal; let avf: String; let com: String }
        let cases = [
            Case(price: 100_000, salvage: 0,      life: 2000,   annual: 1000, avf: "0.75",   com: "0.0525"),                                    // N=2, SLV=0
            Case(price: 50_000,  salvage: 10_000, life: 6000,   annual: 1500, avf: "0.7",    com: "0.016333333333333333333333333333333333333"),  // N=4, SLV=.2
            Case(price: 20_000,  salvage: 5_000,  life: 5000,   annual: 2000, avf: "0.775",  com: "0.005425"),                                   // N=2.5, SLV=.25
            Case(price: 6_500_000, salvage: 1_500_000, life: 10_000, annual: 1000, avf: "0.65384615384615384615384615384615384615", com: "2.975"), // N=10, SLV=3/13 → 17/26
            Case(price: 80_000,  salvage: 20_000, life: 7500,   annual: 500,  avf: "0.65",   com: "0.0728"),                                     // N=15, SLV=.25
        ]
        for c in cases {
            let r = try EquipmentCalc.rate(price: c.price, salvage: c.salvage, lifeHours: c.life, annualHours: c.annual,
                                           fuelOilPerHour: 0, repairFactor: 0, insurancePerYear: 0, costOfMoney: c07)
            assertClose(r.costOfMoney, c.com, "com for \(c)")
            let avf = r.costOfMoney * c.annual / (Money.decimal(cents: c.price) * c07)
            assertClose(avf, c.avf, tol: Decimal(string: "1e-18")!, "AVF for \(c)")
        }
    }

    // annual 1500.5: total 56933199/2400800 → 2371 ; annual 0.5 h: com 5600.21875, total 10420.24875 → 1042025
    func testFractionalAnnualHours() throws {
        let r = try truck(annual: Decimal(string: "1500.5")!)
        assertClose(r.total, "23.714261496167944018660446517827390870", "total@1500.5")
        XCTAssertEqual(r.rateCents, 2371)
        let tiny = try truck(annual: Decimal(string: "0.5")!)
        assertClose(tiny.costOfMoney, "5600.21875", "com@0.5")
        assertClose(tiny.total, "10420.24875", "total@0.5")
        XCTAssertEqual(tiny.rateCents, 1_042_025)
    }

    // life 1 h: dep 50000, AVF 1, com 91/30, rep 52000; total 15301787/150 → 10201191
    func testLifeOneHour() throws {
        let r = try truck(life: 1)
        XCTAssertEqual(r.depreciation, 50_000)
        XCTAssertEqual(r.repairs, 52_000)
        assertClose(r.costOfMoney, "3.0333333333333333333333333333333333333", "com")
        XCTAssertEqual(r.rateCents, 10_201_191)
    }

    // salvage 0: dep 65/8, AVF 19/32, com 1729/960, total 121469/4800 → 2531
    func testSalvageZero() throws {
        let r = try truck(salvage: 0)
        XCTAssertEqual(r.depreciation, Decimal(string: "8.125")!)
        assertClose(r.costOfMoney, "1.8010416666666666666666666666666666667", "com")
        XCTAssertEqual(r.rateCents, 2531)
    }

    // Chainsaw repair factor 2.50: $1,000, life 2000, annual 1500, fuel 1.50 → 0.5 + 1.5 + 1.25 = 3.25 → 325;
    // $1,200, salvage $100, annual 1200, ins $50, 7%: total 23393/6000 = 3.898833… → 390
    func testChainsawRepairFactor250() throws {
        let saw = try EquipmentCalc.rate(price: 100_000, salvage: 0, lifeHours: 2000, annualHours: 1500, fuelOilPerHour: 150,
                                         repairFactor: Decimal(string: "2.50")!, insurancePerYear: 0, costOfMoney: 0)
        XCTAssertEqual(saw.repairs, Decimal(string: "1.25")!)
        XCTAssertEqual(saw.total, Decimal(string: "3.25")!)
        XCTAssertEqual(saw.rateCents, 325)
        let saw2 = try EquipmentCalc.rate(price: 120_000, salvage: 10_000, lifeHours: 2000, annualHours: 1200, fuelOilPerHour: 175,
                                          repairFactor: Decimal(string: "2.50")!, insurancePerYear: 5000, costOfMoney: c07)
        assertClose(saw2.total, "3.8988333333333333333333333333333333333", "saw2 total")
        XCTAssertEqual(saw2.rateCents, 390)
    }

    func testEveryInvalidInputThrowsTheDocumentedError() {
        func rate(price: Int = 6_500_000, salvage: Int = 1_500_000, life: Decimal = 8000, annual: Decimal = 1500,
                  fuel: Int = 728, repair: Decimal = Decimal(string: "0.80")!, ins: Int = 240_000, com: Decimal = Decimal(string: "0.07")!) throws -> Int {
            try EquipmentCalc.rateCents(price: price, salvage: salvage, lifeHours: life, annualHours: annual,
                                        fuelOilPerHour: fuel, repairFactor: repair, insurancePerYear: ins, costOfMoney: com)
        }
        func expect(_ e: EquipmentCalcError, _ body: @autoclosure () throws -> Int, file: StaticString = #filePath, line: UInt = #line) {
            XCTAssertThrowsError(try body(), "\(e)", file: file, line: line) { XCTAssertEqual($0 as? EquipmentCalcError, e, file: file, line: line) }
        }
        expect(.salvageNotBelowPrice, try rate(salvage: 6_500_000))
        expect(.salvageNotBelowPrice, try rate(salvage: 6_500_001))
        expect(.salvageNotBelowPrice, try rate(price: 1, salvage: 1))
        expect(.negativeSalvage, try rate(salvage: -1))
        expect(.negativeSalvage, try rate(price: 100, salvage: -100))
        expect(.nonPositivePrice, try rate(price: 0, salvage: 0))
        expect(.nonPositivePrice, try rate(price: -1, salvage: 0))
        expect(.nonPositivePrice, try rate(price: -5, salvage: -5))
        expect(.nonPositivePrice, try rate(price: Int.min, salvage: 0))
        expect(.nonPositiveLifeHours, try rate(life: 0))
        expect(.nonPositiveLifeHours, try rate(life: -1))
        expect(.nonPositiveLifeHours, try rate(life: Decimal(string: "-0.01")!))
        expect(.nonPositiveAnnualHours, try rate(annual: 0))
        expect(.nonPositiveAnnualHours, try rate(annual: -1500))
        expect(.negativeFuelOil, try rate(fuel: -1))
        expect(.negativeFuelOil, try rate(fuel: Int.min))
        expect(.negativeRepairFactor, try rate(repair: Decimal(string: "-0.01")!))
        expect(.negativeInsurance, try rate(ins: -1))
        expect(.negativeCostOfMoney, try rate(com: Decimal(string: "-0.0001")!))
        expect(.nonPositiveLifeHours, try rate(life: .nan))
        expect(.nonPositiveAnnualHours, try rate(annual: .nan))
        expect(.negativeRepairFactor, try rate(repair: .nan))
        expect(.negativeCostOfMoney, try rate(com: .nan))
        XCTAssertNoThrow(try rate(salvage: 0))
        XCTAssertNoThrow(try rate(price: 2, salvage: 1))
        XCTAssertNoThrow(try rate(life: Decimal(string: "0.01")!, annual: Decimal(string: "0.01")!))
        XCTAssertNoThrow(try rate(fuel: 0, repair: 0, ins: 0, com: 0))
    }

    // Round-once (DECISIONS 7): independent cases where per-component rounding differs, in both directions and on a tie.
    func testSumRoundedOnceSecondAndThirdCases() throws {
        let a = try EquipmentCalc.rate(price: 100_000, salvage: 87_500, lifeHours: 1000, annualHours: 1000, fuelOilPerHour: 0,
                                       repairFactor: 0, insurancePerYear: 12_500, costOfMoney: 0)                     // 0.125 + 0.125 = 0.25 → 25 (per-component 26)
        XCTAssertEqual(a.rateCents, 25)
        XCTAssertEqual(Money.cents(a.depreciation * 100) + Money.cents(a.insurance * 100), 26)
        let c = try EquipmentCalc.rate(price: 100_000, salvage: 87_600, lifeHours: 1000, annualHours: 1000, fuelOilPerHour: 0,
                                       repairFactor: 0, insurancePerYear: 12_400, costOfMoney: 0)                     // 0.124 + 0.124 = 0.248 → 25 (per-component 24)
        XCTAssertEqual(c.rateCents, 25)
        XCTAssertEqual(Money.cents(c.depreciation * 100) + Money.cents(c.insurance * 100), 24)
        let d = try EquipmentCalc.rate(price: 100_000, salvage: 66_500, lifeHours: 1000, annualHours: 1000, fuelOilPerHour: 0,
                                       repairFactor: Decimal(string: "0.335")!, insurancePerYear: 33_500, costOfMoney: 0) // 3 × 0.335 = 1.005 → 101 (per-component 102)
        XCTAssertEqual(d.total, Decimal(string: "1.005")!)
        XCTAssertEqual(d.rateCents, 101)
    }
}
