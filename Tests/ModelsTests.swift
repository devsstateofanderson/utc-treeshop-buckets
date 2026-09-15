import XCTest
import SwiftData
@testable import Buckets

/// The §3.3 rows as `BucketItem`s in an in-memory store. Test-target only.
@MainActor
enum StoreFixture {
    static let settings = AppSettings()

    @discardableResult
    static func insertRows(into context: ModelContext) -> [String: BucketItem] {
        var rows: [String: BucketItem] = [:]
        func add(_ bucket: Bucket, _ name: String, _ rate: Int, unit: String? = nil, active: Bool = true) {
            let order = BucketItem.nextSortOrder(in: bucket, context: context)
            let item = BucketItem(bucket: bucket, name: name, rateCents: rate, unit: unit, isActive: active, sortOrder: order)
            context.insert(item)
            rows[name] = item
        }
        add(.labor, "Marcus", 5408); add(.labor, "David", 3966); add(.labor, "Miguel", 3065)
        add(.equipment, "Bucket truck (50 ft)", 2372); add(.equipment, "Chip truck (F-550)", 2215)
        add(.equipment, "Chipper (12\")", 1711); add(.equipment, "Chainsaws (3)", 750); add(.equipment, "Mini skid steer", 1603)
        add(.overhead, "General liability", 600_000); add(.overhead, "Shop rent", 960_000); add(.overhead, "Website + marketing", 360_000)
        add(.overhead, "Phones + internet", 240_000); add(.overhead, "Accounting + legal", 240_000); add(.overhead, "Software", 180_000)
        add(.overhead, "Licenses + misc", 120_000)
        add(.materials, "Queen palm, 10 gal", 8500, unit: "each"); add(.materials, "Root barrier", 4500, unit: "20 ft roll")
        add(.materials, "Mulch", 3200, unit: "yard"); add(.materials, "Stakes + ties kit", 1200, unit: "each")
        add(.consumables, "Dump fee", 7500, unit: "load"); add(.consumables, "Grapple truck (sub)", 65_000, unit: "day")
        add(.consumables, "Stump grinding (sub)", 9000, unit: "stump"); add(.consumables, "Crane (sub)", 180_000, unit: "day")
        add(.consumables, "Cambistat", 12_000, unit: "application"); add(.consumables, "Permit", 5000, unit: "each")
        return rows
    }

    static func items(in context: ModelContext) throws -> [BucketItem] {
        try context.fetch(FetchDescriptor<BucketItem>())
    }

    /// The §3.3 base project: 8 hours, skid steer off, dump fee on × 2.
    static func baseProject(in context: ModelContext) throws -> Project {
        let project = Project.make(date: Date(timeIntervalSince1970: 1_700_000_000), items: try items(in: context), settings: settings)
        context.insert(project)
        project.hours = 8
        project.line("Mini skid steer").isOn = false
        let dump = project.line("Dump fee"); dump.isOn = true; dump.qty = 2
        try context.save()
        return project
    }
}

extension Project {
    func line(_ name: String) -> ProjectLine { lines.first { $0.name == name }! }
    var priceCents: Int { breakdown(billableHours: 1500).price }
}

@MainActor
final class ModelsTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext { container.mainContext }

    override func setUp() async throws {
        container = try Store.inMemoryContainer()
        StoreFixture.insertRows(into: context)
    }

    func testNewProjectDefaultsAndTheWorkedExample() throws {
        let project = try StoreFixture.baseProject(in: context)
        XCTAssertEqual(project.lines.count, 25)
        XCTAssertTrue(project.lines.filter { $0.bucket.rowKind == .hourly && $0.name != "Mini skid steer" }.allSatisfy(\.isOn))
        XCTAssertTrue(project.lines.filter { $0.bucket.rowKind == .quantity && $0.name != "Dump fee" }.allSatisfy { !$0.isOn && $0.qty == 1 })
        XCTAssertEqual(project.markupPct, 35)
        XCTAssertEqual(project.minimumJobCents, 75_000)
        XCTAssertEqual(project.breakdown(billableHours: 1500).price, 250_150)
        project.line("Miguel").isOn = false
        XCTAssertEqual(project.priceCents, 217_048)
        project.line("Miguel").isOn = true
        project.line("Mini skid steer").isOn = true
        XCTAssertEqual(project.priceCents, 267_462)
        let stumps = project.line("Stump grinding (sub)"); stumps.isOn = true; stumps.qty = 3
        XCTAssertEqual(project.priceCents, 303_912)
    }

    // Layer 7: mutate a BucketItem.rateCents after the line exists → project price unchanged.
    func testSnapshotIsolatesProjectFromRowEdits() throws {
        let project = try StoreFixture.baseProject(in: context)
        let marcus = try StoreFixture.items(in: context).first { $0.name == "Marcus" }!
        marcus.rateCents = 9999
        marcus.name = "Marcus (raise)"
        marcus.unit = "day"
        try context.save()
        XCTAssertEqual(project.priceCents, 250_150)
        XCTAssertEqual(project.line("Marcus").rateCents, 5408)
        // Toggling off and on never re-snapshots (DECISIONS 17).
        project.line("Marcus").isOn = false
        project.line("Marcus").isOn = true
        XCTAssertEqual(project.priceCents, 250_150)
    }

    func testDeletedRowLeavesTheLinePricingFromItsSnapshot() throws {
        let project = try StoreFixture.baseProject(in: context)
        let dump = try StoreFixture.items(in: context).first { $0.name == "Dump fee" }!
        XCTAssertEqual(dump.referenceCount, 1)
        context.delete(dump)
        try context.save()
        XCTAssertNil(project.line("Dump fee").item)
        XCTAssertEqual(project.priceCents, 250_150)
        // Re-price leaves the orphan alone and does not resurrect the row.
        project.reprice(items: try StoreFixture.items(in: context), settings: StoreFixture.settings)
        XCTAssertEqual(project.priceCents, 250_150)
        XCTAssertEqual(project.lines.count, 25)
    }

    func testRepriceRefreshesSnapshotsSettingsAndAppendsNewRows() throws {
        let project = try StoreFixture.baseProject(in: context)
        let items = try StoreFixture.items(in: context)
        items.first { $0.name == "Marcus" }!.rateCents = 6000          // a raise
        items.first { $0.name == "Miguel" }!.isActive = false           // archived: still refreshed, still on
        let newHire = BucketItem(bucket: .labor, name: "Ana", rateCents: 4000, sortOrder: 3)
        context.insert(newHire)
        let newMaterial = BucketItem(bucket: .materials, name: "Sod", rateCents: 500, unit: "pallet", sortOrder: 4)
        context.insert(newMaterial)
        try context.save()
        var settings = StoreFixture.settings
        settings.markupPct = 40; settings.minimumJobCents = 100_000
        project.reprice(items: try StoreFixture.items(in: context), settings: settings)
        XCTAssertEqual(project.line("Marcus").rateCents, 6000)
        XCTAssertTrue(project.line("Miguel").isOn)
        XCTAssertEqual(project.markupPct, 40)
        XCTAssertEqual(project.minimumJobCents, 100_000)
        XCTAssertEqual(project.lines.count, 27)
        XCTAssertTrue(project.line("Ana").isOn)
        XCTAssertFalse(project.line("Sod").isOn)
        XCTAssertEqual(project.line("Sod").qty, 1)
        XCTAssertFalse(project.line("Mini skid steer").isOn, "toggles survive re-price")
        XCTAssertEqual(project.line("Dump fee").qty, 2, "quantities survive re-price")
        // (212.87 + 5.92 + 40.00) × 8 + 150 = 2220.32 × 1.40
        XCTAssertEqual(project.priceCents, Money.cents(Decimal(222_032) * Decimal(string: "1.40")!))
    }

    func testDuplicateCopiesEverythingAndClearsActuals() throws {
        let project = try StoreFixture.baseProject(in: context)
        project.client = "Mrs. Lee"; project.notes = "gate code 1234"; project.multiplier = 2
        project.actualHours = 10; project.line("Dump fee").actualQty = 3
        let marcus = try StoreFixture.items(in: context).first { $0.name == "Marcus" }!
        marcus.rateCents = 9999   // the copy must keep the old snapshot, not re-snapshot
        let copy = project.duplicate(date: Date(timeIntervalSince1970: 1_800_000_000))
        context.insert(copy)
        try context.save()
        XCTAssertEqual(copy.name, "New project copy")
        XCTAssertEqual(copy.client, "Mrs. Lee")
        XCTAssertEqual(copy.notes, "gate code 1234")
        XCTAssertEqual(copy.multiplier, 2)
        XCTAssertEqual(copy.hours, 8)
        XCTAssertNil(copy.actualHours)
        XCTAssertTrue(copy.lines.allSatisfy { $0.actualQty == nil })
        XCTAssertEqual(copy.lines.count, 25)
        XCTAssertEqual(copy.line("Marcus").rateCents, 5408)
        XCTAssertEqual(copy.line("Dump fee").qty, 2)
        XCTAssertFalse(copy.line("Mini skid steer").isOn)
        XCTAssertEqual(copy.priceCents, 500_299)
        XCTAssertTrue(copy.line("Marcus").item === marcus)
    }

    func testNewProjectsExcludeArchivedRows() throws {
        try StoreFixture.items(in: context).first { $0.name == "Crane (sub)" }!.isActive = false
        let project = Project.make(date: .now, items: try StoreFixture.items(in: context), settings: StoreFixture.settings)
        XCTAssertEqual(project.lines.count, 24)
        XCTAssertNil(project.lines.first { $0.name == "Crane (sub)" })
    }

    func testDeletingAProjectCascadesToItsLines() throws {
        let project = try StoreFixture.baseProject(in: context)
        XCTAssertEqual(try context.fetch(FetchDescriptor<ProjectLine>()).count, 25)
        context.delete(project)
        try context.save()
        XCTAssertEqual(try context.fetch(FetchDescriptor<ProjectLine>()).count, 0)
        XCTAssertEqual(try StoreFixture.items(in: context).count, 25, "rows are untouched")
        XCTAssertEqual(try StoreFixture.items(in: context).first { $0.name == "Marcus" }!.referenceCount, 0)
    }

    func testActualsVariance() throws {
        let project = try StoreFixture.baseProject(in: context)
        XCTAssertNil(project.actuals(billableHours: 1500))
        project.actualHours = 10
        let a = try XCTUnwrap(project.actuals(billableHours: 1500))
        XCTAssertEqual(a.estimate.cost, 185_296)
        XCTAssertEqual(a.actual.labor, 124_390)
        XCTAssertEqual(a.actual.cost, 227_870)          // 212.87 × 10 + 150
        XCTAssertEqual(a.variance(.labor), 24_878)
        XCTAssertEqual(a.variance(.consumables), 0)
        XCTAssertEqual(a.totalVariance, 42_574)
        XCTAssertEqual(Money.cents(a.totalVariancePct! * 10), 230)   // 22.97% → 23.0
        project.line("Dump fee").actualQty = 3
        XCTAssertEqual(project.actuals(billableHours: 1500)!.variance(.consumables), 7500)
        project.actualHours = 6
        XCTAssertEqual(project.actuals(billableHours: 1500)!.totalVariance, 127_722 + 22_500 - 185_296)
    }

    func testSortedLinesFollowBucketThenRowOrder() throws {
        let project = try StoreFixture.baseProject(in: context)
        let names = project.sortedLines.map(\.name)
        XCTAssertEqual(Array(names.prefix(3)), ["Marcus", "David", "Miguel"])
        XCTAssertEqual(names[3], "Bucket truck (50 ft)")
        XCTAssertEqual(project.sortedLines.map(\.bucket), Bucket.allCases.flatMap { b in Array(repeating: b, count: project.lines(in: b).count) })
        XCTAssertEqual(project.lines(in: .overhead).count, 7)
    }

    func testExportImportRoundTrip() throws {
        let project = try StoreFixture.baseProject(in: context)
        project.actualHours = 10
        project.line("Dump fee").actualQty = 3
        let marcus = try StoreFixture.items(in: context).first { $0.name == "Marcus" }!
        marcus.calcInputs = try JSONEncoder().encode(LaborCalcInputs(wageCents: 3000, paidHours: 2080, burdenPct: 30))
        marcus.source = nil; marcus.notes = "crew lead"
        let dump = try StoreFixture.items(in: context).first { $0.name == "Dump fee" }!
        context.delete(dump)                                   // an orphan line must survive the trip
        try context.save()
        var settings = AppSettings(); settings.costOfMoneyPct = 7; settings.laborBurdenPct = 32.5
        let stamp = Date(timeIntervalSince1970: 1_750_000_000)

        let data = try Transfer.exportJSON(from: context, settings: settings, exportedAt: stamp)
        let text = try XCTUnwrap(String(data: data, encoding: .utf8))
        XCTAssertTrue(text.contains("\"wageCents\" : 3000"), "calculator inputs are readable JSON, not base64")
        XCTAssertFalse(text.contains("Bucket truck (50 ft)\" : "), "sanity: no dictionary-shaped rows")

        let second = try Store.inMemoryContainer()
        let imported = try Transfer.importJSON(data, into: second.mainContext)
        XCTAssertEqual(imported, settings)
        let again = try Transfer.exportJSON(from: second.mainContext, settings: imported, exportedAt: stamp)
        XCTAssertEqual(String(data: again, encoding: .utf8), text)

        let projects = try second.mainContext.fetch(FetchDescriptor<Project>())
        XCTAssertEqual(projects.count, 1)
        XCTAssertEqual(projects[0].priceCents, 250_150)
        XCTAssertEqual(projects[0].actualHours, 10)
        XCTAssertNil(projects[0].line("Dump fee").item)
        XCTAssertNotNil(projects[0].line("Marcus").item)
        XCTAssertEqual(projects[0].line("Marcus").item?.laborInputs?.wageCents, 3000)
        XCTAssertEqual(try second.mainContext.fetch(FetchDescriptor<BucketItem>()).count, 24)
    }

    func testImportReplacesEverything() throws {
        _ = try StoreFixture.baseProject(in: context)
        let data = try Transfer.exportJSON(from: context, settings: AppSettings(), exportedAt: .now)
        // Importing the file into the same store must not double anything.
        try Transfer.importJSON(data, into: context)
        try Transfer.importJSON(data, into: context)
        XCTAssertEqual(try StoreFixture.items(in: context).count, 25)
        XCTAssertEqual(try context.fetch(FetchDescriptor<Project>()).count, 1)
        XCTAssertEqual(try context.fetch(FetchDescriptor<ProjectLine>()).count, 25)
    }

    func testImportRejectsBadFiles() throws {
        XCTAssertThrowsError(try Transfer.importJSON(Data("{}".utf8), into: context))
        let bad = """
        {"formatVersion": 2, "exportedAt": "2026-01-01T00:00:00Z", "settings": {"billableHoursPerYear": 1500, "laborBurdenPct": 30, "markupPct": 35, "minimumJobCents": 75000, "costOfMoneyPct": 0}, "items": [], "projects": []}
        """
        XCTAssertThrowsError(try Transfer.importJSON(Data(bad.utf8), into: context)) {
            XCTAssertEqual($0 as? TransferError, .unsupportedFormat(2))
        }
        XCTAssertEqual(try StoreFixture.items(in: context).count, 25, "a rejected import changes nothing")
    }

    func testSettingsAreExactDecimals() {
        var s = AppSettings()
        s.laborBurdenPct = 32.5; s.markupPct = 35; s.costOfMoneyPct = 7
        XCTAssertEqual(s.laborBurden, Decimal(string: "0.325")!)
        XCTAssertEqual(s.markup, Decimal(string: "0.35")!)
        XCTAssertEqual(s.costOfMoney, Decimal(string: "0.07")!)
        XCTAssertEqual(s.billableHours, 1500)
        XCTAssertEqual(Money.decimal(from: 0.1 + 0.2), Decimal(string: "0.30000000000000004")!)
        let d = UserDefaults(suiteName: "BucketsTests.settings")!
        d.removePersistentDomain(forName: "BucketsTests.settings")
        AppSettings.register(in: d)
        XCTAssertEqual(AppSettings.current(from: d), AppSettings.defaults)
        s.save(to: d)
        XCTAssertEqual(AppSettings.current(from: d), s)
    }

    func testRowHelpers() throws {
        let items = try StoreFixture.items(in: context)
        XCTAssertEqual(items.first { $0.name == "Shop rent" }!.hourlyRateCents(billableHours: 1500), 640)
        XCTAssertEqual(items.first { $0.name == "Marcus" }!.hourlyRateCents(billableHours: 1500), 5408)
        XCTAssertNil(items.first { $0.name == "Dump fee" }!.hourlyRateCents(billableHours: 1500))
        XCTAssertEqual(BucketItem.nextSortOrder(in: .labor, context: context), 3)
        XCTAssertEqual(BucketItem.nextSortOrder(in: .overhead, context: context), 7)
        XCTAssertEqual(BucketItem(bucket: .overhead, name: "x").unit, "yr")
        XCTAssertEqual(BucketItem(bucket: .labor, name: "x").unit, "hr")
        XCTAssertEqual(BucketItem(bucket: .materials, name: "x").unit, "each")
    }
}
