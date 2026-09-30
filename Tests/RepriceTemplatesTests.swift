import XCTest
import SwiftData
import SwiftUI
@testable import Buckets

/// Company → Re-price packages (DECISIONS 92): packages snapshot the allowance as they snapshot the margin, so the day
/// the allowance changes every package is stale until re-priced. The banner counts them; the action re-prices every
/// package and no ordinary project.
@MainActor
final class RepriceTemplatesTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext { container.mainContext }

    override func setUp() async throws {
        container = try Store.inMemoryContainer()
        StoreFixture.insertRows(into: context)
    }

    private func package(_ name: String, settings: AppSettings = AppSettings()) throws -> Project {
        let p = Project.make(name: name, date: .now, items: try StoreFixture.items(in: context), settings: settings)
        p.isTemplate = true
        p.hours = 8
        context.insert(p)
        return p
    }

    func testTheBannerCountsStalePackagesAndTheActionRepricesThemAll() throws {
        let removal = try package("Removal")
        let prune = try package("Prune")
        let legacy = try package("Legacy markup")
        legacy.targetMarginPct = nil
        legacy.markupPct = 35
        // A package from before the allowance existed: no snapshot at all.
        let old = try package("Old")
        old.salesAllowancePct = nil
        old.commissionBurdenPct = nil
        let job = Project.make(name: "Job", date: .now, items: try StoreFixture.items(in: context), settings: AppSettings())
        job.hours = 8
        context.insert(job)
        try context.save()
        let projects = try context.fetch(FetchDescriptor<Project>())

        // Nothing is stale while the allowance is 0, whatever the payroll tax: no price would move.
        XCTAssertEqual(Project.templatesUnderOlderAllowance(projects, settings: AppSettings()), 0)
        var noAllowance = AppSettings(); noAllowance.commissionBurdenPct = 12
        XCTAssertEqual(Project.templatesUnderOlderAllowance(projects, settings: noAllowance), 0)

        var settings = AppSettings(); settings.salesAllowancePct = 7
        XCTAssertEqual(Project.templatesUnderOlderAllowance(projects, settings: settings), 3,
                       "the three margin packages; a legacy markup package ignores the allowance and the job is not a package")
        let before = removal.priceCents
        let jobPrice = job.priceCents
        XCTAssertEqual(try Project.repriceTemplates(in: context, settings: settings), 3)
        XCTAssertEqual(removal.salesAllowancePct, 7)
        XCTAssertEqual(prune.salesAllowancePct, 7)
        XCTAssertEqual(old.commissionBurdenPct, Decimal(string: "7.65")!)
        XCTAssertEqual(legacy.targetMarginPct, 50, "every package is re-priced, the legacy one onto today's margin too")
        XCTAssertGreaterThan(removal.priceCents, before)
        XCTAssertEqual(removal.priceCents, Money.cents(Decimal(removal.breakdown(billableHours: 1500).cost) * 10000 / Decimal(string: "4246.45")!))
        XCTAssertEqual(job.salesAllowancePct, 0, "an ordinary project is untouched")
        XCTAssertEqual(job.priceCents, jobPrice)
        XCTAssertEqual(Project.templatesUnderOlderAllowance(try context.fetch(FetchDescriptor<Project>()), settings: settings), 0)
        XCTAssertEqual(try Project.repriceTemplates(in: context, settings: settings), 0, "a second run reports 0")

        // A change to the payroll tax alone moves the price while the allowance is on.
        settings.commissionBurdenPct = 9
        XCTAssertEqual(Project.templatesUnderOlderAllowance(try context.fetch(FetchDescriptor<Project>()), settings: settings), 4)
    }

    func testCopyForTheBanner() {
        XCTAssertEqual(SettingsText.stalePackages(1), "1 package priced under an older allowance")
        XCTAssertEqual(SettingsText.stalePackages(9), "9 packages priced under an older allowance")
    }

    func testThePricingDefaultsRefuseAShareOver95() {
        let b = Decimal(string: "7.65")!
        XCTAssertTrue(SettingsField.pricingShareFits(margin: 50, allowance: 7, burden: b))
        XCTAssertTrue(SettingsField.pricingShareFits(margin: 95, allowance: 0, burden: b))
        XCTAssertFalse(SettingsField.pricingShareFits(margin: 90, allowance: 5, burden: b), "90 + 5 × 1.0765 = 95.38")
        XCTAssertTrue(SettingsField.pricingShareFits(margin: 90, allowance: 5, burden: 0), "exactly 95")
        XCTAssertFalse(SettingsField.pricingShareFits(margin: 96, allowance: 0, burden: 0))
        XCTAssertFalse(SettingsField.pricingShareFits(margin: 50, allowance: 101, burden: 0))
        XCTAssertFalse(SettingsField.pricingShareFits(margin: 50, allowance: 7, burden: 101))
        XCTAssertFalse(SettingsField.pricingShareFits(margin: 50, allowance: -1, burden: 0))

        var margin = 50.0, allowance = 0.0, burden = 7.65
        let a = SettingsField.allowance(Binding(get: { allowance }, set: { allowance = $0 }), margin: margin, burden: burden)
        a.wrappedValue = 7
        XCTAssertEqual(allowance, 7)
        a.wrappedValue = 60
        XCTAssertEqual(allowance, 7, "refused: 50 + 60 × 1.0765 > 95")
        let m = SettingsField.margin(Binding(get: { margin }, set: { margin = $0 }), allowance: allowance, burden: burden)
        m.wrappedValue = 90
        XCTAssertEqual(margin, 50, "refused with a 7% allowance")
        m.wrappedValue = Decimal(string: "42.5")!
        XCTAssertEqual(margin, 42.5)
        let t = SettingsField.commissionBurden(Binding(get: { burden }, set: { burden = $0 }), margin: margin, allowance: allowance)
        t.wrappedValue = 30
        XCTAssertEqual(burden, 30)
        t.wrappedValue = 150
        XCTAssertEqual(burden, 30, "0…100")
        XCTAssertEqual(SettingsText.markupString(AppSettings().pricingRule), "100.0%")
        var s = AppSettings(); s.salesAllowancePct = 7
        XCTAssertEqual(SettingsText.markupString(s.pricingRule), "135.5%")
    }
}
