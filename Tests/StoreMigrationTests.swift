import XCTest
import SwiftData
@testable import Buckets

/// The v1.1 schema, declared here so the migration test can write a store exactly the way v1.1 did without a
/// store file in the repository (AGENTS.md: never commit raw SwiftData stores). The nested classes carry the
/// app's entity names, so a store written with this schema is what the app finds on a customer Mac that ran
/// v1.1; only the attributes v0.2.0 added (`BucketItem` review fields, `Company.serviceArea`) are absent.
enum BucketsSchemaV11: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 1, 0)
    static var models: [any PersistentModel.Type] {
        [BucketItem.self, Project.self, ProjectLine.self, Subcontractor.self, Loadout.self, Company.self, CompanyDocument.self]
    }

    @Model final class BucketItem {
        var bucket: Bucket
        var name: String
        var rateCents: Int
        var unit: String
        var isActive: Bool
        var source: String?
        var notes: String?
        var calcInputs: Data?
        var sortOrder: Int
        var category: String?
        var link: String?
        var subcontractor: Subcontractor?
        var loadouts: [Loadout] = []
        var unitCode: String?
        var make: String?
        var model: String?
        var year: Int?
        var serial: String?
        @Relationship(deleteRule: .nullify, inverse: \ProjectLine.item) var lines: [ProjectLine] = []

        init(bucket: Bucket, name: String, rateCents: Int, unit: String, sortOrder: Int) {
            self.bucket = bucket
            self.name = name
            self.rateCents = rateCents
            self.unit = unit
            self.isActive = true
            self.sortOrder = sortOrder
        }
    }

    @Model final class Project {
        var name: String
        var client: String?
        var date: Date
        var hours: Decimal
        var multiplier: Int
        var markupPct: Decimal
        var targetMarginPct: Decimal?
        var minimumJobCents: Int
        var actualHours: Decimal?
        var notes: String?
        var isTemplate: Bool = false
        var crewName: String?
        @Relationship(deleteRule: .cascade) var lines: [ProjectLine] = []

        init(name: String, client: String?, date: Date, hours: Decimal, markupPct: Decimal, targetMarginPct: Decimal?, minimumJobCents: Int) {
            self.name = name
            self.client = client
            self.date = date
            self.hours = hours
            self.multiplier = 1
            self.markupPct = markupPct
            self.targetMarginPct = targetMarginPct
            self.minimumJobCents = minimumJobCents
        }
    }

    @Model final class ProjectLine {
        var item: BucketItem?
        var bucket: Bucket
        var name: String
        var unit: String
        var rateCents: Int
        var isOn: Bool
        var qty: Decimal
        var actualQty: Decimal?

        init(item: BucketItem, isOn: Bool, qty: Decimal = 1, actualQty: Decimal? = nil) {
            self.item = item
            self.bucket = item.bucket
            self.name = item.name
            self.unit = item.unit
            self.rateCents = item.rateCents
            self.isOn = isOn
            self.qty = qty
            self.actualQty = actualQty
        }
    }

    @Model final class Subcontractor {
        var name: String
        var contact: String?
        var phone: String?
        var email: String?
        var notes: String?
        var isActive: Bool
        var sortOrder: Int
        @Relationship(deleteRule: .cascade, inverse: \BucketItem.subcontractor) var services: [BucketItem] = []

        init(name: String, sortOrder: Int) {
            self.name = name
            self.isActive = true
            self.sortOrder = sortOrder
        }
    }

    @Model final class Loadout {
        var name: String
        var notes: String?
        var sortOrder: Int
        @Relationship(inverse: \BucketItem.loadouts) var members: [BucketItem] = []

        init(name: String, sortOrder: Int) {
            self.name = name
            self.sortOrder = sortOrder
        }
    }

    @Model final class Company {
        var name: String
        var dba: String?
        var owner: String?
        var address: String?
        var phone: String?
        var email: String?
        var website: String?
        var ein: String?
        var licenses: String?
        var glCarrier: String?
        var glPolicy: String?
        var glExpires: Date?
        var autoCarrier: String?
        var autoPolicy: String?
        var autoExpires: Date?
        var wcCarrier: String?
        var wcPolicy: String?
        var wcExpires: Date?
        var notes: String?
        @Relationship(deleteRule: .cascade, inverse: \CompanyDocument.company) var documents: [CompanyDocument] = []

        init(name: String) { self.name = name }
    }

    @Model final class CompanyDocument {
        var title: String
        var category: String
        var fileName: String
        var originalName: String
        var addedAt: Date
        var expiresAt: Date?
        var notes: String?
        var company: Company?

        init(title: String, category: String, fileName: String, originalName: String, addedAt: Date) {
            self.title = title
            self.category = category
            self.fileName = fileName
            self.originalName = originalName
            self.addedAt = addedAt
        }
    }
}

/// A store written by the v1.1 schema (the BRIEF §3.3 rows and two projects, as `FixtureStoreWriter` wrote them
/// under v1.1) opens under the v0.2.0 schema with every row, project and price intact and the new fields empty
/// (issue #3 §1, §5). This is the migration a customer's live store goes through when the app is replaced.
@MainActor
final class StoreMigrationTests: XCTestCase {
    private var url: URL!

    override func setUp() async throws {
        let dir = FileManager.default.temporaryDirectory.appending(path: "BucketsMigration-\(UUID().uuidString)", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        url = dir.appending(path: "Buckets.store")
        try Self.writeV11Store(at: url)
    }

    override func tearDown() async throws {
        try? FileManager.default.removeItem(at: url.deletingLastPathComponent())
    }

    /// The §3.3 rows plus "Oak removal" (8 h, skid steer off, 2 dump loads, actuals entered) and "Palm install"
    /// (4 h, skid steer on, 6 palms, 6 stake kits, 3 yards of mulch), both at the 50% target margin.
    static func writeV11Store(at url: URL) throws {
        typealias Item = BucketsSchemaV11.BucketItem
        typealias Line = BucketsSchemaV11.ProjectLine
        let container = try ModelContainer(for: Schema(versionedSchema: BucketsSchemaV11.self),
                                           configurations: ModelConfiguration(url: url))
        let context = container.mainContext
        var rows: [String: Item] = [:]
        var ordered: [Item] = []
        var order: [Bucket: Int] = [:]
        func add(_ bucket: Bucket, _ name: String, _ rate: Int, unit: String? = nil) {
            let item = Item(bucket: bucket, name: name, rateCents: rate, unit: unit ?? bucket.fixedUnit ?? "each", sortOrder: order[bucket, default: 0])
            order[bucket, default: 0] += 1
            context.insert(item)
            rows[name] = item
            ordered.append(item)
        }
        add(.labor, "Marcus", 5408); add(.labor, "David", 3966); add(.labor, "Miguel", 3065)
        add(.equipment, "Bucket truck (50 ft)", 2372); add(.equipment, "Chip truck (F-550)", 2215)
        add(.equipment, "Chipper (12\")", 1711); add(.equipment, "Chainsaws (3)", 750); add(.equipment, "Mini skid steer", 1603)
        for (name, code, make, model, year, serial, category) in [
            ("Bucket truck (50 ft)", "TRK-01", "Ford", "F-750 / Altec LRV-56", 2016, "1FDXF7DC0GDA12345", "Trucks"),
            ("Chip truck (F-550)", "TRK-02", "Ford", "F-550", 2019, "1FDUF5HT9KDA67890", "Trucks"),
            ("Chipper (12\")", "CHP-01", "Bandit", "Intimidator 12XP", 2018, "12XP-004231", "Chippers"),
            ("Chainsaws (3)", "SAW-01", "STIHL", "MS 500i", 2023, nil, "Chainsaws"),
            ("Mini skid steer", "MCH-01", "Toro", "Dingo TX 427", 2021, "TX427-31877", "Machines")] as [(String, String, String, String, Int, String?, String)] {
            let row = rows[name]!
            row.unitCode = code; row.make = make; row.model = model; row.year = year; row.serial = serial; row.category = category
        }
        add(.overhead, "General liability", 600_000); add(.overhead, "Shop rent", 960_000); add(.overhead, "Website + marketing", 360_000)
        add(.overhead, "Phones + internet", 240_000); add(.overhead, "Accounting + legal", 240_000); add(.overhead, "Software", 180_000)
        add(.overhead, "Licenses + misc", 120_000)
        add(.materials, "Queen palm, 10 gal", 8500, unit: "each"); add(.materials, "Root barrier", 4500, unit: "20 ft roll")
        add(.materials, "Mulch", 3200, unit: "yard"); add(.materials, "Stakes + ties kit", 1200, unit: "each")
        add(.consumables, "Dump fee", 7500, unit: "load"); add(.consumables, "Grapple truck (sub)", 65_000, unit: "day")
        add(.consumables, "Stump grinding (sub)", 9000, unit: "stump"); add(.consumables, "Crane (sub)", 180_000, unit: "day")
        add(.consumables, "Cambistat", 12_000, unit: "application"); add(.consumables, "Permit", 5000, unit: "each")
        rows["Marcus"]!.calcInputs = try JSONEncoder().encode(LaborCalcInputs(wageCents: 3000, paidHours: 2080, burdenPct: 30))
        rows["Dump fee"]!.source = "Orange County landfill"
        rows["Queen palm, 10 gal"]!.source = "Cherry Lake"

        func lines(on: (Item) -> Bool, qty: [String: Decimal] = [:], actualQty: [String: Decimal] = [:]) -> [Line] {
            ordered.map { Line(item: $0, isOn: on($0), qty: qty[$0.name] ?? 1, actualQty: actualQty[$0.name]) }
        }
        let removal = BucketsSchemaV11.Project(name: "Oak removal", client: "R. Delgado", date: Date(timeIntervalSince1970: 1_757_800_000),
                                               hours: 8, markupPct: 100, targetMarginPct: 50, minimumJobCents: 75_000)
        removal.notes = "Gate on the left; dump run at lunch."
        removal.actualHours = 10
        context.insert(removal)
        removal.lines = lines(on: { ($0.bucket.rowKind == .hourly && $0.name != "Mini skid steer") || $0.name == "Dump fee" },
                              qty: ["Dump fee": 2], actualQty: ["Dump fee": 3])
        let palms = BucketsSchemaV11.Project(name: "Palm install", client: "Sunridge HOA", date: Date(timeIntervalSince1970: 1_757_900_000),
                                             hours: 4, markupPct: 100, targetMarginPct: 50, minimumJobCents: 75_000)
        context.insert(palms)
        palms.lines = lines(on: { $0.bucket.rowKind == .hourly || ["Queen palm, 10 gal", "Stakes + ties kit", "Mulch"].contains($0.name) },
                            qty: ["Queen palm, 10 gal": 6, "Stakes + ties kit": 6, "Mulch": 3])
        try context.save()
    }

    func testV11StoreOpensWithEveryRowProjectAndPriceIntact() throws {
        let container = try Store.container(at: url)
        let context = container.mainContext
        let items = try context.fetch(FetchDescriptor<BucketItem>())
        XCTAssertEqual(items.count, 25)
        XCTAssertEqual(items.first { $0.name == "Marcus" }?.rateCents, 5408)
        XCTAssertEqual(items.first { $0.name == "Bucket truck (50 ft)" }?.unitCode, "TRK-01")
        XCTAssertEqual(items.first { $0.name == "Dump fee" }?.source, "Orange County landfill")
        XCTAssertEqual(items.first { $0.name == "Marcus" }?.laborInputs?.wageCents, 3000)
        for item in items {
            XCTAssertEqual(item.confidence, .missing, item.name)
            XCTAssertNil(item.confidenceRaw, item.name)
            XCTAssertNil(item.evidence, item.name); XCTAssertNil(item.checkedAt, item.name); XCTAssertNil(item.reviewDueAt, item.name)
            XCTAssertNil(item.approvedBy, item.name); XCTAssertNil(item.assumption, item.name)
            XCTAssertFalse(item.needsOwnerConfirmation, item.name)
        }
        let projects = try context.fetch(FetchDescriptor<Project>()).sorted { $0.name < $1.name }
        XCTAssertEqual(projects.map(\.name), ["Oak removal", "Palm install"])
        XCTAssertEqual(projects[0].lines.count, 25)
        XCTAssertEqual(projects[0].priceCents, 370_592, "the §3.3 job at the 50% target margin (DECISIONS 70)")
        XCTAssertEqual(projects[0].actualHours, 10)
        XCTAssertEqual(projects[0].line("Dump fee").actualQty, 3)
        XCTAssertEqual(projects[1].priceCents, 318_720, "4 h full crew with the skid steer, 6 palms, 6 stake kits, 3 yards of mulch")
        XCTAssertEqual(projects[0].unresolvedEnabledLines().count, 15, "every enabled line warns until the rows are reviewed")
        XCTAssertEqual(projects[1].unresolvedEnabledLines().count, 18)
        XCTAssertEqual(try context.fetch(FetchDescriptor<Company>()).count, 0)
        XCTAssertNil(Company.current(in: context).serviceArea)
        let readiness = Readiness(items: items, company: nil, settings: AppSettings())
        XCTAssertEqual(readiness.unresolved, [.missing: 25])
        XCTAssertEqual(readiness.status, .notReady(missingInputs: 2), "company name and service area; the rows are there")
    }

    func testReviewFieldsPersistInTheMigratedStore() throws {
        let checked = Date(timeIntervalSince1970: 1_789_536_000)
        do {
            let container = try Store.container(at: url)
            let marcus = try container.mainContext.fetch(FetchDescriptor<BucketItem>()).first { $0.name == "Marcus" }!
            marcus.evidence = "2026 payroll register"
            marcus.markChecked(now: checked)
            marcus.approvedBy = "Alexander"
            marcus.needsOwnerConfirmation = true
            XCTAssertTrue(marcus.markVerified())
            try container.mainContext.save()
        }
        let again = try Store.container(at: url)
        let marcus = try again.mainContext.fetch(FetchDescriptor<BucketItem>()).first { $0.name == "Marcus" }!
        XCTAssertEqual(marcus.confidence, .verified)
        XCTAssertEqual(marcus.evidence, "2026 payroll register")
        XCTAssertEqual(marcus.checkedAt, checked)
        XCTAssertEqual(marcus.reviewDueAt, Calendar.current.date(byAdding: .year, value: 1, to: checked))
        XCTAssertEqual(marcus.approvedBy, "Alexander")
        XCTAssertTrue(marcus.needsOwnerConfirmation)
        XCTAssertEqual(marcus.unresolvedReason(), .ownerConfirmation)
        XCTAssertEqual(try again.mainContext.fetch(FetchDescriptor<Project>()).map(\.priceCents).sorted(), [318_720, 370_592], "prices untouched")
    }
}
