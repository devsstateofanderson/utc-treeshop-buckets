import XCTest
import SwiftData
@testable import Buckets

/// Setup & readiness (DECISIONS 73; issue #3 §2): required inputs, completion by bucket, the unresolved groups,
/// and the rule that "ready" is never claimed while a setup input is unresolved.
@MainActor
final class ReadinessTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext { container.mainContext }
    private let checked = Date(timeIntervalSince1970: 1_789_536_000)
    private let later = Date(timeIntervalSince1970: 1_789_636_000)
    private let now = Date(timeIntervalSince1970: 1_790_236_000)
    private let past = Date(timeIntervalSince1970: 1_788_536_000)

    override func setUp() async throws {
        container = try Store.inMemoryContainer()
    }

    private func verifyAll(_ items: [BucketItem], at date: Date) {
        for item in items { item.evidence = "checked"; item.checkedAt = date; item.markVerified() }
    }

    func testEmptyStoreIsNotReady() {
        let r = Readiness(items: [], company: nil, settings: AppSettings(), now: now)
        XCTAssertEqual(r.status, .notReady(missingInputs: 5), "name, service area, labor, equipment, overhead")
        XCTAssertEqual(r.status.title, "Not ready")
        XCTAssertEqual(r.status.detail, "5 setup inputs unresolved.")
        XCTAssertEqual(r.setupInputs.map(\.title), ["Company name", "Service area", "Billable hours", "Target margin", "Minimum job",
                                                   "Labor rows", "Equipment rows", "Overhead rows"])
        XCTAssertEqual(r.setupInputs.filter(\.isResolved).map(\.detail), ["1,500 hours per year", "50%", "$750.00"])
        XCTAssertEqual(r.setupInputs.first { $0.title == "Labor rows" }?.detail, "none yet")
        XCTAssertEqual(r.unresolvedTotal, 0)
        XCTAssertTrue(r.buckets.allSatisfy { $0.active == 0 && $0.completionPct == 0 })
        XCTAssertNil(r.lastVerified)
    }

    func testFixtureRowsWithACompanyNeedReview() throws {
        StoreFixture.insertRows(into: context)
        let company = Company.current(in: context)
        company.name = "Sacred Tree Service LLC"
        company.serviceArea = "Orange, Seminole and Lake counties"
        let items = try StoreFixture.items(in: context)
        let r = Readiness(items: items, company: company, settings: AppSettings(), now: now)
        XCTAssertEqual(r.missingInputs, 0)
        XCTAssertEqual(r.status, .needsReview(unresolvedRows: 25))
        XCTAssertEqual(r.status.detail, "25 active catalog rows unresolved.")
        XCTAssertEqual(r.unresolved, [.missing: 25])
        XCTAssertEqual(r.firstBucket[.missing], .labor)
        XCTAssertEqual(r.buckets.map { "\($0.bucket.rawValue) \($0.resolved)/\($0.active)" },
                       ["labor 0/3", "equipment 0/5", "materials 0/4", "consumables 0/6", "subcontractors 0/0", "overhead 0/7"])
        XCTAssertEqual(r.setupInputs.first { $0.title == "Labor rows" }?.detail, "3 active rows")
        XCTAssertEqual(r.setupInputs.first { $0.title == "Company name" }?.detail, "Sacred Tree Service LLC")
    }

    func testGroupsCountEachRowOnceAndReadyNeedsEveryRow() throws {
        StoreFixture.insertRows(into: context)
        let company = Company.current(in: context)
        company.name = "STS"; company.serviceArea = "Apopka"
        let items = try StoreFixture.items(in: context)
        verifyAll(items, at: checked)
        let marcus = items.first { $0.name == "Marcus" }!
        marcus.checkedAt = later
        let david = items.first { $0.name == "David" }!
        david.confidence = .estimated
        let chipper = items.first { $0.name == "Chipper (12\")" }!
        chipper.needsOwnerConfirmation = true
        let rent = items.first { $0.name == "Shop rent" }!
        rent.reviewDueAt = past
        let mulch = items.first { $0.name == "Mulch" }!
        mulch.confidence = .missing
        var r = Readiness(items: items, company: company, settings: AppSettings(), now: now)
        XCTAssertEqual(r.unresolved, [.estimated: 1, .ownerConfirmation: 1, .overdue: 1, .missing: 1])
        XCTAssertEqual(r.unresolvedTotal, 4)
        XCTAssertEqual(r.status, .needsReview(unresolvedRows: 4))
        XCTAssertEqual(r.firstBucket, [.estimated: .labor, .ownerConfirmation: .equipment, .overdue: .overhead, .missing: .materials])
        XCTAssertEqual(r.buckets.first { $0.bucket == .labor }?.resolved, 2)
        XCTAssertEqual(r.buckets.first { $0.bucket == .labor }?.completionPct, 67)
        XCTAssertEqual(r.buckets.first { $0.bucket == .labor }?.lastVerified, later)
        XCTAssertEqual(r.lastVerified, later)
        // Resolve the four; the store is ready.
        david.confidence = .verified
        chipper.needsOwnerConfirmation = false
        rent.reviewDueAt = nil
        mulch.confidence = .verified
        r = Readiness(items: items, company: company, settings: AppSettings(), now: now)
        XCTAssertEqual(r.status, .ready)
        XCTAssertEqual(r.status.detail, "Every setup input and every active row is resolved.")
        XCTAssertTrue(r.buckets.filter { $0.active > 0 }.allSatisfy { $0.completionPct == 100 })
        // Archived rows do not count either way.
        let crane = items.first { $0.name == "Crane (sub)" }!
        crane.confidence = .missing; crane.isActive = false
        XCTAssertEqual(Readiness(items: items, company: company, settings: AppSettings(), now: now).status, .ready)
        XCTAssertEqual(Readiness(items: items, company: company, settings: AppSettings(), now: now).buckets.first { $0.bucket == .consumables }?.active, 5)
    }

    func testReadyIsNeverClaimedWhileASetupInputIsUnresolved() throws {
        StoreFixture.insertRows(into: context)
        let items = try StoreFixture.items(in: context)
        verifyAll(items, at: checked)
        let company = Company.current(in: context)
        company.name = "STS"; company.serviceArea = "Apopka"
        XCTAssertEqual(Readiness(items: items, company: company, settings: AppSettings(), now: now).status, .ready)
        company.serviceArea = "  "
        XCTAssertEqual(Readiness(items: items, company: company, settings: AppSettings(), now: now).status, .notReady(missingInputs: 1))
        company.serviceArea = "Apopka"
        var settings = AppSettings(); settings.targetMarginPct = 0; settings.minimumJobCents = 0
        let r = Readiness(items: items, company: company, settings: settings, now: now)
        XCTAssertEqual(r.status, .notReady(missingInputs: 2))
        XCTAssertEqual(r.setupInputs.filter { !$0.isResolved }.map(\.title), ["Target margin", "Minimum job"])
        for item in items where item.bucket == .overhead { item.isActive = false }
        XCTAssertEqual(Readiness(items: items, company: company, settings: AppSettings(), now: now).status, .notReady(missingInputs: 1))
        XCTAssertEqual(Readiness(items: items, company: nil, settings: AppSettings(), now: now).status, .notReady(missingInputs: 3))
    }

    func testServiceAreaResolvesByDescriptionOrRadius() {
        let company = Company(name: "STS")
        var r = Readiness(items: [], company: company, settings: AppSettings(), now: now)
        XCTAssertEqual(r.setupInputs.first { $0.title == "Service area" }?.isResolved, false)
        company.serviceRadiusMiles = 30
        r = Readiness(items: [], company: company, settings: AppSettings(), now: now)
        XCTAssertEqual(r.setupInputs.first { $0.title == "Service area" }?.isResolved, true, "a radius alone resolves it (DECISIONS 78)")
        XCTAssertEqual(r.setupInputs.first { $0.title == "Service area" }?.detail, "30-mile radius")
        company.serviceArea = "Apopka and Central Florida"; company.growingZone = "USDA 9b"
        r = Readiness(items: [], company: company, settings: AppSettings(), now: now)
        XCTAssertEqual(r.setupInputs.first { $0.title == "Service area" }?.detail, "Apopka and Central Florida · 30-mile radius · USDA 9b")
        company.serviceRadiusMiles = 0; company.serviceArea = "  "; company.growingZone = nil
        r = Readiness(items: [], company: company, settings: AppSettings(), now: now)
        XCTAssertEqual(r.setupInputs.first { $0.title == "Service area" }?.detail, "not set")
    }
}
