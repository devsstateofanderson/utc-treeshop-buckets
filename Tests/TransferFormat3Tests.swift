import XCTest
import SwiftData
@testable import Buckets

/// Export/import format 3 (DECISIONS 95): the sales allowance, the payroll tax on commission, track-only rows, a row's
/// commission % and a project's sale terms round-trip; format 2 files read with the fields empty and the defaults; a
/// 0.2.3 app refuses the file rather than drop the allowance and price lower; the merge sets `trackOnly` and never
/// clears it. Synthetic people and rates.
@MainActor
final class TransferFormat3Tests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext { container.mainContext }
    private let stamp = Date(timeIntervalSince1970: 1_750_000_000)
    private var sam: BucketItem!

    override func setUp() async throws {
        container = try Store.inMemoryContainer()
        StoreFixture.insertRows(into: context)
        sam = BucketItem(bucket: .labor, name: "Sam Rivera", rateCents: 4000, sortOrder: 3)
        sam.trackOnly = true
        sam.commissionPct = 7
        context.insert(sam)
        try context.save()
    }

    private var allowance: AppSettings {
        var s = AppSettings(); s.salesAllowancePct = 7; s.commissionBurdenPct = 8; return s
    }

    private static let format2Settings =
        #""settings": {"billableHoursPerYear": 1500, "laborBurdenPct": 30, "markupPct": 100, "minimumJobCents": 75000, "costOfMoneyPct": 0, "targetMarginPct": 50}"#

    func testRoundTripOfEveryNewKey() throws {
        let job = Project.make(name: "Job", date: stamp, items: try StoreFixture.items(in: context), settings: allowance)
        job.hours = 8
        context.insert(job)
        job.setSalesperson(sam)
        job.commissionPctOverride = 10
        let package = Project.make(name: "Package", date: stamp, items: try StoreFixture.items(in: context), settings: allowance)
        package.isTemplate = true
        context.insert(package)
        try context.save()

        let data = try Transfer.exportJSON(from: context, settings: allowance, exportedAt: stamp)
        let text = String(decoding: data, as: UTF8.self)
        XCTAssertTrue(text.contains("\"formatVersion\" : 3"))
        XCTAssertTrue(text.contains("\"salesAllowancePct\" : 7"))
        XCTAssertTrue(text.contains("\"commissionBurdenPct\" : 8"))
        XCTAssertTrue(text.contains("\"trackOnly\" : true"))
        XCTAssertFalse(text.contains("\"trackOnly\" : false"), "written only when set")
        XCTAssertTrue(text.contains("\"salespersonName\" : \"Sam Rivera\""))
        XCTAssertTrue(text.contains("\"commissionPctOverride\" : 10"))
        let doc = try Transfer.decoder().decode(TransferDocument.self, from: data)
        XCTAssertEqual(doc.settings?.salesAllowancePct, 7)
        XCTAssertEqual(doc.settings?.commissionBurdenPct, 8)
        let samIndex = doc.items.firstIndex { $0.name == "Sam Rivera" }
        XCTAssertEqual(doc.items[samIndex!].commissionPct, 7)
        let jobRecord = doc.projects.first { $0.name == "Job" }!
        XCTAssertEqual(jobRecord.salespersonIndex, samIndex)
        XCTAssertEqual(jobRecord.commissionPct, 7)
        XCTAssertEqual(jobRecord.salesAllowancePct, 7)
        XCTAssertEqual(jobRecord.commissionBurdenPct, 8)
        let packageRecord = doc.projects.first { $0.name == "Package" }!
        XCTAssertNil(packageRecord.salespersonIndex); XCTAssertNil(packageRecord.salespersonName)
        XCTAssertEqual(packageRecord.salesAllowancePct, 7)

        let second = try Store.inMemoryContainer()
        let settings = try Transfer.importJSON(data, into: second.mainContext)
        XCTAssertEqual(settings.salesAllowancePct, 7)
        XCTAssertEqual(settings.commissionBurdenPct, 8)
        let back = try second.mainContext.fetch(FetchDescriptor<Project>()).first { $0.name == "Job" }!
        XCTAssertEqual(back.salesperson?.name, "Sam Rivera")
        XCTAssertEqual(back.salespersonName, "Sam Rivera")
        XCTAssertEqual(back.commissionPct, 7)
        XCTAssertEqual(back.commissionPctOverride, 10)
        XCTAssertEqual(back.salesAllowancePct, 7)
        XCTAssertEqual(back.commissionBurdenPct, 8)
        XCTAssertEqual(back.breakdown(billableHours: 1500), job.breakdown(billableHours: 1500))
        let row = try second.mainContext.fetch(FetchDescriptor<BucketItem>()).first { $0.name == "Sam Rivera" }!
        XCTAssertTrue(row.trackOnly)
        XCTAssertEqual(row.commissionPct, 7)
        XCTAssertEqual(row.soldProjects.count, 1)
        let again = try Transfer.exportJSON(from: second.mainContext, settings: settings, exportedAt: stamp)
        XCTAssertEqual(String(decoding: again, as: UTF8.self), text)
    }

    func testSettingsAlwaysCarryTheTwoKeys() throws {
        let text = String(decoding: try Transfer.exportJSON(from: context, settings: AppSettings(), exportedAt: stamp), as: UTF8.self)
        XCTAssertTrue(text.contains("\"salesAllowancePct\" : 0"), "written at 0, as every setting is (76)")
        XCTAssertTrue(text.contains("\"commissionBurdenPct\" : 7.65"))
    }

    func testFormat2FilesReadWithTheFieldsEmptyAndTheDefaults() throws {
        let older = """
        {"formatVersion": 2, "exportedAt": "2026-09-30T00:00:00Z", \(Self.format2Settings),
         "items": [{"bucket": "labor", "name": "Lee", "rateCents": 3500, "unit": "hr", "isActive": true, "sortOrder": 0}],
         "projects": [{"name": "Old", "date": "2026-09-01T00:00:00Z", "hours": 8, "multiplier": 1, "markupPct": 100, "minimumJobCents": 75000,
                       "targetMarginPct": 50, "lines": [{"itemIndex": 0, "bucket": "labor", "name": "Lee", "unit": "hr", "rateCents": 3500, "isOn": true, "qty": 1}]}]}
        """
        let fresh = try Store.inMemoryContainer()
        let settings = try Transfer.importJSON(Data(older.utf8), into: fresh.mainContext)
        XCTAssertEqual(settings.salesAllowancePct, 0)
        XCTAssertEqual(settings.commissionBurdenPct, 7.65)
        let project = try fresh.mainContext.fetch(FetchDescriptor<Project>())[0]
        XCTAssertNil(project.salesAllowancePct); XCTAssertNil(project.commissionBurdenPct)
        XCTAssertNil(project.salesperson); XCTAssertNil(project.salespersonName)
        XCTAssertNil(project.commissionPct); XCTAssertNil(project.commissionPctOverride)
        XCTAssertEqual(project.priceCents, 75_000, "8 × 35.00 = 280.00 × 2 = 560.00, under the floor")
        let row = try fresh.mainContext.fetch(FetchDescriptor<BucketItem>())[0]
        XCTAssertFalse(row.trackOnly)
        XCTAssertNil(row.commissionPct)
        // Re-exported as format 3 with no project key it did not have.
        let text = String(decoding: try Transfer.exportJSON(from: fresh.mainContext, settings: settings, exportedAt: stamp), as: UTF8.self)
        XCTAssertTrue(text.contains("\"formatVersion\" : 3"))
        XCTAssertFalse(text.contains("salespersonName"))
        XCTAssertFalse(text.contains("\"trackOnly\""))
        XCTAssertEqual(text.components(separatedBy: "salesAllowancePct").count - 1, 1, "only the settings carry it")
    }

    /// Mirrors DECISIONS 74's test: an app that reads formats 1 to 2 (0.2.3) refuses this app's export, because it
    /// would drop `salesAllowancePct` and price lower. This app reads 1 to 3 and refuses 4.
    func testAnOlderAppRefusesFormat3AndThisAppRefusesFormat4() throws {
        let data = try Transfer.exportJSON(from: context, settings: allowance, exportedAt: stamp)
        let doc = try Transfer.decoder().decode(TransferDocument.self, from: data)
        let readBy023 = 1...2
        XCTAssertFalse(readBy023.contains(doc.formatVersion), "a 0.2.3-shaped reader refuses the file")
        XCTAssertEqual(TransferDocument.currentFormatVersion, 3)
        XCTAssertEqual(TransferDocument.readableFormatVersions, 1...3)
        let newer = """
        {"formatVersion": 4, "exportedAt": "2026-01-01T00:00:00Z", \(Self.format2Settings), "items": [], "projects": []}
        """
        XCTAssertThrowsError(try Transfer.importJSON(Data(newer.utf8), into: context)) { error in
            XCTAssertEqual(error as? TransferError, .unsupportedFormat(4))
            XCTAssertEqual(error.localizedDescription, "This file is Buckets format 4; this app reads formats 1 to 3.")
        }
        XCTAssertThrowsError(try Transfer.mergeItems(Data(newer.utf8), into: context))
    }

    /// DECISIONS 94, 95: a `salespersonIndex` outside `items` is refused like a bad line index, and one that points at a
    /// row outside Labor is refused too; either way the store is left as it was.
    func testABadOrNonLaborSalespersonIndexIsRefused() throws {
        func file(_ index: Int) -> Data {
            Data("""
            {"formatVersion": 3, "exportedAt": "2026-09-30T00:00:00Z", \(Self.format2Settings),
             "items": [{"bucket": "labor", "name": "Lee", "rateCents": 3500, "unit": "hr", "isActive": true, "sortOrder": 0},
                       {"bucket": "equipment", "name": "Chipper", "rateCents": 2500, "unit": "hr", "isActive": true, "sortOrder": 0}],
             "projects": [{"name": "Job", "date": "2026-09-01T00:00:00Z", "hours": 8, "multiplier": 1, "markupPct": 100, "minimumJobCents": 75000,
                           "targetMarginPct": 50, "salespersonIndex": \(index), "salespersonName": "Lee", "lines": []}]}
            """.utf8)
        }
        let before = try context.fetch(FetchDescriptor<BucketItem>()).count
        XCTAssertThrowsError(try Transfer.importJSON(file(2), into: context)) { error in
            XCTAssertEqual(error as? TransferError, .badItemIndex(2))
        }
        XCTAssertThrowsError(try Transfer.importJSON(file(-1), into: context)) { error in
            XCTAssertEqual(error as? TransferError, .badItemIndex(-1))
        }
        XCTAssertThrowsError(try Transfer.importJSON(file(1), into: context)) { error in
            XCTAssertEqual(error as? TransferError, .salespersonNotLabor(1))
            XCTAssertEqual(error.localizedDescription, "A project names row #1 as its salesperson, which is not a Labor row.")
        }
        XCTAssertEqual(try context.fetch(FetchDescriptor<BucketItem>()).count, before, "refused before anything is deleted")

        XCTAssertNoThrow(try Transfer.importJSON(file(0), into: context))
        XCTAssertEqual(try context.fetch(FetchDescriptor<Project>())[0].salesperson?.name, "Lee")
    }

    /// DECISIONS 95: until Equipment has its own "Track only" toggle, a file cannot set the flag on a row outside Labor,
    /// because 0.2.4 offers no way to clear it there. Import and merge both ignore it.
    func testTrackOnlyFromAFileAppliesToLaborRowsOnly() throws {
        let file = Data("""
        {"formatVersion": 3, "exportedAt": "2026-09-30T00:00:00Z", \(Self.format2Settings),
         "items": [{"bucket": "equipment", "name": "Chipper", "rateCents": 2500, "unit": "hr", "isActive": true, "sortOrder": 0, "trackOnly": true},
                   {"bucket": "labor", "name": "Lee", "rateCents": 3500, "unit": "hr", "isActive": true, "sortOrder": 0, "trackOnly": true}],
         "projects": []}
        """.utf8)
        let fresh = try Store.inMemoryContainer()
        _ = try Transfer.importJSON(file, into: fresh.mainContext)
        let restored = try fresh.mainContext.fetch(FetchDescriptor<BucketItem>())
        XCTAssertFalse(restored.first { $0.name == "Chipper" }!.trackOnly)
        XCTAssertTrue(restored.first { $0.name == "Lee" }!.trackOnly)

        let result = try Transfer.mergeItems(file, into: context)
        let merged = try StoreFixture.items(in: context)
        XCTAssertFalse(merged.first { $0.name == "Chipper" }!.trackOnly, "a new equipment row stays priced")
        XCTAssertTrue(merged.first { $0.name == "Lee" }!.trackOnly)
        XCTAssertEqual(result.added, 2)
        let again = try Transfer.mergeItems(file, into: context)
        XCTAssertEqual(again.updated, 0, "the ignored flag never counts as a change")
        XCTAssertEqual(again.unchanged, 2)
    }

    func testMergeSetsTrackOnlyNeverClearsItAndAppliesTheCommissionPct() throws {
        let marcusFile = """
        {"formatVersion": 3, "exportedAt": "2026-09-30T00:00:00Z",
         "items": [{"bucket": "labor", "name": "Marcus", "rateCents": 5408, "unit": "hr", "isActive": true, "sortOrder": 0, "trackOnly": true, "commissionPct": 5},
                   {"bucket": "labor", "name": "Sam Rivera", "rateCents": 4000, "unit": "hr", "isActive": true, "sortOrder": 3}],
         "projects": []}
        """
        var result = try Transfer.mergeItems(Data(marcusFile.utf8), into: context)
        let marcus = try StoreFixture.items(in: context).first { $0.name == "Marcus" }!
        XCTAssertTrue(marcus.trackOnly)
        XCTAssertEqual(marcus.commissionPct, 5)
        XCTAssertTrue(sam.trackOnly, "a file without the key never clears it")
        XCTAssertEqual(sam.commissionPct, 7, "nor the %")
        XCTAssertEqual(result.updated, 1)
        XCTAssertEqual(result.unchanged, 1)
        result = try Transfer.mergeItems(Data(marcusFile.utf8), into: context)
        XCTAssertEqual(result.updated, 0, "a second run changes nothing")
        XCTAssertEqual(result.unchanged, 2)

        let clearing = """
        {"formatVersion": 3, "exportedAt": "2026-09-30T00:00:00Z",
         "items": [{"bucket": "labor", "name": "Sam Rivera", "rateCents": 4000, "unit": "hr", "isActive": true, "sortOrder": 3, "trackOnly": false, "commissionPct": 8},
                   {"bucket": "labor", "name": "Jo Park", "rateCents": 3800, "unit": "hr", "isActive": true, "sortOrder": 4, "trackOnly": true, "commissionPct": 6}],
         "projects": []}
        """
        result = try Transfer.mergeItems(Data(clearing.utf8), into: context)
        XCTAssertTrue(sam.trackOnly, "false never clears it")
        XCTAssertEqual(sam.commissionPct, 8)
        let jo = try StoreFixture.items(in: context).first { $0.name == "Jo Park" }!
        XCTAssertTrue(jo.trackOnly, "a new row takes the file's flag")
        XCTAssertEqual(jo.commissionPct, 6)
        XCTAssertEqual(result.added, 1)
    }

    func testMergedPackagesTakeTheAllowanceByDecision89sRule() throws {
        var company = AppSettings(); company.salesAllowancePct = 7
        let file = """
        {"formatVersion": 3, "exportedAt": "2026-09-30T00:00:00Z",
         "items": [{"bucket": "labor", "name": "Sam Rivera", "rateCents": 4000, "unit": "hr", "isActive": true, "sortOrder": 3, "trackOnly": true},
                   {"bucket": "labor", "name": "Marcus", "rateCents": 5408, "unit": "hr", "isActive": true, "sortOrder": 0}],
         "projects": [
           {"name": "With keys", "date": "2026-09-30T00:00:00Z", "hours": 8, "multiplier": 1, "markupPct": 100, "minimumJobCents": 75000, "isTemplate": true,
            "targetMarginPct": 50, "salesAllowancePct": 5, "commissionBurdenPct": 9, "salespersonIndex": 0, "salespersonName": "Sam Rivera", "commissionPctOverride": 12,
            "lines": [{"itemIndex": 0, "bucket": "labor", "name": "Sam Rivera", "unit": "hr", "rateCents": 4000, "isOn": false, "qty": 1},
                      {"itemIndex": 1, "bucket": "labor", "name": "Marcus", "unit": "hr", "rateCents": 5408, "isOn": true, "qty": 1}]},
           {"name": "Without keys", "date": "2026-09-30T00:00:00Z", "hours": 8, "multiplier": 1, "markupPct": 100, "minimumJobCents": 75000, "isTemplate": true,
            "targetMarginPct": 50,
            "lines": [{"itemIndex": 0, "bucket": "labor", "name": "Sam Rivera", "unit": "hr", "rateCents": 4000, "isOn": true, "qty": 1}]}]}
        """
        XCTAssertEqual(try Transfer.mergeItems(Data(file.utf8), into: context, settings: company).packages, 2)
        let packages = try context.fetch(FetchDescriptor<Project>()).filter(\.isTemplate)
        let with = packages.first { $0.name == "With keys" }!
        XCTAssertEqual(with.salesAllowancePct, 5, "the file's value when present")
        XCTAssertEqual(with.commissionBurdenPct, 9)
        XCTAssertNil(with.salesperson, "packages never carry a salesperson")
        XCTAssertNil(with.salespersonName); XCTAssertNil(with.commissionPctOverride)
        XCTAssertFalse(with.line("Sam Rivera").isOn)
        let without = packages.first { $0.name == "Without keys" }!
        XCTAssertEqual(without.salesAllowancePct, 7, "company defaults on create")
        XCTAssertEqual(without.commissionBurdenPct, Decimal(string: "7.65")!)
        XCTAssertTrue(without.line("Sam Rivera").isOn, "a package line for a track-only row merges with isOn from the file")

        // On update a missing key leaves the store's value alone; a present one replaces it.
        with.salesAllowancePct = 3
        let update = """
        {"formatVersion": 3, "exportedAt": "2026-09-30T00:00:00Z", "items": [],
         "projects": [{"name": "With keys", "date": "2026-09-30T00:00:00Z", "hours": 6, "multiplier": 1, "markupPct": 100, "minimumJobCents": 75000,
                       "isTemplate": true, "lines": []},
                      {"name": "Without keys", "date": "2026-09-30T00:00:00Z", "hours": 6, "multiplier": 1, "markupPct": 100, "minimumJobCents": 75000,
                       "isTemplate": true, "salesAllowancePct": 0, "lines": []}]}
        """
        XCTAssertEqual(try Transfer.mergeItems(Data(update.utf8), into: context, settings: company).packagesUpdated, 2)
        XCTAssertEqual(with.salesAllowancePct, 3)
        XCTAssertEqual(with.commissionBurdenPct, 9)
        XCTAssertEqual(without.salesAllowancePct, 0)
    }
}
