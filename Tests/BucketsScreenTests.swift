import XCTest
import SwiftData
@testable import Buckets

/// Non-view logic behind the Buckets screen: table order, the two calculator drafts, and the screenshot hook.
@MainActor
final class BucketsScreenTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext { container.mainContext }

    override func setUp() async throws {
        container = try Store.inMemoryContainer()
    }

    // MARK: Table order (DECISIONS 28)

    func testRowsInBucketSortBySortOrderThenName() {
        let items = [
            BucketItem(bucket: .labor, name: "Zed", sortOrder: 1),
            BucketItem(bucket: .labor, name: "Bea", sortOrder: 1),
            BucketItem(bucket: .labor, name: "Marcus", sortOrder: 0),
            BucketItem(bucket: .equipment, name: "Chipper", sortOrder: 0),
            BucketItem(bucket: .labor, name: "", sortOrder: 2),
        ]
        XCTAssertEqual(items.rows(in: .labor).map(\.name), ["Marcus", "Bea", "Zed", ""])
        XCTAssertEqual(items.rows(in: .equipment).map(\.name), ["Chipper"])
        XCTAssertTrue(items.rows(in: .overhead).isEmpty)
    }

    func testRateLabelAndDisplayName() {
        XCTAssertEqual(BucketItem(bucket: .labor, name: "Marcus", rateCents: 5408).rateLabel, "$54.08/hr")
        XCTAssertEqual(BucketItem(bucket: .overhead, name: "Rent", rateCents: 960_000).rateLabel, "$9,600.00/yr")
        XCTAssertEqual(BucketItem(bucket: .materials, name: "Palm", rateCents: 8500).rateLabel, "$85.00 each")
        XCTAssertEqual(BucketItem(bucket: .consumables, name: "Dump fee", rateCents: 7500, unit: "load").rateLabel, "$75.00/load")
        XCTAssertEqual(BucketItem(bucket: .consumables, name: "x", rateCents: 100, unit: "").rateLabel, "$1.00")
        XCTAssertEqual(BucketItem(bucket: .labor, name: "").displayName, "Untitled")
        XCTAssertEqual(projectsPhrase(1), "1 project")
        XCTAssertEqual(projectsPhrase(3), "3 projects")
        XCTAssertEqual(hoursString(2080), "2,080")
        XCTAssertEqual(hoursString(Decimal(string: "6.5")!), "6.5")
    }

    // MARK: Labor sheet (DECISIONS 35)

    func testLaborDraftDefaultsFromSettingsAndPricesMarcus() throws {
        var settings = AppSettings()
        settings.laborBurdenPct = 32.5
        var draft = LaborCalcDraft(saved: nil, settings: settings)
        XCTAssertEqual(draft.wageCents, 0)
        XCTAssertEqual(draft.paidHours, 2080)
        XCTAssertEqual(draft.burdenPct, Decimal(string: "32.5")!, "the percent is lifted exactly, never through Double")
        XCTAssertEqual(draft.billableHours, 1500)
        XCTAssertEqual(try draft.result.get(), 0)

        draft.wageCents = 3000
        draft.burdenPct = 30
        XCTAssertEqual(try draft.result.get(), 5408)
        XCTAssertEqual(draft.inputs, LaborCalcInputs(wageCents: 3000, paidHours: 2080, burdenPct: 30))
        XCTAssertEqual(draft.formula, "$30.00 × 1.30 × 2,080 ÷ 1,500")
    }

    func testLaborDraftReopensSavedInputs() {
        let saved = LaborCalcInputs(wageCents: 2200, paidHours: 1800, burdenPct: Decimal(string: "27.5")!)
        let draft = LaborCalcDraft(saved: saved, settings: AppSettings())
        XCTAssertEqual(draft.wageCents, 2200)
        XCTAssertEqual(draft.paidHours, 1800)
        XCTAssertEqual(draft.burdenPct, Decimal(string: "27.5")!)
        XCTAssertEqual(draft.inputs, saved)
    }

    func testLaborDraftShowsTheBillableHoursError() {
        var settings = AppSettings()
        settings.billableHoursPerYear = 0
        let draft = LaborCalcDraft(saved: LaborCalcInputs(wageCents: 3000, paidHours: 2080, burdenPct: 30), settings: settings)
        guard case .failure(let error) = draft.result else { return XCTFail("expected an error") }
        XCTAssertEqual(error as? LaborCalcError, .nonPositiveBillableHours)
        XCTAssertTrue(CalcMessage.text(for: error).contains("Settings"))
    }

    // MARK: Equipment sheet (DECISIONS 13, 36)

    func testEquipmentDraftDefaults() {
        var settings = AppSettings()
        settings.billableHoursPerYear = 1800
        settings.costOfMoneyPct = 7
        let draft = EquipmentCalcDraft(saved: nil, settings: settings)
        XCTAssertEqual(draft.priceCents, 0)
        XCTAssertEqual(draft.salvageCents, 0)
        XCTAssertEqual(draft.lifeHours, 8000)
        XCTAssertEqual(draft.annualHours, 1800, "annual use defaults to the billable hours")
        XCTAssertEqual(draft.repairFactor, Decimal(string: "0.80")!)
        XCTAssertEqual(draft.costOfMoneyPct, 7)
        guard case .failure(let error) = draft.result else { return XCTFail("a blank sheet has no rate yet") }
        XCTAssertEqual(error as? EquipmentCalcError, .nonPositivePrice)
        XCTAssertEqual(CalcMessage.text(for: error), "Enter the purchase price.")
    }

    func testEquipmentDraftPricesTheBucketTruck() throws {
        var settings = AppSettings()
        settings.costOfMoneyPct = 7
        var draft = EquipmentCalcDraft(saved: nil, settings: settings)
        draft.priceCents = 6_500_000
        draft.salvageCents = 1_500_000
        draft.fuelOilPerHourCents = 728
        draft.insurancePerYearCents = 240_000
        let rate = try draft.result.get()
        XCTAssertEqual(EquipmentCalcDraft.dollars(rate.depreciation), "$6.25")
        XCTAssertEqual(EquipmentCalcDraft.dollars(rate.costOfMoney), "$2.09")
        XCTAssertEqual(EquipmentCalcDraft.dollars(rate.insurance), "$1.60")
        XCTAssertEqual(EquipmentCalcDraft.dollars(rate.fuelOil), "$7.28")
        XCTAssertEqual(EquipmentCalcDraft.dollars(rate.repairs), "$6.50")
        XCTAssertEqual(rate.rateCents, 2372)
        XCTAssertEqual(draft.inputs, EquipmentCalcInputs(
            priceCents: 6_500_000, salvageCents: 1_500_000, lifeHours: 8000, annualHours: 1500, fuelOilPerHourCents: 728,
            repairFactor: Decimal(string: "0.80")!, insurancePerYearCents: 240_000, costOfMoneyPct: 7))
    }

    func testEquipmentDraftReopensSavedInputsButReadsCostOfMoneyFromSettings() {
        let saved = EquipmentCalcInputs(priceCents: 6_500_000, salvageCents: 1_500_000, lifeHours: 8000, annualHours: 1000,
                                        fuelOilPerHourCents: 728, repairFactor: Decimal(string: "0.90")!,
                                        insurancePerYearCents: 240_000, costOfMoneyPct: 7)
        var settings = AppSettings()
        settings.costOfMoneyPct = 5
        let draft = EquipmentCalcDraft(saved: saved, settings: settings)
        XCTAssertEqual(draft.annualHours, 1000)
        XCTAssertEqual(draft.repairFactor, Decimal(string: "0.90")!)
        XCTAssertEqual(draft.costOfMoneyPct, 5, "the sheet always shows the live Settings rate (DECISIONS 13)")
        XCTAssertEqual(draft.inputs.costOfMoneyPct, 5)
    }

    func testEquipmentDraftErrors() {
        var draft = EquipmentCalcDraft(saved: nil, settings: AppSettings())
        draft.priceCents = 1000
        draft.salvageCents = 1000
        guard case .failure(let error) = draft.result else { return XCTFail("expected an error") }
        XCTAssertEqual(error as? EquipmentCalcError, .salvageNotBelowPrice)
        XCTAssertEqual(CalcMessage.text(for: error), "Salvage value must be below the purchase price.")
        draft.salvageCents = 0
        draft.lifeHours = 0
        guard case .failure(let e2) = draft.result else { return XCTFail("expected an error") }
        XCTAssertEqual(e2 as? EquipmentCalcError, .nonPositiveLifeHours)
    }

    func testEveryCalcErrorHasADistinctMessage() {
        let labor: [LaborCalcError] = [.negativeWage, .negativePaidHours, .negativeBurden, .nonPositiveBillableHours]
        let equipment: [EquipmentCalcError] = [.nonPositivePrice, .negativeSalvage, .salvageNotBelowPrice, .nonPositiveLifeHours,
                                               .nonPositiveAnnualHours, .negativeFuelOil, .negativeRepairFactor,
                                               .negativeInsurance, .negativeCostOfMoney]
        let messages = labor.map { CalcMessage.text(for: $0) } + equipment.map { CalcMessage.text(for: $0) }
        XCTAssertEqual(Set(messages).count, messages.count)
        XCTAssertTrue(messages.allSatisfy { !$0.isEmpty })
    }

    // MARK: Screenshot hook (DECISIONS 48) — selects, never creates

    func testScreenHookSelectsTheFirstRowOfTheBucket() throws {
        StoreFixture.insertRows(into: context)
        try context.save()
        let items = try StoreFixture.items(in: context)
        func id(_ name: String) -> PersistentIdentifier { items.first { $0.name == name }!.persistentModelID }

        let buckets = AppState(container: container, screen: "buckets")
        XCTAssertEqual(buckets.sidebar, .bucket(.labor))
        XCTAssertEqual(buckets.selectedItem, id("Marcus"))
        XCTAssertFalse(buckets.wantsCalcSheet)

        let overhead = AppState(container: container, screen: "overhead")
        XCTAssertEqual(overhead.sidebar, .bucket(.overhead))
        XCTAssertEqual(overhead.selectedItem, id("General liability"))

        let laborCalc = AppState(container: container, screen: "laborcalc")
        XCTAssertEqual(laborCalc.selectedItem, id("Marcus"))
        XCTAssertTrue(laborCalc.wantsCalcSheet)

        let equipmentCalc = AppState(container: container, screen: "equipmentcalc")
        XCTAssertEqual(equipmentCalc.sidebar, .bucket(.equipment))
        XCTAssertEqual(equipmentCalc.selectedItem, id("Bucket truck (50 ft)"))
        XCTAssertTrue(equipmentCalc.wantsCalcSheet)

        let plain = AppState(container: container, screen: nil)
        XCTAssertEqual(plain.sidebar, .bucket(.labor))
        XCTAssertNil(plain.selectedItem)
        XCTAssertFalse(plain.wantsSettingsWindow)
        XCTAssertTrue(AppState(container: container, screen: "settings").wantsSettingsWindow)
        XCTAssertEqual(try StoreFixture.items(in: context).count, 25, "the hook never creates rows")
    }

    func testScreenHookOnAnEmptyStoreSelectsNothingAndCreatesNothing() throws {
        let state = AppState(container: container, screen: "laborcalc")
        XCTAssertEqual(state.sidebar, .bucket(.labor))
        XCTAssertNil(state.selectedItem)
        XCTAssertFalse(state.wantsCalcSheet, "no row, no sheet")
        XCTAssertEqual(try context.fetch(FetchDescriptor<BucketItem>()).count, 0)
    }

    func testDeleteIsRefusedWhileAProjectReferencesTheRow() throws {
        StoreFixture.insertRows(into: context)
        let project = try StoreFixture.baseProject(in: context)
        let state = AppState(container: container, screen: "buckets")
        let marcus = try StoreFixture.items(in: context).first { $0.name == "Marcus" }!
        XCTAssertEqual(marcus.referenceCount, 1)
        state.delete(marcus)
        XCTAssertEqual(try StoreFixture.items(in: context).count, 25, "referenced rows are not deleted (DECISIONS 22)")
        context.delete(project)
        try context.save()
        XCTAssertEqual(marcus.referenceCount, 0)
        state.delete(marcus)
        XCTAssertEqual(try StoreFixture.items(in: context).count, 24)
        XCTAssertNil(state.selectedItem)
    }
}
