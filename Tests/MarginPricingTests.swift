import XCTest
import SwiftData
@testable import Buckets

/// DECISIONS 70: the company prices to a target margin. Price = Cost × 100 × multiplier ÷ (100 − margin), one
/// division, rounded once; the brief's markup path stays for projects created before margins existed.
final class MarginPricingTests: XCTestCase {
    private var cost: Int { Fixture.price(Fixture.lines()).cost }

    func testFiftyPercentMarginDoublesTheCost() {
        let b = Pricer.price(lines: Fixture.lines(), hours: 8, multiplier: 1, rule: .targetMargin(50),
                             minimumJobCents: 75_000, billableHours: 1500)
        XCTAssertEqual(b.cost, 185_296)
        XCTAssertEqual(b.price, 370_592)
        XCTAssertEqual(b.profit, 185_296)
        XCTAssertEqual(b.marginPct, 50)
        XCTAssertEqual(Fixture.price(Fixture.lines()).price, 250_150, "the markup path is untouched")
    }

    func testMarginIsOneDivisionRoundedOnce() {
        // 40%: 185,296 × 100 ÷ 60 = 308,826.666… → 308,827
        XCTAssertEqual(price(margin: 40), 308_827)
        // 20% on a 2¢ cost: 2 × 100 ÷ 80 = 2.5 exactly → 3 (half away from zero), no Decimal drift from a second step
        let tie = Pricer.price(lines: [PriceLine(bucket: .materials, rateCents: 2, isOn: true, qty: 1)], hours: 0,
                               multiplier: 1, rule: .targetMargin(20), minimumJobCents: 0, billableHours: 1500)
        XCTAssertEqual(tie.cost, 2)
        XCTAssertEqual(tie.price, 3)
        XCTAssertEqual(price(margin: Decimal(string: "33.5")!), Money.cents(Decimal(185_296) * 100 / Decimal(string: "66.5")!))
    }

    func testMultiplierAndFloorStillApply() {
        let b = Pricer.price(lines: Fixture.lines(), hours: 8, multiplier: 3, rule: .targetMargin(50),
                             minimumJobCents: 75_000, billableHours: 1500)
        XCTAssertEqual(b.price, 185_296 * 6)
        let floor = Pricer.price(lines: [PriceLine(bucket: .materials, rateCents: 100, isOn: true, qty: 1)], hours: 0,
                                 multiplier: 1, rule: .targetMargin(50), minimumJobCents: 75_000, billableHours: 1500)
        XCTAssertEqual(floor.price, 75_000)
        XCTAssertEqual(floor.profit, 74_900)
    }

    func testMarginIsClampedSoThePriceAlwaysExists() {
        XCTAssertEqual(price(margin: 0), 185_296, "0% margin: price = cost")
        XCTAssertEqual(price(margin: -10), 185_296, "negative margins are ignored")
        XCTAssertEqual(price(margin: 95), 185_296 * 20)
        XCTAssertEqual(price(margin: 100), 185_296 * 20, "held at 95%: a 100% margin has no price")
        XCTAssertEqual(price(margin: .nan), 185_296)
    }

    func testMarkupEquivalentForDisplay() {
        XCTAssertEqual(PriceRule.targetMargin(50).markupPercent, 100)
        XCTAssertEqual(PriceRule.targetMargin(0).markupPercent, 0)
        XCTAssertEqual(PriceRule.markup(Decimal(string: "0.35")!).markupPercent, 35)
        XCTAssertEqual(Project.rounded2(PriceRule.targetMargin(40).markupPercent), Decimal(string: "66.67")!)
        XCTAssertEqual(AppSettings.defaults.targetMarginPct, 50)
        XCTAssertEqual(AppSettings().pricingRule, .targetMargin(50))
    }

    private func price(margin: Decimal) -> Int {
        Pricer.price(lines: Fixture.lines(), hours: 8, multiplier: 1, rule: .targetMargin(margin),
                     minimumJobCents: 75_000, billableHours: 1500).price
    }
}

@MainActor
final class MarginProjectTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext { container.mainContext }

    override func setUp() async throws {
        container = try Store.inMemoryContainer()
        StoreFixture.insertRows(into: context)
    }

    func testNewProjectsSnapshotTheCompanyTargetMargin() throws {
        let project = Project.make(date: .now, items: try StoreFixture.items(in: context), settings: AppSettings())
        XCTAssertEqual(project.targetMarginPct, 50)
        XCTAssertEqual(project.markupPct, 100, "markup equivalent, for display")
        XCTAssertEqual(project.minimumJobCents, 75_000)
        XCTAssertEqual(project.pricingRule, .targetMargin(50))
    }

    func testMarginProjectPricesAtTwiceCostAndLegacyProjectsKeepTheirMarkup() throws {
        let project = try StoreFixture.baseProject(in: context)
        XCTAssertEqual(project.priceCents, 250_150)
        project.targetMarginPct = 50
        XCTAssertEqual(project.priceCents, 370_592)
        XCTAssertEqual(project.breakdown(billableHours: 1500).marginPct, 50)
        project.line("Miguel").isOn = false
        XCTAssertEqual(project.priceCents, 321_552)
        project.multiplier = 2
        XCTAssertEqual(project.priceCents, 643_104)
        let copy = project.duplicate(date: .now)
        XCTAssertEqual(copy.targetMarginPct, 50)
        XCTAssertEqual(copy.asPackage(date: .now).targetMarginPct, 50)
    }

    func testTransferCarriesTheMarginAndUpgradesOldFiles() throws {
        let project = try StoreFixture.baseProject(in: context)
        project.targetMarginPct = 50
        project.markupPct = 100
        var settings = AppSettings(); settings.targetMarginPct = 45
        let data = try Transfer.exportJSON(from: context, settings: settings, exportedAt: .now)
        let json = String(decoding: data, as: UTF8.self)
        XCTAssertTrue(json.contains("\"targetMarginPct\" : 45"), json)
        XCTAssertTrue(json.contains("\"markupPct\" : 81.82"), "old readers still get a markup")

        let fresh = try Store.inMemoryContainer()
        let imported = try Transfer.importJSON(data, into: fresh.mainContext)
        XCTAssertEqual(imported.targetMarginPct, 45)
        let back = try fresh.mainContext.fetch(FetchDescriptor<Project>()).first!
        XCTAssertEqual(back.targetMarginPct, 50)
        XCTAssertEqual(back.priceCents, 370_592)

        // A file written before DECISIONS 70 carries only a markup: the project keeps it, the settings convert it.
        let old = """
        {"formatVersion": 1, "exportedAt": "2026-01-01T00:00:00Z",
         "settings": {"billableHoursPerYear": 1500, "laborBurdenPct": 30, "markupPct": 35, "minimumJobCents": 75000, "costOfMoneyPct": 0},
         "items": [{"bucket": "materials", "name": "Mulch", "rateCents": 500, "unit": "bag", "isActive": true, "sortOrder": 0, "source": "manual"}],
         "projects": [{"name": "Old", "client": null, "date": "2026-01-01T00:00:00Z", "hours": 0, "multiplier": 1, "markupPct": 35, "minimumJobCents": 0, "actualHours": null, "notes": null,
                       "lines": [{"bucket": "materials", "name": "Mulch", "rateCents": 500, "unit": "bag", "isOn": true, "qty": 2, "actualQty": null, "sortOrder": 0}]}]}
        """
        let legacy = try Store.inMemoryContainer()
        let converted = try Transfer.importJSON(Data(old.utf8), into: legacy.mainContext)
        XCTAssertEqual(converted.targetMarginPct, 35.0 / 135.0 * 100, accuracy: 1e-9)
        let oldProject = try legacy.mainContext.fetch(FetchDescriptor<Project>()).first!
        XCTAssertNil(oldProject.targetMarginPct)
        XCTAssertEqual(oldProject.priceCents, 1350, "10.00 × 1.35")
    }
}
