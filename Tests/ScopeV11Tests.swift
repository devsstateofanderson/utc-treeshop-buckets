import XCTest
import SwiftData
@testable import Buckets

/// Subcontractors, packages, loadouts and the transfer changes (DECISIONS 60–63).
@MainActor
final class ScopeV11Tests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext { container.mainContext }

    override func setUp() async throws {
        container = try Store.inMemoryContainer()
        StoreFixture.insertRows(into: context)
    }

    private func addSub() throws -> (Subcontractor, BucketItem, BucketItem) {
        let sub = Subcontractor(name: "J&J Stump", contact: "Jorge", phone: "407-555-0100", sortOrder: 0)
        context.insert(sub)
        let stump = BucketItem(bucket: .subcontractors, name: "Stump grinding", rateCents: 9000, unit: "stump", sortOrder: 0)
        let travel = BucketItem(bucket: .subcontractors, name: "Travel", rateCents: 5000, unit: "trip", sortOrder: 1)
        stump.subcontractor = sub; travel.subcontractor = sub
        context.insert(stump); context.insert(travel)
        try context.save()
        return (sub, stump, travel)
    }

    // MARK: Subcontractors

    func testSubcontractorServicesPriceLikeConsumablesAndGroupBySub() throws {
        let (sub, stump, _) = try addSub()
        XCTAssertEqual(sub.sortedServices.map(\.name), ["Stump grinding", "Travel"])
        let project = try StoreFixture.baseProject(in: context)
        XCTAssertEqual(project.lines.count, 27, "two sub services joined the base fixture, both off")
        XCTAssertEqual(project.priceCents, 250_150)
        let line = project.line("Stump grinding")
        XCTAssertFalse(line.isOn)
        line.isOn = true; line.qty = 3
        let b = project.breakdown(billableHours: 1500)
        XCTAssertEqual(b.subcontractors, 27_000)
        XCTAssertEqual(b.consumables, 15_000)
        XCTAssertEqual(b.price, 286_600)             // same as 3 stumps in the consumables bucket (DECISIONS 15)
        XCTAssertEqual(ProjectText.grouped(project.lines(in: .subcontractors)).map(\.title), ["J&J Stump"])
        XCTAssertTrue(ProjectText.breakdown(project, breakdown: b).contains("Subcontractors: $270.00"))
        XCTAssertFalse(ProjectText.price(name: project.displayName, priceCents: b.price).contains("Stump"))
        // Referenced: the sub cannot be deleted; archiving cascades to its services.
        XCTAssertEqual(sub.referenceCount, 2)
        XCTAssertEqual(stump.referenceCount, 1)
        sub.setActive(false)
        XCTAssertFalse(stump.isActive)
        let fresh = Project.make(date: .now, items: try StoreFixture.items(in: context), settings: AppSettings())
        XCTAssertNil(fresh.lines.first { $0.name == "Stump grinding" }, "archived services are hidden from new projects")
    }

    func testDeletingASubDeletesItsServices() throws {
        let (sub, _, _) = try addSub()
        XCTAssertEqual(sub.referenceCount, 0)
        context.delete(sub)
        try context.save()
        XCTAssertEqual(try context.fetch(FetchDescriptor<BucketItem>()).filter { $0.bucket == .subcontractors }.count, 0)
    }

    // MARK: Loadouts

    func testApplyLoadoutSetsLaborAndEquipmentToggles() throws {
        let items = try StoreFixture.items(in: context)
        let crew = Loadout(name: "Two-man prune", sortOrder: 0)
        context.insert(crew)
        for name in ["Marcus", "David", "Bucket truck (50 ft)", "Chainsaws (3)"] { crew.setMember(items.first { $0.name == name }!, true) }
        try context.save()
        XCTAssertEqual(crew.hourlyRateCents, 5408 + 3966 + 2372 + 750)
        let project = try StoreFixture.baseProject(in: context)
        let newHire = BucketItem(bucket: .labor, name: "Ana", rateCents: 4000, sortOrder: 9)
        context.insert(newHire)
        crew.setMember(newHire, true)
        try context.save()
        project.apply(crew)
        XCTAssertEqual(project.crewName, "Two-man prune")
        XCTAssertTrue(project.line("Marcus").isOn)
        XCTAssertFalse(project.line("Miguel").isOn)
        XCTAssertFalse(project.line("Chip truck (F-550)").isOn)
        XCTAssertTrue(project.line("Chainsaws (3)").isOn)
        XCTAssertTrue(project.line("Ana").isOn, "a member the project lacked is appended, on")
        XCTAssertTrue(project.line("Dump fee").isOn, "other buckets are untouched")
        XCTAssertEqual(project.lines.count, 26)
        // (5408+3966+4000+2372+750 = 164.96/hr + 18.00/hr overhead) × 8 h + 150 dump = 1613.68 × 1.35 = 2178.468
        XCTAssertEqual(project.priceCents, 217_847)
        crew.setMember(newHire, false)
        XCTAssertFalse(crew.contains(newHire))
        let copy = crew.copy(named: "Copy", sortOrder: 1)
        XCTAssertEqual(copy.members.count, 4)
    }

    // MARK: Packages

    func testPackageInstantiatesAtTodaysRates() throws {
        let package = try StoreFixture.baseProject(in: context)
        package.name = "Standard removal"
        package.isTemplate = true
        package.crewName = "Full crew"
        let marcus = try StoreFixture.items(in: context).first { $0.name == "Marcus" }!
        marcus.rateCents = 6000
        var settings = AppSettings(); settings.markupPct = 40
        let job = package.instantiate(date: Date(timeIntervalSince1970: 1_800_000_000), items: try StoreFixture.items(in: context), settings: settings)
        context.insert(job)
        try context.save()
        XCTAssertFalse(job.isTemplate)
        XCTAssertTrue(package.isTemplate)
        XCTAssertEqual(job.name, "Standard removal")
        XCTAssertEqual(job.crewName, "Full crew")
        XCTAssertEqual(job.hours, 8)
        XCTAssertEqual(job.line("Marcus").rateCents, 6000, "today's rates")
        XCTAssertEqual(package.line("Marcus").rateCents, 5408, "the package keeps its snapshot until re-priced")
        XCTAssertEqual(job.markupPct, 40)
        XCTAssertEqual(job.line("Dump fee").qty, 2)
        let saved = job.asPackage(date: .now)
        XCTAssertTrue(saved.isTemplate)
        XCTAssertEqual(saved.name, "Standard removal")
        XCTAssertNil(saved.actualHours)
    }

    // MARK: Transfer

    func testExportImportRoundTripsSubsLoadoutsAndPackages() throws {
        let (sub, stump, _) = try addSub()
        let items = try StoreFixture.items(in: context)
        let crew = Loadout(name: "Crew A", notes: "bucket truck days", sortOrder: 0)
        context.insert(crew)
        crew.setMember(items.first { $0.name == "Marcus" }!, true)
        crew.setMember(items.first { $0.name == "Bucket truck (50 ft)" }!, true)
        let package = try StoreFixture.baseProject(in: context)
        package.isTemplate = true; package.crewName = "Crew A"; package.name = "Standard removal"
        package.line("Stump grinding").isOn = true
        try context.save()
        let stamp = Date(timeIntervalSince1970: 1_750_000_000)
        let data = try Transfer.exportJSON(from: context, settings: AppSettings(), exportedAt: stamp)
        let text = String(data: data, encoding: .utf8)!
        XCTAssertTrue(text.contains("\"subcontractorIndex\" : 0"))
        XCTAssertTrue(text.contains("\"isTemplate\" : true"))
        XCTAssertTrue(text.contains("\"memberIndexes\""))

        let second = try Store.inMemoryContainer()
        try Transfer.importJSON(data, into: second.mainContext)
        let subs = try second.mainContext.fetch(FetchDescriptor<Subcontractor>())
        XCTAssertEqual(subs.count, 1)
        XCTAssertEqual(subs[0].name, sub.name)
        XCTAssertEqual(subs[0].phone, "407-555-0100")
        XCTAssertEqual(subs[0].sortedServices.map(\.name), ["Stump grinding", "Travel"])
        let loadouts = try second.mainContext.fetch(FetchDescriptor<Loadout>())
        XCTAssertEqual(loadouts.count, 1)
        XCTAssertEqual(Set(loadouts[0].members.map(\.name)), ["Marcus", "Bucket truck (50 ft)"])
        let projects = try second.mainContext.fetch(FetchDescriptor<Project>())
        XCTAssertEqual(projects.count, 1)
        XCTAssertTrue(projects[0].isTemplate)
        XCTAssertEqual(projects[0].crewName, "Crew A")
        XCTAssertEqual(projects[0].line("Stump grinding").item?.subcontractor?.name, "J&J Stump")
        let again = try Transfer.exportJSON(from: second.mainContext, settings: AppSettings(), exportedAt: stamp)
        XCTAssertEqual(String(data: again, encoding: .utf8), text)
        _ = stump
    }

    func testOlderFilesWithoutTheNewKeysStillRead() throws {
        let older = """
        {"formatVersion": 1, "exportedAt": "2026-09-15T00:00:00Z",
         "settings": {"billableHoursPerYear": 1500, "laborBurdenPct": 30, "markupPct": 35, "minimumJobCents": 75000, "costOfMoneyPct": 0},
         "items": [{"bucket": "consumables", "name": "Dump fee", "rateCents": 7500, "unit": "load", "isActive": true, "source": null, "notes": null, "calcInputs": null, "sortOrder": 0}],
         "projects": [{"name": "Old", "client": null, "date": "2026-01-01T00:00:00Z", "hours": 8, "multiplier": 1, "markupPct": 35, "minimumJobCents": 75000, "actualHours": null, "notes": null,
                       "lines": [{"itemIndex": 0, "bucket": "consumables", "name": "Dump fee", "unit": "load", "rateCents": 7500, "isOn": true, "qty": 2, "actualQty": null}]}]}
        """
        let fresh = try Store.inMemoryContainer()
        try Transfer.importJSON(Data(older.utf8), into: fresh.mainContext)
        let project = try fresh.mainContext.fetch(FetchDescriptor<Project>())[0]
        XCTAssertFalse(project.isTemplate)
        XCTAssertNil(project.crewName)
        XCTAssertEqual(project.priceCents, 75_000)
        XCTAssertEqual(try Transfer.mergeItems(Data(older.utf8), into: fresh.mainContext).unchanged, 1)
    }

    func testMergeArchivesButNeverUnarchivesAndBringsSubsAndLoadouts() throws {
        let items = try StoreFixture.items(in: context)
        let skid = items.first { $0.name == "Mini skid steer" }!
        let file = """
        {"formatVersion": 1, "exportedAt": "2026-09-16T00:00:00Z",
         "settings": {"billableHoursPerYear": 1500, "laborBurdenPct": 30, "markupPct": 35, "minimumJobCents": 75000, "costOfMoneyPct": 0},
         "subcontractors": [{"name": "Central FL Crane", "contact": "Dispatch", "phone": "407-555-0199", "email": null, "notes": null, "isActive": true, "sortOrder": 0}],
         "items": [
           {"bucket": "equipment", "name": "Mini skid steer", "rateCents": 1603, "unit": "hr", "isActive": false, "source": null, "notes": null, "calcInputs": null, "sortOrder": 0},
           {"bucket": "labor", "name": "Marcus", "rateCents": 5408, "unit": "hr", "isActive": true, "source": null, "notes": null, "calcInputs": null, "sortOrder": 0},
           {"bucket": "subcontractors", "name": "Crane day", "rateCents": 180000, "unit": "day", "isActive": true, "source": null, "notes": null, "calcInputs": null, "sortOrder": 0, "subcontractorIndex": 0}
         ],
         "loadouts": [{"name": "Crane crew", "notes": null, "sortOrder": 0, "memberIndexes": [1]}],
         "projects": []}
        """
        let result = try Transfer.mergeItems(Data(file.utf8), into: context)
        XCTAssertEqual(result.added, 1)
        XCTAssertEqual(result.subcontractors, 1)
        XCTAssertEqual(result.loadouts, 1)
        XCTAssertFalse(skid.isActive, "a file can archive a row it names")
        let crane = try context.fetch(FetchDescriptor<Subcontractor>())[0]
        XCTAssertEqual(crane.sortedServices.map(\.name), ["Crane day"])
        XCTAssertEqual(crane.services[0].rateCents, 180_000)
        let crew = try context.fetch(FetchDescriptor<Loadout>())[0]
        XCTAssertEqual(crew.members.map(\.name), ["Marcus"])
        // A second pass with the row active again does not un-archive it.
        let again = file.replacingOccurrences(of: "\"isActive\": false", with: "\"isActive\": true")
        _ = try Transfer.mergeItems(Data(again.utf8), into: context)
        XCTAssertFalse(skid.isActive)
        XCTAssertEqual(try context.fetch(FetchDescriptor<Subcontractor>()).count, 1)
        XCTAssertEqual(try context.fetch(FetchDescriptor<Loadout>()).count, 1)
    }
}
