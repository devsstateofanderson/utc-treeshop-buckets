import XCTest
import SwiftData
@testable import Buckets

/// DECISIONS 93 (second paragraph): the Overhead salary calculator, `$/yr = round(amount × periods a year × (100 + burden)
/// ÷ 100)`, one division, rounded once. Every figure was recomputed by hand with exact rational arithmetic, half away from
/// zero once. The pay figures are synthetic: an example salaried salesperson at $200 a day, 5 days × 52 weeks.
@MainActor
final class SalaryCalcTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext { container.mainContext }

    override func setUp() async throws {
        container = try Store.inMemoryContainer()
    }

    private func inputs(_ amount: Int, _ period: SalaryPeriod, days: Decimal = 5, weeks: Decimal = 52,
                        burden: Decimal = 30) -> SalaryCalcInputs {
        SalaryCalcInputs(amountCents: amount, period: period, daysPerWeek: days, weeksPerYear: weeks, burdenPct: burden)
    }

    // MARK: The math

    /// 20,000¢ × (5 × 52) × 130 ÷ 100 = 6,760,000¢ = $67,600.00 a year, the figure such a line carries when typed by hand;
    /// at a 10% burden 20,000 × 260 × 110 ÷ 100 = 5,720,000. The $/hr is display only: 4,506.67 → $45.07, 3,813.33 → $38.13.
    func testExampleSalaryAtThirtyAndTenPercent() throws {
        XCTAssertEqual(try SalaryCalc.annualCents(inputs(20_000, .day)), 6_760_000)
        XCTAssertEqual(try SalaryCalc.annualCents(inputs(20_000, .day, burden: 10)), 5_720_000)
        XCTAssertEqual(try SalaryCalc.annualCents(inputs(20_000, .day, burden: 0)), 5_200_000)
        let settings = AppSettings()
        var draft = SalaryCalcDraft(saved: inputs(20_000, .day), settings: settings)
        XCTAssertEqual(draft.hourlyCents(annualCents: 6_760_000), 4507)
        XCTAssertEqual(draft.summary(annualCents: 6_760_000), "= $67,600.00 per year · $45.07 per hour at 1,500 billable hours")
        draft.burdenPct = 10
        guard case .success(let cents) = draft.result else { return XCTFail("expected a figure") }
        XCTAssertEqual(cents, 5_720_000)
        XCTAssertEqual(draft.summary(annualCents: cents), "= $57,200.00 per year · $38.13 per hour at 1,500 billable hours")
    }

    /// The period table: day = days per week × weeks per year; week = weeks per year; biweekly 26; semimonthly 24;
    /// month 12; year 1. A $52,000 base expressed in each period (0% burden).
    func testPeriodTable() throws {
        let expected: [SalaryPeriod: Decimal] = [.day: 260, .week: 52, .biweekly: 26, .semimonthly: 24, .month: 12, .year: 1]
        for period in SalaryPeriod.allCases {
            XCTAssertEqual(period.periodsPerYear(daysPerWeek: 5, weeksPerYear: 52), expected[period], "\(period)")
        }
        XCTAssertEqual(SalaryPeriod.day.periodsPerYear(daysPerWeek: 6, weeksPerYear: 50), 300)
        XCTAssertEqual(SalaryPeriod.day.periodsPerYear(daysPerWeek: Decimal(string: "4.5")!, weeksPerYear: 52), 234)
        XCTAssertEqual(SalaryPeriod.week.periodsPerYear(daysPerWeek: 6, weeksPerYear: 50), 50)
        XCTAssertEqual(SalaryPeriod.month.periodsPerYear(daysPerWeek: 6, weeksPerYear: 50), 12, "the counts only move day and week")

        XCTAssertEqual(try SalaryCalc.annualCents(inputs(20_000, .day, burden: 0)), 5_200_000)
        XCTAssertEqual(try SalaryCalc.annualCents(inputs(100_000, .week, burden: 0)), 5_200_000)
        XCTAssertEqual(try SalaryCalc.annualCents(inputs(200_000, .biweekly, burden: 0)), 5_200_000)
        XCTAssertEqual(try SalaryCalc.annualCents(inputs(216_667, .semimonthly, burden: 0)), 5_200_008)
        XCTAssertEqual(try SalaryCalc.annualCents(inputs(433_333, .month, burden: 0)), 5_199_996)
        XCTAssertEqual(try SalaryCalc.annualCents(inputs(5_200_000, .year, burden: 0)), 5_200_000)
        XCTAssertEqual(try SalaryCalc.annualCents(inputs(5_200_000, .year)), 6_760_000)

        XCTAssertEqual(SalaryPeriod.allCases.map(\.title),
                       ["per day", "per week", "every two weeks", "twice a month", "per month", "per year"])
        XCTAssertEqual(SalaryPeriod.allCases.filter(\.usesDaysPerWeek), [.day])
        XCTAssertEqual(SalaryPeriod.allCases.filter(\.usesWeeksPerYear), [.day, .week])
    }

    /// A half-cent tie rounds once, away from zero: 15,050¢ a day × 260 × 107.65 ÷ 100 = 4,212,344.5 → 4,212,345.
    /// Rounding the burdened day first (16,201.325 → 16,201, × 260 = 4,212,260) would be 85¢ low, which is why there is
    /// one division. 15,001¢ a week × 52 × 112.5 ÷ 100 = 877,558.5 → 877,559.
    func testTieRoundsOnceAwayFromZero() throws {
        let tie = inputs(15_050, .day, burden: Decimal(string: "7.65")!)
        XCTAssertEqual(try SalaryCalc.annualCents(tie), 4_212_345)
        XCTAssertEqual(Money.cents(Decimal(15_050) * Decimal(string: "107.65")! / 100) * 260, 4_212_260, "the two-step figure")
        XCTAssertEqual(try SalaryCalc.annualCents(inputs(15_001, .week, burden: Decimal(string: "12.5")!)), 877_559)
        XCTAssertEqual(try SalaryCalc.annualCents(inputs(1, .year, burden: 50)), 2, "1.5¢ → 2¢")
        XCTAssertEqual(try SalaryCalc.annualCents(inputs(1, .year, burden: Decimal(string: "49.99")!)), 1, "1.4999¢ → 1¢")
    }

    /// Negative inputs throw (as DECISIONS 9), but only the counts the period uses are checked; a result above the rate
    /// bound of DECISIONS 30 is refused.
    func testNegativesAndTheBoundThrow() throws {
        XCTAssertThrowsError(try SalaryCalc.annualCents(inputs(-1, .year))) { XCTAssertEqual($0 as? SalaryCalcError, .negativeAmount) }
        XCTAssertThrowsError(try SalaryCalc.annualCents(inputs(20_000, .day, burden: -1))) { XCTAssertEqual($0 as? SalaryCalcError, .negativeBurden) }
        XCTAssertThrowsError(try SalaryCalc.annualCents(inputs(20_000, .day, days: -1))) { XCTAssertEqual($0 as? SalaryCalcError, .negativeDaysPerWeek) }
        XCTAssertThrowsError(try SalaryCalc.annualCents(inputs(20_000, .day, weeks: -1))) { XCTAssertEqual($0 as? SalaryCalcError, .negativeWeeksPerYear) }
        XCTAssertThrowsError(try SalaryCalc.annualCents(inputs(100_000, .week, weeks: -1))) { XCTAssertEqual($0 as? SalaryCalcError, .negativeWeeksPerYear) }
        XCTAssertEqual(try SalaryCalc.annualCents(inputs(100_000, .week, days: -1)), 6_760_000, "a week rate never reads days")
        XCTAssertEqual(try SalaryCalc.annualCents(inputs(433_333, .month, days: -1, weeks: -1, burden: 0)), 5_199_996)
        XCTAssertEqual(try SalaryCalc.annualCents(inputs(0, .day)), 0)

        XCTAssertEqual(try SalaryCalc.annualCents(inputs(SalaryCalc.maximumCents, .year, burden: 0)), 999_999_999)
        XCTAssertThrowsError(try SalaryCalc.annualCents(inputs(SalaryCalc.maximumCents, .year, burden: Decimal(string: "0.01")!))) {
            XCTAssertEqual($0 as? SalaryCalcError, .aboveMaximum)
        }
        XCTAssertThrowsError(try SalaryCalc.annualCents(inputs(999_999_999, .day, days: 7, weeks: 53, burden: 999_999))) {
            XCTAssertEqual($0 as? SalaryCalcError, .aboveMaximum)
        }
    }

    func testEveryCalcErrorHasADistinctMessage() {
        let labor: [LaborCalcError] = [.negativeWage, .negativePaidHours, .negativeBurden, .nonPositiveBillableHours]
        let equipment: [EquipmentCalcError] = [.nonPositivePrice, .negativeSalvage, .salvageNotBelowPrice, .nonPositiveLifeHours,
                                               .nonPositiveAnnualHours, .negativeFuelOil, .negativeRepairFactor,
                                               .negativeInsurance, .negativeCostOfMoney]
        let salary: [SalaryCalcError] = [.negativeAmount, .negativeDaysPerWeek, .negativeWeeksPerYear, .negativeBurden, .aboveMaximum]
        let messages = labor.map { CalcMessage.text(for: $0) } + equipment.map { CalcMessage.text(for: $0) }
            + salary.map { CalcMessage.text(for: $0) }
        XCTAssertEqual(Set(messages).count, messages.count)
        XCTAssertTrue(messages.allSatisfy { !$0.isEmpty })
    }

    // MARK: salaryInputs and calcInputs

    /// `salaryInputs` is `calcInputs` decoded for an overhead row, exactly (Decimal fields byte for byte), and nil on
    /// every other bucket or on a line typed by hand.
    func testSalaryInputsRoundTripThroughCalcInputs() throws {
        let saved = inputs(20_000, .day, days: Decimal(string: "4.5")!, weeks: Decimal(string: "50.5")!, burden: Decimal(string: "7.65")!)
        let data = try JSONEncoder().encode(saved)
        let text = String(decoding: data, as: UTF8.self)
        XCTAssertTrue(text.contains("\"burdenPct\":7.65"), text)
        XCTAssertTrue(text.contains("\"period\":\"day\""), text)

        let salary = BucketItem(bucket: .overhead, name: "Sales salary", rateCents: 6_760_000, calcInputs: data)
        XCTAssertEqual(salary.salaryInputs, saved)
        XCTAssertNil(salary.laborInputs)
        XCTAssertNil(salary.equipmentInputs)
        XCTAssertNil(BucketItem(bucket: .labor, name: "x", calcInputs: data).salaryInputs, "Labor reads laborInputs only")
        XCTAssertNil(BucketItem(bucket: .overhead, name: "Rent", rateCents: 960_000).salaryInputs, "typed by hand: no inputs")
        let labor = try JSONEncoder().encode(LaborCalcInputs(wageCents: 3000, paidHours: 2080, burdenPct: 30))
        XCTAssertNil(BucketItem(bucket: .overhead, name: "y", calcInputs: labor).salaryInputs, "another calculator's inputs")
        XCTAssertNil(BucketItem(bucket: .overhead, name: "z", calcInputs: Data("{\"amountCents\":1,\"period\":\"fortnight\"}".utf8)).salaryInputs)
    }

    /// Export and import carry the inputs as they carry every calculator's (DECISIONS 43): no format change. Fractional
    /// counts and burden (4.5 days, 50.5 weeks, 7.65%) come back exactly through `JSONValue.number(Decimal)`.
    func testTransferCarriesTheInputs() throws {
        let saved = inputs(20_000, .day, days: Decimal(string: "4.5")!, weeks: Decimal(string: "50.5")!, burden: Decimal(string: "7.65")!)
        let rate = try SalaryCalc.annualCents(saved)
        let row = BucketItem(bucket: .overhead, name: "Sales salary", rateCents: rate, calcInputs: try JSONEncoder().encode(saved))
        context.insert(row)
        try context.save()
        let data = try Transfer.exportJSON(from: context, settings: AppSettings(), exportedAt: .now)
        XCTAssertEqual(try Transfer.decoder().decode(TransferDocument.self, from: data).formatVersion, 3)

        let other = try Store.inMemoryContainer()
        _ = try Transfer.importJSON(data, into: other.mainContext)
        let back = try XCTUnwrap(try other.mainContext.fetch(FetchDescriptor<BucketItem>()).first { $0.name == "Sales salary" })
        XCTAssertEqual(back.rateCents, rate)
        XCTAssertEqual(back.salaryInputs, saved)
        XCTAssertEqual(back.salaryInputs?.burdenPct, Decimal(string: "7.65")!)
        XCTAssertEqual(back.salaryInputs?.daysPerWeek, Decimal(string: "4.5")!)
        XCTAssertEqual(back.salaryInputs?.weeksPerYear, Decimal(string: "50.5")!)
    }

    // MARK: The sheet's draft

    func testDraftDefaultsSavesAndReopens() throws {
        var settings = AppSettings()
        settings.laborBurdenPct = 27.5
        var draft = SalaryCalcDraft(saved: nil, settings: settings)
        XCTAssertEqual(draft.amountCents, 0)
        XCTAssertEqual(draft.period, .year)
        XCTAssertEqual(draft.daysPerWeek, 5)
        XCTAssertEqual(draft.weeksPerYear, 52)
        XCTAssertEqual(draft.burdenPct, Decimal(string: "27.5")!, "the burden defaults from Settings")
        XCTAssertEqual(draft.billableHours, 1500)

        draft.amountCents = 20_000
        draft.period = .day
        draft.burdenPct = 30
        XCTAssertEqual(draft.formula, "$200.00 × 5 × 52 × 1.30")
        let row = BucketItem(bucket: .overhead, name: "Sales salary", rateCents: 1)
        context.insert(row)
        XCTAssertTrue(draft.save(into: row))
        XCTAssertEqual(row.rateCents, 6_760_000)
        XCTAssertEqual(row.salaryInputs, draft.inputs)

        let reopened = SalaryCalcDraft(saved: row.salaryInputs, settings: AppSettings())
        XCTAssertEqual(reopened, draft, "reopens filled in; the burden is the row's, not Settings'")

        var week = draft
        week.period = .week
        week.amountCents = 100_000
        XCTAssertEqual(week.formula, "$1,000.00 × 52 × 1.30")
        week.period = .semimonthly
        XCTAssertEqual(week.formula, "$1,000.00 × 24 × 1.30")
        week.period = .year
        week.burdenPct = Decimal(string: "7.65")!
        XCTAssertEqual(week.formula, "$1,000.00 × 1.0765")

        var bad = draft
        bad.burdenPct = -1
        let labor = BucketItem(bucket: .labor, name: "Crew", rateCents: 5408)
        XCTAssertFalse(bad.save(into: row), "an error saves nothing")
        XCTAssertFalse(draft.save(into: labor), "only an Overhead line takes a salary")
        XCTAssertEqual(row.rateCents, 6_760_000)
        XCTAssertEqual(labor.rateCents, 5408)
        XCTAssertNil(labor.calcInputs)

        var noHours = draft
        noHours.billableHours = 0
        XCTAssertNil(noHours.hourlyCents(annualCents: 6_760_000))
        XCTAssertEqual(noHours.summary(annualCents: 6_760_000), "= $67,600.00 per year")
    }

    /// The calculator moves no price: a line typed by hand at $67,600.00 and the same line saved through the sheet price
    /// a project identically, before and after Re-price.
    func testSavingTheExampleSalaryMovesNoPrice() throws {
        StoreFixture.insertRows(into: context)
        let salary = BucketItem(bucket: .overhead, name: "Sales salary", rateCents: 6_760_000,
                                sortOrder: BucketItem.nextSortOrder(in: .overhead, context: context))
        context.insert(salary)
        let project = Project.make(date: .now, items: try StoreFixture.items(in: context), settings: AppSettings())
        context.insert(project)
        project.hours = 8
        project.line("Mini skid steer").isOn = false
        let dump = project.line("Dump fee"); dump.isOn = true; dump.qty = 2
        let before = project.breakdown(billableHours: 1500)
        // §3.3's $27,000 of overhead plus the salary: 9,460,000 × 8 ÷ 1,500 = 50,453.33 → 50,453.
        XCTAssertEqual(before.overhead, 50_453)

        var draft = SalaryCalcDraft(saved: nil, settings: AppSettings())
        draft.amountCents = 20_000
        draft.period = .day
        XCTAssertTrue(draft.save(into: salary))
        XCTAssertEqual(salary.rateCents, 6_760_000)
        XCTAssertEqual(project.breakdown(billableHours: 1500), before)
        project.reprice(items: try StoreFixture.items(in: context), settings: AppSettings())
        XCTAssertEqual(project.breakdown(billableHours: 1500), before)
    }

    // MARK: Screenshot hook (DECISIONS 48)

    func testScreenHookOpensTheFirstSalaryLine() throws {
        let rows = StoreFixture.insertRows(into: context)
        try context.save()
        let plain = AppState(container: container, screen: "salarycalc")
        XCTAssertEqual(plain.sidebar, .bucket(.overhead))
        XCTAssertEqual(plain.selectedItem, rows["General liability"]!.persistentModelID, "no salary line: the first overhead row")
        XCTAssertTrue(plain.wantsCalcSheet)

        let salary = BucketItem(bucket: .overhead, name: "Sales salary", rateCents: 6_760_000,
                                calcInputs: try JSONEncoder().encode(inputs(20_000, .day)),
                                sortOrder: BucketItem.nextSortOrder(in: .overhead, context: context))
        context.insert(salary)
        try context.save()
        let state = AppState(container: container, screen: "salarycalc")
        XCTAssertEqual(state.selectedItem, salary.persistentModelID)
        XCTAssertTrue(state.wantsCalcSheet)
        XCTAssertEqual(try StoreFixture.items(in: context).count, 26, "the hook never creates rows")
    }
}
