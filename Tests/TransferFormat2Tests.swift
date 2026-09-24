import XCTest
import SwiftData
@testable import Buckets

/// Export/import format 2 (DECISIONS 74; issue #3 §5): the review fields and the service area round-trip,
/// format-1 files still read, format 3 is refused, and the merge carries review fields without vouching for a row.
@MainActor
final class TransferFormat2Tests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext { container.mainContext }
    private let checked = Date(timeIntervalSince1970: 1_789_536_000)
    private let due = Date(timeIntervalSince1970: 1_821_000_000)
    private let stamp = Date(timeIntervalSince1970: 1_750_000_000)

    override func setUp() async throws {
        container = try Store.inMemoryContainer()
        StoreFixture.insertRows(into: context)
    }

    private static let format1Settings =
        #""settings": {"billableHoursPerYear": 1500, "laborBurdenPct": 30, "markupPct": 35, "minimumJobCents": 75000, "costOfMoneyPct": 0}"#

    func testExportIsFormat2AndRoundTripsTheReviewFields() throws {
        let items = try StoreFixture.items(in: context)
        let marcus = items.first { $0.name == "Marcus" }!
        marcus.evidence = "Southern Personnel Leasing invoice"; marcus.checkedAt = checked; marcus.reviewDueAt = due
        marcus.approvedBy = "Alexander"; marcus.assumption = "2,080 paid hours"; marcus.markVerified()
        let chipper = items.first { $0.name == "Chipper (12\")" }!
        chipper.confidence = .estimated; chipper.needsOwnerConfirmation = true
        let company = Company.current(in: context)
        company.name = "STS"; company.serviceArea = "Orange County"
        try context.save()

        let data = try Transfer.exportJSON(from: context, settings: AppSettings(), exportedAt: stamp)
        let text = String(data: data, encoding: .utf8)!
        XCTAssertTrue(text.contains("\"formatVersion\" : 2"))
        XCTAssertTrue(text.contains("\"confidence\" : \"verified\""))
        XCTAssertTrue(text.contains("\"checkedAt\" : \"2026-09-16T05:20:00Z\""))
        XCTAssertTrue(text.contains("\"needsOwnerConfirmation\" : true"))
        XCTAssertTrue(text.contains("\"serviceArea\" : \"Orange County\""))
        XCTAssertFalse(text.contains("\"confidence\" : \"missing\""), "missing is the absence of the key")
        XCTAssertFalse(text.contains("\"needsOwnerConfirmation\" : false"), "the flag is written only when set")

        let second = try Store.inMemoryContainer()
        try Transfer.importJSON(data, into: second.mainContext)
        let back = try second.mainContext.fetch(FetchDescriptor<BucketItem>())
        let m = back.first { $0.name == "Marcus" }!
        XCTAssertEqual(m.confidence, .verified)
        XCTAssertEqual(m.evidence, "Southern Personnel Leasing invoice")
        XCTAssertEqual(m.checkedAt, checked)
        XCTAssertEqual(m.reviewDueAt, due)
        XCTAssertEqual(m.approvedBy, "Alexander")
        XCTAssertEqual(m.assumption, "2,080 paid hours")
        let c = back.first { $0.name == "Chipper (12\")" }!
        XCTAssertEqual(c.confidence, .estimated)
        XCTAssertTrue(c.needsOwnerConfirmation)
        XCTAssertEqual(back.first { $0.name == "David" }!.confidence, .missing)
        XCTAssertEqual(Company.current(in: second.mainContext).serviceArea, "Orange County")
        let again = try Transfer.exportJSON(from: second.mainContext, settings: AppSettings(), exportedAt: stamp)
        XCTAssertEqual(String(data: again, encoding: .utf8), text)
    }

    func testFormat1FilesReadWithEmptyReviewFields() throws {
        let older = """
        {"formatVersion": 1, "exportedAt": "2026-09-15T00:00:00Z", \(Self.format1Settings),
         "items": [{"bucket": "consumables", "name": "Dump fee", "rateCents": 7500, "unit": "load", "isActive": true, "source": "Orange County landfill", "notes": null, "calcInputs": null, "sortOrder": 0}],
         "projects": [{"name": "Old", "client": null, "date": "2026-01-01T00:00:00Z", "hours": 8, "multiplier": 1, "markupPct": 35, "minimumJobCents": 75000, "actualHours": null, "notes": null,
                       "lines": [{"itemIndex": 0, "bucket": "consumables", "name": "Dump fee", "unit": "load", "rateCents": 7500, "isOn": true, "qty": 2, "actualQty": null}]}]}
        """
        let fresh = try Store.inMemoryContainer()
        try Transfer.importJSON(Data(older.utf8), into: fresh.mainContext)
        let dump = try fresh.mainContext.fetch(FetchDescriptor<BucketItem>())[0]
        XCTAssertEqual(dump.confidence, .missing)
        XCTAssertNil(dump.evidence); XCTAssertNil(dump.checkedAt); XCTAssertNil(dump.reviewDueAt)
        XCTAssertFalse(dump.needsOwnerConfirmation)
        XCTAssertEqual(dump.source, "Orange County landfill", "existing fields are untouched")
        XCTAssertEqual(try fresh.mainContext.fetch(FetchDescriptor<Project>())[0].priceCents, 75_000)
        // The re-export is format 2 and reads back identically.
        let data = try Transfer.exportJSON(from: fresh.mainContext, settings: AppSettings(), exportedAt: stamp)
        XCTAssertTrue(String(data: data, encoding: .utf8)!.contains("\"formatVersion\" : 2"))
        let third = try Store.inMemoryContainer()
        try Transfer.importJSON(data, into: third.mainContext)
        XCTAssertEqual(try third.mainContext.fetch(FetchDescriptor<BucketItem>())[0].confidence, .missing)
    }

    func testNewerFormatsAreRefusedWithARangeMessage() throws {
        let newer = """
        {"formatVersion": 3, "exportedAt": "2026-01-01T00:00:00Z", \(Self.format1Settings), "items": [], "projects": []}
        """
        XCTAssertThrowsError(try Transfer.importJSON(Data(newer.utf8), into: context)) { error in
            XCTAssertEqual(error as? TransferError, .unsupportedFormat(3))
            XCTAssertEqual(error.localizedDescription, "This file is Buckets format 3; this app reads formats 1 to 2.")
        }
        XCTAssertThrowsError(try Transfer.mergeItems(Data(newer.utf8), into: context))
        XCTAssertEqual(try StoreFixture.items(in: context).count, 25, "a refused file changes nothing")
        XCTAssertEqual(TransferDocument.readableFormatVersions, 1...2)
    }

    func testMergeCarriesReviewFieldsButNeverVouchesForARow() throws {
        let items = try StoreFixture.items(in: context)
        let marcus = items.first { $0.name == "Marcus" }!
        marcus.evidence = "payroll"; marcus.checkedAt = checked; marcus.markVerified()
        try context.save()
        // A format-1 file (no review keys) leaves the review fields alone: nothing to update.
        let format1 = """
        {"formatVersion": 1, "exportedAt": "2026-09-16T00:00:00Z", \(Self.format1Settings),
         "items": [{"bucket": "labor", "name": "Marcus", "rateCents": 5408, "unit": "hr", "isActive": true, "source": null, "notes": null, "calcInputs": null, "sortOrder": 0}],
         "projects": []}
        """
        XCTAssertEqual(try Transfer.mergeItems(Data(format1.utf8), into: context).unchanged, 1)
        XCTAssertEqual(marcus.confidence, .verified)
        XCTAssertEqual(marcus.evidence, "payroll")
        // A format-2 file updates the fields it carries.
        let format2 = """
        {"formatVersion": 2, "exportedAt": "2026-09-16T00:00:00Z", \(Self.format1Settings),
         "items": [
           {"bucket": "labor", "name": "Marcus", "rateCents": 5408, "unit": "hr", "isActive": true, "source": null, "notes": null, "calcInputs": null, "sortOrder": 0,
            "confidence": "estimated", "assumption": "raise pending", "needsOwnerConfirmation": true},
           {"bucket": "materials", "name": "Mulch", "rateCents": 3200, "unit": "yard", "isActive": true, "source": null, "notes": null, "calcInputs": null, "sortOrder": 0,
            "confidence": "verified", "approvedBy": "file"},
           {"bucket": "materials", "name": "Sod", "rateCents": 500, "unit": "pallet", "isActive": true, "source": "Osceola Sod", "notes": null, "calcInputs": null, "sortOrder": 9,
            "confidence": "verified", "checkedAt": "2026-09-16T05:20:00Z", "evidence": "price list"}
         ],
         "projects": []}
        """
        let result = try Transfer.mergeItems(Data(format2.utf8), into: context)
        XCTAssertEqual(result.added, 1)
        XCTAssertEqual(result.updated, 2)
        XCTAssertEqual(marcus.confidence, .estimated)
        XCTAssertEqual(marcus.assumption, "raise pending")
        XCTAssertTrue(marcus.needsOwnerConfirmation)
        XCTAssertEqual(marcus.evidence, "payroll", "a field the file omits stays")
        let mulch = items.first { $0.name == "Mulch" }!
        XCTAssertEqual(mulch.confidence, .estimated, "verified without evidence and a checked date drops to estimated")
        XCTAssertEqual(mulch.approvedBy, "file")
        let sod = try StoreFixture.items(in: context).first { $0.name == "Sod" }!
        XCTAssertEqual(sod.confidence, .verified, "an added row with evidence and a date can be verified by the file")
        XCTAssertEqual(sod.checkedAt, checked)
        // Running it again changes nothing.
        XCTAssertEqual(try Transfer.mergeItems(Data(format2.utf8), into: context).updated, 1,
                       "Mulch stays 'updated': the file keeps asking for verified and the app keeps refusing")
        XCTAssertEqual(marcus.confidence, .estimated)
    }
}
