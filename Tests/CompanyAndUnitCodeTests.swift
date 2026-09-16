import XCTest
import SwiftData
@testable import Buckets

@MainActor
final class CompanyAndUnitCodeTests: XCTestCase {
    func testUnitCodesSuggestNextFreeNumberPerPrefix() {
        let items = [BucketItem(bucket: .equipment, name: "a"), BucketItem(bucket: .equipment, name: "b")]
        items[0].unitCode = "SAW-01"; items[1].unitCode = "saw-07"
        XCTAssertEqual(BucketItem.nextUnitCode(prefix: "SAW", among: items), "SAW-08")
        XCTAssertEqual(BucketItem.nextUnitCode(prefix: "TRK", among: items), "TRK-01")
        XCTAssertEqual(BucketItem.unitCodePrefix(for: "Chainsaws"), "SAW")
        XCTAssertEqual(BucketItem.unitCodePrefix(for: "Trucks"), "TRK")
        XCTAssertEqual(BucketItem.unitCodePrefix(for: "Bucket trucks"), "BUC")
        XCTAssertEqual(BucketItem.unitCodePrefix(for: nil), "EQ")
        let truck = BucketItem(bucket: .equipment, name: "Ford F250")
        truck.unitCode = "TRK-02"; truck.make = "Ford"; truck.model = "F-250"; truck.year = 2019; truck.serial = "1FT…"
        XCTAssertEqual(truck.codedName, "TRK-02 · Ford F250")
        XCTAssertEqual(truck.identification, "2019 Ford F-250 · S/N 1FT…")
        XCTAssertTrue(truck.matches("trk-02"))
        XCTAssertTrue(truck.matches("2019"))
        XCTAssertTrue(truck.matches("f-250"))
        XCTAssertEqual(BucketItem(bucket: .equipment, name: "Saw").codedName, "Saw")
        XCTAssertEqual(BucketItem(bucket: .equipment, name: "Saw").identification, "")
    }

    func testCompanyIsASingleRowAndRoundTripsWithDocuments() throws {
        let container = try Store.inMemoryContainer()
        let context = container.mainContext
        let company = Company.current(in: context)
        XCTAssertTrue(company === Company.current(in: context))
        company.name = "Sacred Tree Service LLC"; company.glCarrier = "Lion"; company.glPolicy = "GL-123"
        company.glExpires = Date(timeIntervalSince1970: 1_800_000_000)
        let doc = CompanyDocument(title: "2026 WC COI", category: "Insurance", fileName: "abc-2026 WC COI.pdf",
                                  originalName: "2026 WC COI.pdf", addedAt: Date(timeIntervalSince1970: 1_758_000_000),
                                  expiresAt: Date(timeIntervalSince1970: 1_790_000_000))
        context.insert(doc); doc.company = company
        try context.save()
        XCTAssertEqual(doc.status(on: Date(timeIntervalSince1970: 1_700_000_000)), .current)
        XCTAssertEqual(doc.status(on: Date(timeIntervalSince1970: 1_789_000_000)), .expiringSoon)
        XCTAssertEqual(doc.status(on: Date(timeIntervalSince1970: 1_800_000_000)), .expired)
        XCTAssertEqual(CompanyDocument(title: "x", category: "Other", fileName: "f", originalName: "f", addedAt: .now).status(), .undated)
        XCTAssertEqual(CompanyText.guessCategory("2026 Workers Compensation COI.pdf"), "Insurance")
        XCTAssertEqual(CompanyText.guessCategory("Orange County business tax receipt.pdf"), "License")
        XCTAssertEqual(CompanyText.guessCategory("ISA arborist cert.pdf"), "Certification")

        let data = try Transfer.exportJSON(from: context, settings: AppSettings(), exportedAt: Date(timeIntervalSince1970: 1_750_000_000))
        let text = String(data: data, encoding: .utf8)!
        XCTAssertTrue(text.contains("\"glPolicy\" : \"GL-123\""))
        XCTAssertTrue(text.contains("\"originalName\" : \"2026 WC COI.pdf\""))
        let second = try Store.inMemoryContainer()
        try Transfer.importJSON(data, into: second.mainContext)
        let restored = Company.current(in: second.mainContext)
        XCTAssertEqual(restored.name, "Sacred Tree Service LLC")
        XCTAssertEqual(restored.glExpires, company.glExpires)
        XCTAssertEqual(restored.sortedDocuments.map(\.title), ["2026 WC COI"])
        XCTAssertEqual(try second.mainContext.fetch(FetchDescriptor<Company>()).count, 1)
    }

    func testEquipmentIdentificationRoundTripsAndMerges() throws {
        let container = try Store.inMemoryContainer()
        let context = container.mainContext
        let saw = BucketItem(bucket: .equipment, name: "Stihl 500i", rateCents: 749, sortOrder: 0)
        saw.make = "STIHL"; saw.model = "MS 500i"; saw.year = 2023; saw.serial = "5001"
        context.insert(saw); try context.save()
        let data = try Transfer.exportJSON(from: context, settings: AppSettings(), exportedAt: .now)
        let second = try Store.inMemoryContainer()
        try Transfer.importJSON(data, into: second.mainContext)
        let back = try second.mainContext.fetch(FetchDescriptor<BucketItem>())[0]
        XCTAssertEqual([back.unitCode, back.make, back.model, back.serial], [nil, "STIHL", "MS 500i", "5001"])
        XCTAssertEqual(back.year, 2023)
        // A coded file row claims the uncoded row of that name and gives it the code; other fields it omits stay.
        let file = """
        {"formatVersion": 1, "exportedAt": "2026-09-16T00:00:00Z",
         "settings": {"billableHoursPerYear": 1500, "laborBurdenPct": 30, "markupPct": 35, "minimumJobCents": 75000, "costOfMoneyPct": 0},
         "items": [{"bucket": "equipment", "name": "Stihl 500i", "rateCents": 749, "unit": "hr", "isActive": true, "source": null, "notes": null, "calcInputs": null, "sortOrder": 0, "unitCode": "SAW-09"}],
         "projects": []}
        """
        XCTAssertEqual(try Transfer.mergeItems(Data(file.utf8), into: context).updated, 1)
        XCTAssertEqual(saw.unitCode, "SAW-09")
        XCTAssertEqual(saw.serial, "5001")
    }

    func testMergeTellsIdenticalUnitsApartByCode() throws {
        let container = try Store.inMemoryContainer()
        let context = container.mainContext
        func row(_ code: String, serial: String) -> String {
            #"{"bucket": "equipment", "name": "Stihl 500i", "rateCents": 749, "unit": "hr", "isActive": true, "source": null, "notes": null, "calcInputs": null, "sortOrder": 0, "unitCode": "\#(code)", "serial": "\#(serial)"}"#
        }
        let file = """
        {"formatVersion": 1, "exportedAt": "2026-09-16T00:00:00Z",
         "settings": {"billableHoursPerYear": 1500, "laborBurdenPct": 30, "markupPct": 35, "minimumJobCents": 75000, "costOfMoneyPct": 0},
         "items": [\(row("SAW-01", serial: "A")), \(row("SAW-02", serial: "B"))], "projects": []}
        """
        XCTAssertEqual(try Transfer.mergeItems(Data(file.utf8), into: context).added, 2)
        let saws = try context.fetch(FetchDescriptor<BucketItem>()).sorted { ($0.unitCode ?? "") < ($1.unitCode ?? "") }
        XCTAssertEqual(saws.map(\.serial), ["A", "B"])
        // Re-merging updates each unit by its own code.
        let again = file.replacingOccurrences(of: "\"serial\": \"B\"", with: "\"serial\": \"B2\"")
        let result = try Transfer.mergeItems(Data(again.utf8), into: context)
        XCTAssertEqual(result.added, 0); XCTAssertEqual(result.updated, 1)
        XCTAssertEqual(saws[1].serial, "B2")
        // An uncoded file row cannot pick between two coded units of that name: it is skipped, nothing is added.
        let uncodedRow = #"{"bucket": "equipment", "name": "Stihl 500i", "rateCents": 749, "unit": "hr", "isActive": true, "source": null, "notes": null, "calcInputs": null, "sortOrder": 0, "serial": "Z"}"#
        let uncoded = """
        {"formatVersion": 1, "exportedAt": "2026-09-16T00:00:00Z",
         "settings": {"billableHoursPerYear": 1500, "laborBurdenPct": 30, "markupPct": 35, "minimumJobCents": 75000, "costOfMoneyPct": 0},
         "items": [\(uncodedRow)], "projects": []}
        """
        let skipped = try Transfer.mergeItems(Data(uncoded.utf8), into: context)
        XCTAssertEqual(skipped.added, 0); XCTAssertEqual(skipped.updated, 0); XCTAssertEqual(skipped.unchanged, 1)
        XCTAssertEqual(try context.fetch(FetchDescriptor<BucketItem>()).count, 2)
        XCTAssertEqual(saws.map(\.serial), ["A", "B2"])
        // With one coded unit of that name left, an uncoded file row updates it and keeps its code.
        context.delete(saws[1]); try context.save()
        XCTAssertEqual(try Transfer.mergeItems(Data(uncoded.utf8), into: context).updated, 1)
        XCTAssertEqual(saws[0].unitCode, "SAW-01")
        XCTAssertEqual(saws[0].serial, "Z")
    }
}
