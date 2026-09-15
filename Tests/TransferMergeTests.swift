import XCTest
import SwiftData
@testable import Buckets

@MainActor
final class TransferMergeTests: XCTestCase {
    func testMergeAddsFillsInAndKeeps() throws {
        let container = try Store.inMemoryContainer()
        let context = container.mainContext
        context.insert(BucketItem(bucket: .equipment, name: "Stihl 500i", rateCents: 0, sortOrder: 0))          // typed, not priced yet
        context.insert(BucketItem(bucket: .labor, name: "Marcus", rateCents: 5408, sortOrder: 0))               // priced: keep
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
        XCTAssertEqual(result, Transfer.MergeResult(added: 1, filledIn: 1, unchanged: 2))
        let items = try context.fetch(FetchDescriptor<BucketItem>())
        XCTAssertEqual(items.count, 4)
        let saw = items.first { $0.name == "Stihl 500i" }!
        XCTAssertEqual(saw.rateCents, 325)
        XCTAssertEqual(saw.notes, "3 units")
        XCTAssertEqual(saw.equipmentInputs?.repairFactor, Decimal(string: "2.5")!)
        XCTAssertEqual(items.first { $0.name == "Marcus" }!.rateCents, 5408)
        XCTAssertEqual(items.first { $0.name == "Dump fee" }!.rateCents, 7500)
        XCTAssertEqual(items.first { $0.name == "Mulch" }!.source, "Home Depot")
        XCTAssertEqual(try context.fetch(FetchDescriptor<Project>()).count, 0)
        // Running it again changes nothing.
        XCTAssertEqual(try Transfer.mergeItems(Data(file.utf8), into: context), Transfer.MergeResult(added: 0, filledIn: 0, unchanged: 4))
    }
}
