import XCTest
import SwiftData
@testable import Buckets

/// Sold by on a project (DECISIONS 94) and rows not on the crew (DECISIONS 83, 93). Synthetic people and rates:
/// "Sam Rivera" is a salaried salesperson at 7% whose labor row is not on the crew.
@MainActor
final class ProjectSalespersonTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext { container.mainContext }
    private var sam: BucketItem!

    private var allowanceSettings: AppSettings {
        var s = AppSettings(); s.salesAllowancePct = 7; return s
    }

    override func setUp() async throws {
        container = try Store.inMemoryContainer()
        StoreFixture.insertRows(into: context)
        sam = BucketItem(bucket: .labor, name: "Sam Rivera", rateCents: 4000, sortOrder: 3)
        sam.commissionPct = 7
        sam.trackOnly = true
        context.insert(sam)
        try context.save()
    }

    /// The §3.3 job (8 h, skid steer off, two dump loads: cost 185,296) as a new project at `settings`.
    private func newProject(_ settings: AppSettings = AppSettings()) throws -> Project {
        let project = Project.make(date: .now, items: try StoreFixture.items(in: context), settings: settings)
        context.insert(project)
        project.hours = 8
        project.line("Mini skid steer").isOn = false
        let dump = project.line("Dump fee"); dump.isOn = true; dump.qty = 2
        try context.save()
        return project
    }

    func testPickingASalespersonSetsTheLinkTheNameAndTheSnapshot() throws {
        let project = try newProject()
        XCTAssertFalse(project.hasSalesperson)
        XCTAssertEqual(project.effectiveCommissionPct, 0)
        project.setSalesperson(sam)
        XCTAssertEqual(project.salesperson?.persistentModelID, sam.persistentModelID)
        XCTAssertEqual(project.salespersonName, "Sam Rivera")
        XCTAssertEqual(project.commissionPct, 7)
        XCTAssertNil(project.commissionPctOverride)
        XCTAssertEqual(project.effectiveCommissionPct, 7)
        XCTAssertEqual(sam.soldProjects.count, 1)
        XCTAssertEqual(project.commissionTerms, CommissionTerms(pct: 7, burdenPct: Decimal(string: "7.65")!))
        let b = project.breakdown(billableHours: 1500)
        XCTAssertEqual(b.price, 370_592, "the price does not depend on who sells")
        XCTAssertEqual(b.commission, 25_941, "370,592 × 7 ÷ 100 = 25,941.44")
        XCTAssertEqual(b.commissionTax, 1985, "370,592 × 53.55 ÷ 10,000 = 1,984.52")
        XCTAssertEqual(b.profitAfterCommission, 370_592 - 185_296 - 25_941 - 1985)
    }

    func testRepriceRefreshesTheSnapshotAndTheDefaultsAndLeavesTheOverride() throws {
        let project = try newProject(allowanceSettings)
        XCTAssertEqual(project.salesAllowancePct, 7)
        XCTAssertEqual(project.commissionBurdenPct, Decimal(string: "7.65")!)
        project.setSalesperson(sam)
        project.commissionPctOverride = 10
        XCTAssertEqual(project.effectiveCommissionPct, 10)
        XCTAssertEqual(ProjectText.personRateCaption(project), "person's rate: 7%")

        // A fuel change and a new % on the row; the company raises the allowance and the payroll tax.
        let truck = try StoreFixture.items(in: context).first { $0.name == "Chip truck (F-550)" }!
        truck.rateCents = 2300
        sam.commissionPct = 8
        sam.name = "Sam Rivera-Lee"
        var later = allowanceSettings
        later.salesAllowancePct = 8
        later.commissionBurdenPct = 9
        project.reprice(items: try StoreFixture.items(in: context), settings: later)
        XCTAssertEqual(project.line("Chip truck (F-550)").rateCents, 2300)
        XCTAssertEqual(project.commissionPct, 8, "the snapshot refreshes from the row")
        XCTAssertEqual(project.salespersonName, "Sam Rivera-Lee")
        XCTAssertEqual(project.commissionPctOverride, 10, "the negotiated % is never refreshed")
        XCTAssertEqual(project.effectiveCommissionPct, 10)
        XCTAssertEqual(project.salesAllowancePct, 8)
        XCTAssertEqual(project.commissionBurdenPct, 9)
        let b = project.breakdown(billableHours: 1500)
        XCTAssertEqual(b.commission, Money.cents(Decimal(b.price) * 10 / 100))
        XCTAssertEqual(b.commissionTax, Money.cents(Decimal(b.price) * 10 * 9 / 10000))
    }

    func testEffectiveCommissionIsTheOverrideElseTheSnapshotAndZeroWithoutASalesperson() throws {
        let project = try newProject()
        project.commissionPctOverride = 12
        XCTAssertEqual(project.effectiveCommissionPct, 0, "an override with nobody picked pays nothing")
        project.setSalesperson(sam)
        XCTAssertEqual(project.effectiveCommissionPct, 12)
        project.commissionPctOverride = nil
        XCTAssertEqual(project.effectiveCommissionPct, 7)
        project.commissionPctOverride = 0
        XCTAssertEqual(project.effectiveCommissionPct, 0, "a negotiated 0% is a value")
        project.commissionPctOverride = 12
        project.setSalesperson(nil)
        XCTAssertNil(project.salesperson); XCTAssertNil(project.salespersonName); XCTAssertNil(project.commissionPct)
        XCTAssertEqual(project.commissionPctOverride, 12, "clearing Sold by leaves the typed override")
        XCTAssertEqual(project.effectiveCommissionPct, 0)
        XCTAssertEqual(project.breakdown(billableHours: 1500).commission, 0)
        project.commissionPctOverride = 250
        project.setSalesperson(sam)
        XCTAssertEqual(project.effectiveCommissionPct, 100, "held to 0…100")
    }

    func testDeletingTheRowNullifiesTheLinkAndKeepsTheName() throws {
        let project = try newProject()
        project.setSalesperson(sam)
        try context.save()
        XCTAssertFalse(sam.canDelete)
        // Bypasses the guard to exercise the declared inverse (DECISIONS 21).
        context.delete(sam)
        try context.save()
        XCTAssertNil(project.salesperson)
        XCTAssertEqual(project.salespersonName, "Sam Rivera")
        XCTAssertEqual(project.commissionPct, 7)
        XCTAssertTrue(project.hasSalesperson, "the sale terms outlive the row")
        XCTAssertEqual(ProjectText.soldByTitle(project), "Sold by Sam Rivera (row deleted)")
        // Re-price has no row to refresh from and keeps the snapshot.
        project.reprice(items: try StoreFixture.items(in: context), settings: AppSettings())
        XCTAssertEqual(project.commissionPct, 7)
    }

    func testTheDeleteGuardRefusesARowWithSoldProjects() throws {
        XCTAssertTrue(sam.canDelete, "no line and no sale yet")
        let project = try newProject()
        XCTAssertFalse(project.lines.contains { $0.item?.persistentModelID == sam.persistentModelID }, "not on the crew: no line")
        project.setSalesperson(sam)
        try context.save()
        XCTAssertEqual(sam.referenceCount, 0)
        XCTAssertEqual(sam.soldCount, 1)
        XCTAssertFalse(sam.canDelete)
        XCTAssertEqual(sam.usagePhrase, "used in 0 projects · sold 1")
        let state = AppState(container: container, screen: nil)
        state.delete(sam)
        XCTAssertFalse(sam.isDeleted)
        XCTAssertTrue(try StoreFixture.items(in: context).contains { $0.name == "Sam Rivera" }, "the guard refused")
        let marcus = try StoreFixture.items(in: context).first { $0.name == "Marcus" }!
        XCTAssertEqual(marcus.usagePhrase, "used in 1 project", "the sold count appears only when there is one")
    }

    func testDuplicateRowKeepsItOffTheCrew() throws {
        let state = AppState(container: container, screen: nil)
        state.duplicate(sam)
        let copy = try XCTUnwrap(try StoreFixture.items(in: context).first { $0.name == "Sam Rivera copy" })
        XCTAssertTrue(copy.trackOnly)
        XCTAssertEqual(copy.commissionPct, 7)
    }

    func testDuplicateCopiesAndPackagesCarryNone() throws {
        let project = try newProject(allowanceSettings)
        project.setSalesperson(sam)
        project.commissionPctOverride = 10
        let copy = project.duplicate(date: .now)
        context.insert(copy)
        XCTAssertEqual(copy.salesperson?.persistentModelID, sam.persistentModelID)
        XCTAssertEqual(copy.salespersonName, "Sam Rivera")
        XCTAssertEqual(copy.commissionPct, 7)
        XCTAssertEqual(copy.commissionPctOverride, 10)
        XCTAssertEqual(copy.salesAllowancePct, 7)
        XCTAssertEqual(copy.commissionBurdenPct, Decimal(string: "7.65")!)

        let package = project.asPackage(date: .now)
        context.insert(package)
        XCTAssertNil(package.salesperson); XCTAssertNil(package.salespersonName)
        XCTAssertNil(package.commissionPct); XCTAssertNil(package.commissionPctOverride)
        XCTAssertEqual(package.salesAllowancePct, 7, "the allowance is a pricing default, kept like the margin")
        package.setSalesperson(sam)
        XCTAssertNil(package.salesperson, "a package never takes a salesperson")
        XCTAssertFalse(ProjectText.showsSoldBy(package, laborRows: try StoreFixture.items(in: context).rows(in: .labor)))

        let used = package.instantiate(date: .now, items: try StoreFixture.items(in: context), settings: allowanceSettings)
        context.insert(used)
        XCTAssertNil(used.salesperson)
        XCTAssertFalse(used.hasSalesperson)
        try context.save()
        XCTAssertEqual(sam.soldProjects.count, 2, "the project and its duplicate")
    }

    func testTrackOnlyRowsAreSkippedByNewProjectsRepriceAndLoadouts() throws {
        // A project made before the row was marked keeps its line and prices from the snapshot (17).
        sam.trackOnly = false
        let before = try newProject()
        XCTAssertTrue(before.line("Sam Rivera").isOn)
        let priceBefore = before.priceCents
        sam.trackOnly = true
        sam.rateCents = 9000

        let fresh = try newProject()
        XCTAssertFalse(fresh.lines.contains { $0.name == "Sam Rivera" }, "make skips it")
        XCTAssertEqual(fresh.lines.count, 25)

        before.reprice(items: try StoreFixture.items(in: context), settings: AppSettings())
        XCTAssertEqual(before.line("Sam Rivera").rateCents, 4000, "Re-price skips it; the existing line keeps its snapshot")
        XCTAssertEqual(before.priceCents, priceBefore)
        fresh.reprice(items: try StoreFixture.items(in: context), settings: AppSettings())
        XCTAssertFalse(fresh.lines.contains { $0.name == "Sam Rivera" }, "Re-price appends nothing for it")

        let crew = Loadout(name: "Crew A")
        context.insert(crew)
        let items = try StoreFixture.items(in: context)
        crew.members = items.filter { ["Marcus", "David", "Sam Rivera", "Bucket truck (50 ft)"].contains($0.name) }
        fresh.apply(crew)
        XCTAssertFalse(fresh.lines.contains { $0.name == "Sam Rivera" }, "a loadout never appends it")
        XCTAssertEqual(fresh.lines.filter { $0.bucket == .labor && $0.isOn }.map(\.name).sorted(), ["David", "Marcus"])
        before.apply(crew)
        XCTAssertFalse(before.line("Sam Rivera").isOn, "a loadout never turns it on")
    }

    func testRepriceOnATemplateWithoutALineForTheTrackOnlyRowAppendsNothing() throws {
        // A package from before the row existed (the 197-line case): Re-price must not append him switched on.
        let package = Project.make(name: "Package", date: .now, items: try StoreFixture.items(in: context).filter { $0.name != "Sam Rivera" },
                                   settings: AppSettings())
        package.isTemplate = true
        context.insert(package)
        XCTAssertEqual(package.lines.count, 25)
        package.reprice(items: try StoreFixture.items(in: context), settings: AppSettings())
        XCTAssertEqual(package.lines.count, 25)
        XCTAssertFalse(package.lines.contains { $0.name == "Sam Rivera" })
    }
}
