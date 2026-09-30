import XCTest
import SwiftData
@testable import Buckets

/// A merge file can remove or archive a subcontractor (DECISIONS 91).
@MainActor
final class SubcontractorMergeRemovalTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext { container.mainContext }

    override func setUp() async throws {
        container = try Store.inMemoryContainer()
    }

    /// "Stump Co" with two services, both active.
    @discardableResult
    private func addSub(_ name: String = "Stump Co") throws -> (Subcontractor, BucketItem, BucketItem) {
        let sub = Subcontractor(name: name, contact: "Dispatch", sortOrder: 0)
        context.insert(sub)
        let stump = BucketItem(bucket: .subcontractors, name: "Stump grinding", rateCents: 9000, unit: "stump", sortOrder: 0)
        let travel = BucketItem(bucket: .subcontractors, name: "Travel", rateCents: 5000, unit: "trip", sortOrder: 1)
        stump.subcontractor = sub; travel.subcontractor = sub
        context.insert(stump); context.insert(travel)
        try context.save()
        return (sub, stump, travel)
    }

    /// `subRecord` is the JSON body of one subcontractor record; `items` are rows, optionally under file sub 0.
    private func file(subs: [String], items: [String] = []) -> Data {
        Data(#"{"formatVersion": 2, "exportedAt": "2026-09-30T00:00:00Z", "subcontractors": [\#(subs.joined(separator: ", "))], "items": [\#(items.joined(separator: ", "))], "projects": []}"#.utf8)
    }

    private func sub(_ name: String, active: Bool = true, remove: Bool? = nil) -> String {
        #"{"name": "\#(name)", "contact": null, "phone": null, "email": null, "notes": null, "isActive": \#(active), "sortOrder": 0\#(remove.map { #", "remove": \#($0)"# } ?? "")}"#
    }

    private func service(_ name: String, cents: Int, subIndex: Int = 0) -> String {
        #"{"bucket": "subcontractors", "name": "\#(name)", "rateCents": \#(cents), "unit": "each", "isActive": true, "source": null, "notes": null, "calcInputs": null, "sortOrder": 0, "subcontractorIndex": \#(subIndex)}"#
    }

    private var subs: [Subcontractor] { (try? context.fetch(FetchDescriptor<Subcontractor>())) ?? [] }
    private var services: [BucketItem] {
        ((try? context.fetch(FetchDescriptor<BucketItem>())) ?? []).filter { $0.bucket == .subcontractors }
    }

    func testRemoveDeletesAnUnreferencedSubAndItsServices() throws {
        try addSub()
        let (craneCo, _, _) = try addSub("Crane Co")
        context.insert(BucketItem(bucket: .consumables, name: "Dump fee", rateCents: 7500, unit: "load", sortOrder: 0))
        try context.save()
        // The whitespace and case differ: names match as rows do. The service row under it is skipped, not re-created.
        let result = try Transfer.mergeItems(file(subs: [sub("stump  co", remove: true)], items: [service("Stump grinding", cents: 9000)]),
                                             into: context)
        XCTAssertEqual(result.subcontractorsRemoved, 1)
        XCTAssertEqual(result.subcontractorsArchived, 0)
        XCTAssertEqual(result.added, 0)
        XCTAssertEqual(subs.map(\.name), ["Crane Co"], "only the named sub is deleted")
        XCTAssertTrue(craneCo.isActive)
        XCTAssertEqual(services.count, 2, "only the removed sub's services cascade")
        XCTAssertTrue(services.allSatisfy { $0.subcontractor === craneCo && $0.isActive })
        XCTAssertEqual(try context.fetch(FetchDescriptor<BucketItem>()).filter { $0.bucket != .subcontractors }.map(\.name), ["Dump fee"],
                       "other rows are untouched")
        // Merging it again is a no-op.
        let again = try Transfer.mergeItems(file(subs: [sub("Stump Co", remove: true)]), into: context)
        XCTAssertEqual(again, Transfer.MergeResult())
    }

    func testRemoveArchivesASubWhoseServiceIsOnAProjectAndTheLineKeepsItsSnapshot() throws {
        let (stumpCo, stump, travel) = try addSub()
        let project = Project(name: "Oak removal", date: Date(timeIntervalSince1970: 0), markupPct: 35, minimumJobCents: 75000)
        context.insert(project)
        let line = ProjectLine(item: stump, bucket: .subcontractors, name: stump.name, unit: stump.unit, rateCents: stump.rateCents,
                               isOn: true, qty: 3)
        project.lines = [line]
        try context.save()
        let priceBefore = project.priceCents

        let result = try Transfer.mergeItems(file(subs: [sub("Stump Co", remove: true)]), into: context)
        XCTAssertEqual(result.subcontractorsRemoved, 0)
        XCTAssertEqual(result.subcontractorsArchived, 1)
        XCTAssertEqual(subs.count, 1)
        XCTAssertFalse(stumpCo.isActive)
        XCTAssertFalse(stump.isActive)
        XCTAssertFalse(travel.isActive, "archiving a sub archives all its services")
        XCTAssertEqual(services.count, 2, "nothing is deleted while a project references the sub")
        XCTAssertTrue(line.item === stump)
        XCTAssertEqual(line.name, "Stump grinding")
        XCTAssertEqual(line.rateCents, 9000)
        XCTAssertEqual(line.qty, 3)
        XCTAssertTrue(line.isOn)
        XCTAssertEqual(project.priceCents, priceBefore)
        // Already archived: a second pass counts nothing.
        XCTAssertEqual(try Transfer.mergeItems(file(subs: [sub("Stump Co", remove: true)]), into: context).subcontractorsArchived, 0)
    }

    func testIsActiveFalseArchivesAnExistingSubAndNeverUnarchives() throws {
        let (stumpCo, stump, _) = try addSub()
        let result = try Transfer.mergeItems(file(subs: [sub("Stump Co", active: false)], items: [service("Stump grinding", cents: 9000),
                                                                                              service("Haul-off", cents: 4000)]),
                                             into: context)
        XCTAssertEqual(result.subcontractorsArchived, 1)
        XCTAssertEqual(result.subcontractorsRemoved, 0)
        XCTAssertFalse(stumpCo.isActive)
        XCTAssertFalse(stump.isActive)
        let haul = try XCTUnwrap(services.first { $0.name == "Haul-off" })
        XCTAssertTrue(haul.subcontractor === stumpCo)
        XCTAssertFalse(haul.isActive, "a service added under a sub the file archives is added archived")
        XCTAssertEqual(subs.count, 1)
        // A later file with the sub active does not bring it back (DECISIONS 55).
        let back = try Transfer.mergeItems(file(subs: [sub("Stump Co", active: true)], items: [service("Stump grinding", cents: 9000)]),
                                           into: context)
        XCTAssertEqual(back.subcontractorsArchived, 0)
        XCTAssertFalse(stumpCo.isActive)
        XCTAssertFalse(stump.isActive)
    }

    func testANewSubTheFileAddsArchivedHasItsNewServicesArchived() throws {
        let result = try Transfer.mergeItems(file(subs: [sub("Crane Co", active: false)], items: [service("Crane day", cents: 180_000)]),
                                             into: context)
        XCTAssertEqual(result.subcontractors, 1)
        XCTAssertEqual(result.added, 1)
        let craneCo = try XCTUnwrap(subs.first)
        XCTAssertFalse(craneCo.isActive)
        let day = try XCTUnwrap(services.first { $0.name == "Crane day" })
        XCTAssertTrue(day.subcontractor === craneCo)
        XCTAssertFalse(day.isActive, "a sub's services follow the sub")
    }

    /// Rows under a removed or unknown sub hold their file positions, so a loadout member or package line that points past
    /// them still resolves to the row it names (the class of misalignment DECISIONS 89 fixed).
    func testSkippedRowsHoldTheirPositionsForLoadoutsAndPackages() throws {
        try addSub()
        let rope = BucketItem(bucket: .consumables, name: "Rope", rateCents: 1200, unit: "ft", sortOrder: 0)
        context.insert(rope)
        try context.save()
        let ropeRow = #"{"bucket": "consumables", "name": "Rope", "rateCents": 1300, "unit": "ft", "isActive": true, "source": null, "notes": null, "calcInputs": null, "sortOrder": 0}"#
        let chips = #"{"bucket": "consumables", "name": "Chip dump", "rateCents": 4000, "unit": "load", "isActive": true, "source": null, "notes": null, "calcInputs": null, "sortOrder": 1}"#
        func line(_ index: Int) -> String {
            #"{"itemIndex": \#(index), "bucket": "consumables", "name": "stale", "unit": "x", "rateCents": 1, "isOn": true, "qty": 2, "actualQty": null}"#
        }
        let package = #"{"name": "Climb day", "client": null, "date": "2026-09-30T00:00:00Z", "hours": 8, "multiplier": 2, "markupPct": 100, "minimumJobCents": 75000, "actualHours": null, "notes": null, "targetMarginPct": 50, "isTemplate": true, "lines": [\#(line(0)), \#(line(2)), \#(line(3))]}"#
        // File positions: 0 under the removed Stump Co, 1 under the unknown Crane Co, 2 Rope, 3 Chip dump.
        let data = Data(#"{"formatVersion": 2, "exportedAt": "2026-09-30T00:00:00Z", "subcontractors": [\#(sub("Stump Co", remove: true)), \#(sub("Crane Co", remove: true))], "items": [\#(service("Stump grinding", cents: 9000)), \#(service("Crane day", cents: 180_000, subIndex: 1)), \#(ropeRow), \#(chips)], "projects": [\#(package)], "loadouts": [{"name": "Climb kit", "notes": null, "sortOrder": 0, "memberIndexes": [0, 2, 3]}]}"#.utf8)

        let result = try Transfer.mergeItems(data, into: context)
        XCTAssertEqual(result.subcontractorsRemoved, 1)
        XCTAssertEqual(result.unchanged, 2, "both rows under the removed and unknown subs are skipped")
        XCTAssertEqual(result.updated, 1)
        XCTAssertEqual(result.added, 1)
        XCTAssertEqual(result.packageLinesSkipped, 1)
        XCTAssertEqual(rope.rateCents, 1300)
        let kit = try XCTUnwrap(try context.fetch(FetchDescriptor<Loadout>()).first)
        XCTAssertEqual(Set(kit.members.map(\.name)), ["Rope", "Chip dump"])
        let climb = try XCTUnwrap(try context.fetch(FetchDescriptor<Project>()).first { $0.isTemplate })
        XCTAssertEqual(Set(climb.lines.map(\.name)), ["Rope", "Chip dump"])
        XCTAssertTrue(climb.lines.contains { $0.item === rope && $0.rateCents == 1300 })
    }

    func testARemoveForAnUnknownNameCreatesNothing() throws {
        try addSub()
        let result = try Transfer.mergeItems(file(subs: [sub("Crane Co", remove: true)], items: [service("Crane day", cents: 180_000)]),
                                             into: context)
        XCTAssertEqual(result.subcontractors, 0)
        XCTAssertEqual(result.subcontractorsRemoved, 0)
        XCTAssertEqual(result.subcontractorsArchived, 0)
        XCTAssertEqual(result.added, 0, "a service under a sub that is never created is skipped")
        XCTAssertEqual(subs.map(\.name), ["Stump Co"])
        XCTAssertNil(services.first { $0.name == "Crane day" })
        XCTAssertTrue(subs[0].isActive)
    }

    func testAnOldFileWithoutTheKeyMergesAsBefore() throws {
        let (stumpCo, stump, _) = try addSub()
        let older = """
        {"formatVersion": 1, "exportedAt": "2026-09-16T00:00:00Z",
         "subcontractors": [{"name": "Stump Co", "contact": "Office", "phone": "407-555-0101", "email": null, "notes": null, "isActive": true, "sortOrder": 0},
                            {"name": "Crane Co", "contact": null, "phone": null, "email": null, "notes": null, "isActive": true, "sortOrder": 1}],
         "items": [{"bucket": "subcontractors", "name": "Stump grinding", "rateCents": 9500, "unit": "stump", "isActive": true, "source": null, "notes": null, "calcInputs": null, "sortOrder": 0, "subcontractorIndex": 0},
                   {"bucket": "subcontractors", "name": "Crane day", "rateCents": 180000, "unit": "day", "isActive": true, "source": null, "notes": null, "calcInputs": null, "sortOrder": 0, "subcontractorIndex": 1}],
         "projects": []}
        """
        let doc = try Transfer.decoder().decode(TransferDocument.self, from: Data(older.utf8))
        XCTAssertNil(doc.subcontractors?[0].remove)
        let result = try Transfer.mergeItems(Data(older.utf8), into: context)
        XCTAssertEqual(result, Transfer.MergeResult(added: 1, updated: 1, unchanged: 0, subcontractors: 1))
        XCTAssertTrue(stumpCo.isActive)
        XCTAssertEqual(stumpCo.contact, "Office")
        XCTAssertEqual(stump.rateCents, 9500)
        XCTAssertEqual(Set(subs.map(\.name)), ["Stump Co", "Crane Co"])
        XCTAssertTrue(try XCTUnwrap(services.first { $0.name == "Crane day" }).isActive)
    }

    func testExportNeverWritesRemove() throws {
        try addSub()
        let data = try Transfer.exportJSON(from: context, settings: AppSettings(), exportedAt: Date(timeIntervalSince1970: 0))
        XCTAssertFalse(String(decoding: data, as: UTF8.self).contains("\"remove\""))
        let doc = try Transfer.decoder().decode(TransferDocument.self, from: data)
        XCTAssertEqual(doc.formatVersion, 3, "format 3 since 0.2.4 (DECISIONS 95); `remove` never changed the format")
        XCTAssertNil(doc.subcontractors?[0].remove)
    }
}
