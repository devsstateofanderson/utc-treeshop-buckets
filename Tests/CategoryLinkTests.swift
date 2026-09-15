import XCTest
import SwiftData
@testable import Buckets

@MainActor
final class CategoryLinkTests: XCTestCase {
    func testProductURLAndSearch() {
        let item = BucketItem(bucket: .materials, name: "Foxtail Palm – 3 gal", rateCents: 19053, unit: "each",
                              source: "Home Depot (Apopka)", notes: "Wekiva Foliage", category: "Palms", link: "homedepot.com/p/334268424")
        XCTAssertEqual(item.productURL?.absoluteString, "https://homedepot.com/p/334268424")
        XCTAssertNil(BucketItem(bucket: .materials, name: "x", link: "not a url").productURL)
        XCTAssertNil(BucketItem(bucket: .materials, name: "x", link: "").productURL)
        XCTAssertTrue(item.matches("palm"))
        XCTAssertTrue(item.matches("PALMS"))
        XCTAssertTrue(item.matches("wekiva"))
        XCTAssertTrue(item.matches("home depot"))
        XCTAssertFalse(item.matches("oak"))
        XCTAssertTrue(item.matches("  "))
    }

    func testMergeSetsCategoryAndLinkAndExportKeepsThem() throws {
        let container = try Store.inMemoryContainer()
        let context = container.mainContext
        context.insert(BucketItem(bucket: .consumables, name: "Dump fee", rateCents: 7500, unit: "load", sortOrder: 0))
        try context.save()
        let file = """
        {"formatVersion": 1, "exportedAt": "2026-09-15T00:00:00Z",
         "settings": {"billableHoursPerYear": 1500, "laborBurdenPct": 30, "markupPct": 35, "minimumJobCents": 75000, "costOfMoneyPct": 0},
         "items": [{"bucket": "consumables", "name": "Dump fee", "rateCents": 7500, "unit": "load", "isActive": true, "source": null, "notes": null, "calcInputs": null, "sortOrder": 0, "category": "Disposal", "link": "https://www.ocfl.net/"}],
         "projects": []}
        """
        XCTAssertEqual(try Transfer.mergeItems(Data(file.utf8), into: context).updated, 1)
        let item = try context.fetch(FetchDescriptor<BucketItem>())[0]
        XCTAssertEqual(item.category, "Disposal")
        XCTAssertEqual(item.link, "https://www.ocfl.net/")
        let json = String(data: try Transfer.exportJSON(from: context, settings: AppSettings(), exportedAt: .now), encoding: .utf8)!
        XCTAssertTrue(json.contains("\"category\" : \"Disposal\""))
        XCTAssertTrue(json.contains("\"link\" : \"https://www.ocfl.net/\""))
        // A file without the two keys (older export) still reads, and leaves them alone.
        let older = file.replacingOccurrences(of: ", \"category\": \"Disposal\", \"link\": \"https://www.ocfl.net/\"", with: "")
        XCTAssertEqual(try Transfer.mergeItems(Data(older.utf8), into: context).unchanged, 1)
        XCTAssertEqual(item.category, "Disposal")
    }

    func testProjectSectionGrouping() throws {
        let container = try Store.inMemoryContainer()
        let context = container.mainContext
        let palm = BucketItem(bucket: .materials, name: "Foxtail", rateCents: 100, category: "Palms", sortOrder: 0)
        let mulch = BucketItem(bucket: .materials, name: "Mulch", rateCents: 100, category: "Mulch", sortOrder: 1)
        let other = BucketItem(bucket: .materials, name: "Stakes", rateCents: 100, sortOrder: 2)
        [palm, mulch, other].forEach(context.insert)
        let project = Project.make(date: .now, items: [palm, mulch, other], settings: AppSettings())
        context.insert(project)
        try context.save()
        let groups = ProjectText.grouped(project.lines(in: .materials))
        XCTAssertEqual(groups.map(\.title), ["Mulch", "Palms", "Other"])
        XCTAssertEqual(groups.last?.lines.map(\.name), ["Stakes"])
    }
}
