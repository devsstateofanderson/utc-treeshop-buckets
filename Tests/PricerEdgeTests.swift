import XCTest
@testable import Buckets

/// Edge values for every Pricer parameter. Expected values from exact rational arithmetic (python3 fractions),
/// rounding half-away-from-zero once per figure (BRIEF §5.2, DECISIONS 3, 4, 5, 10).
final class Probe_pricer_edges: XCTestCase {
    private func check(_ b: Breakdown, _ e: (Int, Int, Int, Int, Int, Int, Int, Int), _ label: String,
                       file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual([b.labor, b.equipment, b.overhead, b.materials, b.consumables, b.cost, b.price, b.profit],
                       [e.0, e.1, e.2, e.3, e.4, e.5, e.6, e.7], label, file: file, line: line)
        XCTAssertEqual(b.cost, b.labor + b.equipment + b.materials + b.consumables + b.subcontractors + b.overhead, "\(label): Cost = Σ", file: file, line: line)
        XCTAssertEqual(b.profit, b.price - b.cost, "\(label): Profit = Price − Cost", file: file, line: line)
    }

    // MARK: hours

    func testHoursThreeDecimalsUsedExactly() {
        // 12439×6.333 = 78776.187 ; 7048×6.333 = 44634.984 ; 2.7M×6.333/1500 = 11399.4 ; cost 149810 ; ×1.35 = 202243.5 → 202244
        check(Fixture.price(Fixture.lines(), hours: Decimal(string: "6.333")!),
              (78_776, 44_635, 11_399, 0, 15_000, 149_810, 202_244, 52_434), "6.333 h")
    }

    func testHugeHours() {
        // 100000 h: labor 1,243,900,000 ; equipment 704,800,000 ; overhead 180,000,000 ; cost 2,128,715,000 ; ×1.35 = 2,873,765,250 exactly
        check(Fixture.price(Fixture.lines(), hours: 100_000),
              (1_243_900_000, 704_800_000, 180_000_000, 0, 15_000, 2_128_715_000, 2_873_765_250, 745_050_250), "100000 h")
    }

    func testTinyHours() {
        // 0.001 h: 12.439 → 12 ; 7.048 → 7 ; 1.8 → 2 ; cost 15021 ; 20278.35 → floor 75000
        check(Fixture.price(Fixture.lines(), hours: Decimal(string: "0.001")!),
              (12, 7, 2, 0, 15_000, 15_021, 75_000, 59_979), "0.001 h")
    }

    func testNegativeHoursClampToZero() {
        check(Fixture.price(Fixture.lines(), hours: -8), (0, 0, 0, 0, 15_000, 15_000, 75_000, 60_000), "-8 h")
        check(Fixture.price(Fixture.lines(), hours: Decimal(string: "-0.01")!), (0, 0, 0, 0, 15_000, 15_000, 75_000, 60_000), "-0.01 h")
    }

    // MARK: qty

    func testFractionalQty() {
        var lines = Fixture.lines()
        lines[lines.firstIndex(of: Fixture.dumpFee)!].qty = Decimal(string: "2.5")!
        // 7500 × 2.5 = 18750 ; cost 189046 ; ×1.35 = 255212.1 → 255212
        check(Fixture.price(lines), (99_512, 56_384, 14_400, 0, 18_750, 189_046, 255_212, 66_166), "2.5 loads")
    }

    func testEnormousQty() {
        var lines = Fixture.lines()
        lines[lines.firstIndex(of: Fixture.dumpFee)!].qty = 1_000_000
        // 7.5e9 ; cost 7,500,170,296 ; ×1.35 = 10,125,229,899.6 → 10,125,229,900
        check(Fixture.price(lines), (99_512, 56_384, 14_400, 0, 7_500_000_000, 7_500_170_296, 10_125_229_900, 2_625_059_604), "1e6 loads")
    }

    func testZeroAndNegativeQty() {
        var lines = Fixture.lines()
        lines[lines.firstIndex(of: Fixture.dumpFee)!].qty = 0
        check(Fixture.price(lines), (99_512, 56_384, 14_400, 0, 0, 170_296, 229_900, 59_604), "qty 0")
        lines[lines.firstIndex { $0.bucket == .consumables && $0.rateCents == 7500 }!].qty = -2
        check(Fixture.price(lines), (99_512, 56_384, 14_400, 0, 0, 170_296, 229_900, 59_604), "qty -2")
    }

    // MARK: multiplier

    // MARK: markup

    func testMarkupZero() {
        check(Fixture.price(Fixture.lines(), markup: 0), (99_512, 56_384, 14_400, 0, 15_000, 185_296, 185_296, 0), "markup 0")
        XCTAssertEqual(Fixture.price(Fixture.lines(), markup: 0).marginPct, 0)
    }

    func testMarkupTenIsOneThousandPercent() {
        // 185296 × 11 = 2,038,256 ; margin 1852960/2038256 = 90.909…%
        let b = Fixture.price(Fixture.lines(), markup: 10)
        check(b, (99_512, 56_384, 14_400, 0, 15_000, 185_296, 2_038_256, 1_852_960), "markup 10")
        XCTAssertEqual(Money.cents(b.marginPct * 1000), 90_909)
    }

    // MARK: minimum job

    func testMinimumZeroAndNegative() {
        XCTAssertEqual(Fixture.price(Fixture.lines(), minimum: 0).price, 250_150)
        let allOff = Fixture.lines().map { var l = $0; l.isOn = false; return l }
        check(Fixture.price(allOff, minimum: 0), (0, 0, 0, 0, 0, 0, 0, 0), "min 0 all off")
        XCTAssertEqual(Fixture.price(allOff, minimum: 0).marginPct, 0)
        check(Fixture.price(allOff, minimum: -1), (0, 0, 0, 0, 0, 0, 0, 0), "min -1 all off")
        XCTAssertEqual(Fixture.price(allOff, minimum: -100).marginPct, 0)
    }

    // MARK: billable hours

    func testBillableEdges() {
        // ≤ 0 → overhead 0 (DECISIONS 10): cost 170896 ; ×1.35 = 230709.6 → 230710
        check(Fixture.price(Fixture.lines(), billable: 0), (99_512, 56_384, 0, 0, 15_000, 170_896, 230_710, 59_814), "billable 0")
        check(Fixture.price(Fixture.lines(), billable: -1), (99_512, 56_384, 0, 0, 15_000, 170_896, 230_710, 59_814), "billable -1")
        // 1500.5: 21,600,000/1500.5 = 14395.2016 → 14395 ; cost 185291 ; ×1.35 = 250142.85 → 250143
        check(Fixture.price(Fixture.lines(), billable: Decimal(string: "1500.5")!),
              (99_512, 56_384, 14_395, 0, 15_000, 185_291, 250_143, 64_852), "billable 1500.5")
        // 0.001: overhead 21,600,000,000 ; cost 21,600,170,896 ; ×1.35 = 29,160,230,709.6 → 29,160,230,710
        check(Fixture.price(Fixture.lines(), billable: Decimal(string: "0.001")!),
              (99_512, 56_384, 21_600_000_000, 0, 15_000, 21_600_170_896, 29_160_230_710, 7_560_059_814), "billable 0.001")
        // 1499 with 7.33 h: 12439×7.33 = 91177.87 → 91178 ; 7048×7.33 = 51661.84 → 51662 ; 2.7M×7.33/1499 = 13202.8019 → 13203
        check(Fixture.price(Fixture.lines(), hours: Decimal(string: "7.33")!, billable: 1499),
              (91_178, 51_662, 13_203, 0, 15_000, 171_043, 230_908, 59_865), "billable 1499 7.33 h")
    }

    // MARK: row sets

    func testOverheadRowsOnlyAndNoLines() {
        let overheadOnly = Fixture.lines().filter { $0.bucket == .overhead }
        check(Fixture.price(overheadOnly), (0, 0, 14_400, 0, 0, 14_400, 75_000, 60_600), "overhead only")
        check(Fixture.price([]), (0, 0, 0, 0, 0, 0, 75_000, 75_000), "no lines")
        XCTAssertEqual(Fixture.price([]).marginPct, 100)
        let allOff = Fixture.lines().map { var l = $0; l.isOn = false; return l }
        check(Fixture.price(allOff), (0, 0, 0, 0, 0, 0, 75_000, 75_000), "all off")
    }

    func testOverheadIsSummedThenDividedOnceNotPerRow() {
        // three $0.01/yr rows, 1 h, billable 2: Σ = 3 → 1.5 → 2 ; per-row rounding would be 1+1+1 = 3
        let b = Fixture.price(Array(repeating: PriceLine(bucket: .overhead, rateCents: 1), count: 3), hours: 1, minimum: 0, billable: 2)
        XCTAssertEqual(b.overhead, 2)
        // DECISIONS 4 with the brief's rows: 2,700,000 × 8 / 1500 = 14400 exactly; per-row $/hr display would also be 14400 here,
        // so use billable 1499: Σ 21,600,000/1499 = 14409.606 → 14410 vs per-row ($/hr rounded, summed, × 8) = 1800 × 8 = 14400
        let brief = Fixture.price(Fixture.lines().filter { $0.bucket == .overhead }, minimum: 0, billable: 1499)
        XCTAssertEqual(brief.overhead, 14_410)
    }
}
