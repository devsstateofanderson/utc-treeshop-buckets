import XCTest
import SwiftData
@testable import Buckets

@MainActor
final class TransferMergeTests: XCTestCase {
    func testMergeAddsUpdatesAndKeeps() throws {
        let container = try Store.inMemoryContainer()
        let context = container.mainContext
        context.insert(BucketItem(bucket: .equipment, name: "Stihl 500i", rateCents: 0, sortOrder: 0))          // typed, not priced yet
        context.insert(BucketItem(bucket: .labor, name: "Marcus", rateCents: 5408, sortOrder: 0))               // in the file: updated
        context.insert(BucketItem(bucket: .consumables, name: "Dump fee", rateCents: 7500, unit: "load", sortOrder: 0))
        try context.save()

        let file = """
        {"formatVersion": 1, "exportedAt": "2026-09-15T00:00:00Z",
         "settings": {"billableHoursPerYear": 1500, "laborBurdenPct": 30, "markupPct": 35, "minimumJobCents": 75000, "costOfMoneyPct": 0},
         "items": [
           {"bucket": "equipment", "name": "STIHL  500i", "rateCents": 325, "unit": "hr", "isActive": true, "source": null, "notes": "3 units", "calcInputs": {"priceCents": 160000, "salvageCents": 20000, "lifeHours": 2000, "annualHours": 500, "fuelOilPerHourCents": 150, "repairFactor": 2.5, "insurancePerYearCents": 0, "costOfMoneyPct": 0}, "sortOrder": 9},
           {"bucket": "labor", "name": "marcus", "rateCents": 9999, "unit": "hr", "isActive": true, "source": null, "notes": null, "calcInputs": null, "sortOrder": 0},
           {"bucket": "materials", "name": "Mulch", "rateCents": 3200, "unit": "yard", "isActive": true, "source": "Home Depot", "notes": null, "calcInputs": null, "sortOrder": 0},
           {"bucket": "consumables", "name": "Dump fee", "rateCents": 1, "unit": "load", "isActive": true, "source": null, "notes": null, "calcInputs": null, "sortOrder": 0}
         ],
         "projects": [{"name": "ignored", "client": null, "date": "2026-01-01T00:00:00Z", "hours": 8, "multiplier": 1, "markupPct": 35, "minimumJobCents": 75000, "actualHours": null, "notes": null, "lines": []}]}
        """
        let result = try Transfer.mergeItems(Data(file.utf8), into: context)
        XCTAssertEqual(result, Transfer.MergeResult(added: 1, updated: 3, unchanged: 0))
        let items = try context.fetch(FetchDescriptor<BucketItem>())
        XCTAssertEqual(items.count, 4)
        let saw = items.first { $0.name == "Stihl 500i" }!
        XCTAssertEqual(saw.rateCents, 325)
        XCTAssertEqual(saw.notes, "3 units")
        XCTAssertEqual(saw.equipmentInputs?.repairFactor, Decimal(string: "2.5")!)
        XCTAssertEqual(items.first { $0.name == "Marcus" }!.rateCents, 9999)
        XCTAssertEqual(items.first { $0.name == "Dump fee" }!.rateCents, 1)
        XCTAssertEqual(items.first { $0.name == "Mulch" }!.source, "Home Depot")
        XCTAssertEqual(try context.fetch(FetchDescriptor<Project>()).count, 0)
        // Running it again changes nothing.
        XCTAssertEqual(try Transfer.mergeItems(Data(file.utf8), into: context), Transfer.MergeResult(added: 0, updated: 0, unchanged: 4))
        // A row the file does not name is never touched.
        context.insert(BucketItem(bucket: .equipment, name: "Porta Wrap", rateCents: 0, sortOrder: 5))
        try context.save()
        XCTAssertEqual(try Transfer.mergeItems(Data(file.utf8), into: context).unchanged, 4)
        XCTAssertEqual(try context.fetch(FetchDescriptor<BucketItem>()).count, 5)
    }
    // MARK: - Packages in a merge file (DECISIONS 89)

    private func row(_ bucket: String, _ name: String, _ cents: Int, _ unit: String, code: String? = nil) -> String {
        #"{"bucket": "\#(bucket)", "name": "\#(name)", "rateCents": \#(cents), "unit": "\#(unit)", "isActive": true, "source": null, "notes": null, "calcInputs": null, "sortOrder": 0\#(code.map { #", "unitCode": "\#($0)""# } ?? "")}"#
    }

    private func line(_ index: Int?, isOn: Bool, qty: Int = 1) -> String {
        // The file's own snapshot is deliberately stale: a merge must snapshot the merged row, not the file's copy.
        #"{"itemIndex": \#(index.map(String.init) ?? "null"), "bucket": "materials", "name": "stale", "unit": "x", "rateCents": 1, "isOn": \#(isOn), "qty": \#(qty), "actualQty": null}"#
    }

    private func project(_ name: String, template: Bool?, hours: Int = 6, crew: String? = nil, notes: String? = "from the file",
                         margin: Int? = 50, markup: Int = 100, minimum: Int = 75000, lines: [String]) -> String {
        let flag = template.map { #", "isTemplate": \#($0)"# } ?? ""
        let crewKey = crew.map { #", "crewName": "\#($0)""# } ?? ""
        let notesValue = notes.map { #""\#($0)""# } ?? "null"
        let marginValue = margin.map(String.init) ?? "null"
        return #"{"name": "\#(name)", "client": null, "date": "2026-09-29T00:00:00Z", "hours": \#(hours), "multiplier": 2, "markupPct": \#(markup), "minimumJobCents": \#(minimum), "actualHours": null, "notes": \#(notesValue), "targetMarginPct": \#(marginValue), "lines": [\#(lines.joined(separator: ", "))]\#(flag)\#(crewKey)}"#
    }

    /// Company defaults that differ from every figure the test files carry, so a test can tell which one was used.
    private let company = AppSettings(billableHoursPerYear: 1500, laborBurdenPct: 30, targetMarginPct: 40,
                                      minimumJobCents: 50000, costOfMoneyPct: 0)

    private func file(items: [String], projects: [String], loadouts: String = "[]") -> Data {
        Data(#"{"formatVersion": 2, "exportedAt": "2026-09-29T00:00:00Z", "items": [\#(items.joined(separator: ", "))], "projects": [\#(projects.joined(separator: ", "))], "loadouts": \#(loadouts)}"#.utf8)
    }

    func testMergeCreatesPackagesWithLineSnapshotsAndIgnoresOrdinaryProjects() throws {
        let container = try Store.inMemoryContainer()
        let context = container.mainContext
        context.insert(BucketItem(bucket: .consumables, name: "Dump fee", rateCents: 9000, unit: "load", sortOrder: 0))
        // An ordinary project that shares a package's name is not a package and is never touched.
        let job = Project(name: "Small removal", date: Date(timeIntervalSince1970: 0), markupPct: 35, minimumJobCents: 75000)
        context.insert(job)
        job.lines = [ProjectLine(item: nil, bucket: .materials, name: "Job's own line", unit: "bag", rateCents: 1234, isOn: true, qty: 7)]
        try context.save()

        let items = [row("labor", "Crew lead", 5000, "hr"), row("equipment", "Chipper", 2500, "hr"),
                     row("materials", "Mulch", 3200, "yard"), row("consumables", "dump  FEE", 7500, "load")]
        let data = file(items: items, projects: [
            project("Small removal", template: true, crew: "Crew A",
                    lines: [line(0, isOn: true), line(1, isOn: false), line(3, isOn: true, qty: 2)]),
            project("Mulch ring", template: true, hours: 2, lines: [line(2, isOn: true, qty: 3), line(9, isOn: true), line(nil, isOn: true)]),
            project("A job", template: false, lines: [line(0, isOn: true)]),
            project("An older job", template: nil, lines: [line(0, isOn: true)]),
        ])
        let result = try Transfer.mergeItems(data, into: context, settings: company)
        XCTAssertEqual(result, Transfer.MergeResult(added: 3, updated: 1, unchanged: 0, packages: 2, packagesUpdated: 0, packageLinesSkipped: 2))

        let projects = try context.fetch(FetchDescriptor<Project>())
        XCTAssertEqual(projects.count, 3, "two packages plus the store's own project; the file's ordinary projects are ignored")
        XCTAssertEqual(job.lines.map(\.name), ["Job's own line"], "the same-named ordinary project keeps its own lines")
        XCTAssertEqual(job.lines.map(\.rateCents), [1234])
        XCTAssertEqual(job.lines.map(\.qty), [7])
        XCTAssertFalse(job.isTemplate)
        XCTAssertEqual(job.markupPct, 35)

        let removal = projects.first { $0.isTemplate && $0.name == "Small removal" }!
        XCTAssertEqual(removal.hours, 6)
        XCTAssertEqual(removal.multiplier, 2)
        XCTAssertEqual(removal.markupPct, 100)
        XCTAssertEqual(removal.targetMarginPct, 50)
        XCTAssertEqual(removal.minimumJobCents, 75000)
        XCTAssertEqual(removal.crewName, "Crew A")
        XCTAssertEqual(removal.notes, "from the file")
        let lines = removal.sortedLines
        XCTAssertEqual(lines.map(\.name), ["Crew lead", "Chipper", "Dump fee"])
        XCTAssertEqual(lines.map(\.bucket), [.labor, .equipment, .consumables])
        XCTAssertEqual(lines.map(\.unit), ["hr", "hr", "load"])
        XCTAssertEqual(lines.map(\.rateCents), [5000, 2500, 7500], "snapshots of the merged rows, the updated Dump fee included")
        XCTAssertEqual(lines.map(\.isOn), [true, false, true])
        XCTAssertEqual(lines.map(\.qty), [1, 1, 2])
        XCTAssertEqual(lines.map { $0.item?.name }, ["Crew lead", "Chipper", "Dump fee"])
        XCTAssertTrue(lines.allSatisfy { $0.actualQty == nil })

        let ring = projects.first { $0.name == "Mulch ring" }!
        XCTAssertTrue(ring.isTemplate)
        XCTAssertEqual(ring.hours, 2)
        XCTAssertNil(ring.crewName)
        XCTAssertEqual(ring.lines.map(\.name), ["Mulch"])
        XCTAssertEqual(ring.lines.map(\.unit), ["yard"])
        XCTAssertEqual(ring.lines.map(\.rateCents), [3200])
        XCTAssertEqual(ring.lines.map(\.qty), [3])
    }

    func testRemergingAPackageReplacesItRatherThanDuplicating() throws {
        let container = try Store.inMemoryContainer()
        let context = container.mainContext
        // An unrelated project with lines: the replace must delete only the matched package's lines.
        let job = Project(name: "Other job", date: Date(timeIntervalSince1970: 0), markupPct: 35, minimumJobCents: 75000)
        context.insert(job)
        job.lines = [ProjectLine(item: nil, bucket: .labor, name: "Hand", unit: "hr", rateCents: 2000, isOn: true),
                     ProjectLine(item: nil, bucket: .materials, name: "Rope", unit: "ft", rateCents: 50, isOn: true, qty: 100)]
        try context.save()
        let items = [row("labor", "Crew lead", 5000, "hr"), row("equipment", "Chipper", 2500, "hr"), row("materials", "Mulch", 3200, "yard")]
        _ = try Transfer.mergeItems(file(items: items, projects: [
            project("Small removal", template: true, crew: "Crew A", lines: [line(0, isOn: true), line(1, isOn: true), line(2, isOn: true, qty: 4)]),
        ]), into: context, settings: company)

        let changed = [row("labor", "Crew lead", 5500, "hr"), row("equipment", "Chipper", 2500, "hr"), row("materials", "Mulch", 3200, "yard")]
        let result = try Transfer.mergeItems(file(items: changed, projects: [
            project("  small   REMOVAL ", template: true, hours: 8, crew: "Crew B", notes: "second pass", margin: 45, markup: 80,
                    minimum: 90000, lines: [line(0, isOn: true), line(1, isOn: false)]),
        ]), into: context, settings: company)
        XCTAssertEqual(result.packages, 0)
        XCTAssertEqual(result.packagesUpdated, 1)
        XCTAssertEqual(result.packageLinesSkipped, 0)

        let packages = try context.fetch(FetchDescriptor<Project>()).filter(\.isTemplate)
        XCTAssertEqual(packages.count, 1)
        let package = packages[0]
        XCTAssertEqual(package.name, "Small removal", "the store's name is kept")
        XCTAssertEqual(package.hours, 8)
        XCTAssertEqual(package.crewName, "Crew B", "header fields the file carries are the file's")
        XCTAssertEqual(package.notes, "second pass")
        XCTAssertEqual(package.targetMarginPct, 45)
        XCTAssertEqual(package.markupPct, 80)
        XCTAssertEqual(package.minimumJobCents, 90000)
        XCTAssertEqual(package.sortedLines.map(\.name), ["Crew lead", "Chipper"])
        XCTAssertEqual(package.sortedLines.map(\.rateCents), [5500, 2500])
        XCTAssertEqual(package.sortedLines.map(\.isOn), [true, false])
        XCTAssertEqual(try context.fetch(FetchDescriptor<ProjectLine>()).count, 4,
                       "the replaced lines are deleted, not orphaned; the other project's two lines stay")
        XCTAssertEqual(job.lines.map(\.name).sorted(), ["Hand", "Rope"])
    }

    func testASkippedCodedDuplicateRowDoesNotShiftLoadoutOrPackageMembers() throws {
        let container = try Store.inMemoryContainer()
        let context = container.mainContext
        for code in ["SAW-01", "SAW-02"] {
            let saw = BucketItem(bucket: .equipment, name: "Stihl 500i", rateCents: 256, sortOrder: 0)
            saw.unitCode = code
            context.insert(saw)
        }
        context.insert(BucketItem(bucket: .labor, name: "Marcus", rateCents: 5408, sortOrder: 0))
        try context.save()

        // Position 0 names two coded units without a code, so it is skipped; positions 1 and 2 must still mean
        // Marcus and the Chipper.
        let items = [row("equipment", "Stihl 500i", 999, "hr"), row("labor", "Marcus", 5408, "hr"), row("equipment", "Chipper", 2500, "hr")]
        let result = try Transfer.mergeItems(file(items: items, projects: [
            project("Crew day", template: true, lines: [line(0, isOn: true), line(1, isOn: true), line(2, isOn: false, qty: 3)]),
        ], loadouts: #"[{"name": "Chipper crew", "notes": null, "sortOrder": 0, "memberIndexes": [1, 2]}]"#), into: context,
           settings: company)
        XCTAssertEqual(result.added, 1)
        XCTAssertEqual(result.unchanged, 2)
        XCTAssertEqual(result.loadouts, 1)
        XCTAssertEqual(result.packages, 1)
        XCTAssertEqual(result.packageLinesSkipped, 1)

        let loadout = try context.fetch(FetchDescriptor<Loadout>())[0]
        XCTAssertEqual(Set(loadout.members.map(\.name)), ["Marcus", "Chipper"])
        let package = try context.fetch(FetchDescriptor<Project>())[0]
        XCTAssertEqual(package.sortedLines.map(\.name), ["Marcus", "Chipper"])
        XCTAssertEqual(package.sortedLines.map(\.rateCents), [5408, 2500])
        XCTAssertEqual(package.sortedLines.map(\.isOn), [true, false])
        XCTAssertEqual(package.sortedLines.map(\.qty), [1, 3])
        let saws = try context.fetch(FetchDescriptor<BucketItem>()).filter { $0.name == "Stihl 500i" }
        XCTAssertEqual(saws.map(\.rateCents), [256, 256], "the skipped row changes neither unit")
    }

    func testAnUpdateLeavesTheStoresHeaderFieldsAloneWhereTheFileHasNil() throws {
        let container = try Store.inMemoryContainer()
        let context = container.mainContext
        let items = [row("labor", "Crew lead", 5000, "hr")]
        _ = try Transfer.mergeItems(file(items: items, projects: [
            project("Small removal", template: true, crew: "Crew A", notes: "keep me", margin: 55, lines: [line(0, isOn: true)]),
        ]), into: context, settings: company)

        let result = try Transfer.mergeItems(file(items: items, projects: [
            project("Small removal", template: true, hours: 9, crew: nil, notes: nil, margin: nil, markup: 70, minimum: 80000,
                    lines: [line(0, isOn: false)]),
        ]), into: context, settings: company)
        XCTAssertEqual(result.packagesUpdated, 1)
        let package = try context.fetch(FetchDescriptor<Project>())[0]
        XCTAssertEqual(package.crewName, "Crew A", "nil leaves the store's value alone, as rows and the company profile do")
        XCTAssertEqual(package.notes, "keep me")
        XCTAssertEqual(package.targetMarginPct, 55)
        XCTAssertEqual(package.hours, 9, "required fields are always the file's")
        XCTAssertEqual(package.markupPct, 70)
        XCTAssertEqual(package.minimumJobCents, 80000)
        XCTAssertEqual(package.sortedLines.map(\.isOn), [false])
    }

    func testANewPackageWithoutAMarginTakesTheCompanyDefaults() throws {
        let container = try Store.inMemoryContainer()
        let context = container.mainContext
        let result = try Transfer.mergeItems(file(items: [row("labor", "Crew lead", 5000, "hr")], projects: [
            project("Old style", template: true, margin: nil, markup: 35, minimum: 75000, lines: [line(0, isOn: true)]),
        ]), into: context, settings: company)
        XCTAssertEqual(result.packages, 1)
        let package = try context.fetch(FetchDescriptor<Project>())[0]
        XCTAssertEqual(package.targetMarginPct, 40, "priced by the company margin (DECISIONS 70), not the legacy markup rule")
        XCTAssertEqual(package.minimumJobCents, 50000)
        XCTAssertEqual(package.markupPct, Project.rounded2(company.pricingRule.markupPercent))
        XCTAssertEqual(package.pricingRule, company.pricingRule)
    }

    func testAPackageNameMatchingSeveralStorePackagesIsSkippedAndCounted() throws {
        let container = try Store.inMemoryContainer()
        let context = container.mainContext
        for hours: Decimal in [3, 4] {
            let package = Project(name: "Small removal", date: Date(timeIntervalSince1970: 0), hours: hours, markupPct: 35,
                                  minimumJobCents: 75000)
            package.isTemplate = true
            context.insert(package)
            package.lines = [ProjectLine(item: nil, bucket: .labor, name: "Hand", unit: "hr", rateCents: 2000, isOn: true)]
        }
        try context.save()

        let result = try Transfer.mergeItems(file(items: [row("labor", "Crew lead", 5000, "hr")], projects: [
            project("small removal", template: true, hours: 9, lines: [line(0, isOn: true), line(7, isOn: true)]),
            project("Stump grind", template: true, lines: [line(0, isOn: true)]),
        ]), into: context, settings: company)
        XCTAssertEqual(result.packagesSkipped, 1)
        XCTAssertEqual(result.packagesUpdated, 0)
        XCTAssertEqual(result.packages, 1, "the unambiguous package still merges")
        XCTAssertEqual(result.packageLinesSkipped, 0, "a skipped package's lines are not counted")
        let packages = try context.fetch(FetchDescriptor<Project>()).filter { $0.name == "Small removal" }
        XCTAssertEqual(packages.map(\.hours).sorted(), [3, 4], "neither same-named package is touched")
        XCTAssertTrue(packages.allSatisfy { $0.lines.map(\.name) == ["Hand"] })
        XCTAssertEqual(try context.fetch(FetchDescriptor<ProjectLine>()).count, 3)
    }

    func testAPackageLineToARowTheSameFileArchivesIsKeptAndLinked() throws {
        let container = try Store.inMemoryContainer()
        let context = container.mainContext
        let old = BucketItem(bucket: .equipment, name: "Old chipper", rateCents: 1800, sortOrder: 0)
        context.insert(old)
        try context.save()
        let archived = #"{"bucket": "equipment", "name": "Old chipper", "rateCents": 1800, "unit": "hr", "isActive": false, "source": null, "notes": null, "calcInputs": null, "sortOrder": 0}"#
        let result = try Transfer.mergeItems(file(items: [archived], projects: [
            project("Chip day", template: true, lines: [line(0, isOn: true)]),
        ]), into: context, settings: company)
        XCTAssertEqual(result.updated, 1)
        XCTAssertFalse(old.isActive)
        let package = try context.fetch(FetchDescriptor<Project>())[0]
        XCTAssertEqual(package.sortedLines.map(\.name), ["Old chipper"], "kept and linked, as Duplicate keeps archived rows")
        XCTAssertEqual(package.sortedLines.first?.item?.name, "Old chipper")
        XCTAssertEqual(package.sortedLines.map(\.rateCents), [1800])
    }
}
