import XCTest
import SwiftData
@testable import Buckets

/// Checks a catalog file (Scripts/catalog) imports through the same code as Settings → Add Rows from JSON.
/// Runs only when BUCKETS_CATALOG_FILE names a file.
@MainActor
final class StarterCatalogTests: XCTestCase {
    func testCatalogFileMergesCleanly() throws {
        guard let path = ProcessInfo.processInfo.environment["BUCKETS_CATALOG_FILE"], !path.isEmpty else {
            throw XCTSkip("set BUCKETS_CATALOG_FILE to validate a catalog file")
        }
        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        let container = try Store.inMemoryContainer()
        let context = container.mainContext
        // Rows the owner already typed: the merge must fill the $0 ones and keep the priced ones.
        context.insert(BucketItem(bucket: .equipment, name: "Stihl 500i", rateCents: 0, sortOrder: 0))
        context.insert(BucketItem(bucket: .equipment, name: "Porta Wrap 15'", rateCents: 0, sortOrder: 1))
        try context.save()
        let result = try Transfer.mergeItems(data, into: context)
        let items = try context.fetch(FetchDescriptor<BucketItem>())
        XCTAssertEqual(result.updated, 1)
        XCTAssertEqual(result.unchanged, 0)
        XCTAssertEqual(items.count, result.added + 2)
        XCTAssertEqual(items.first { $0.name == "Porta Wrap 15'" }!.rateCents, 0, "rows the file does not name are untouched")
        let saw = items.first { $0.name == "Stihl 500i" }!
        XCTAssertGreaterThan(saw.rateCents, 0)
        XCTAssertNotNil(saw.equipmentInputs)
        // Every equipment row's stored rate must equal what the app's calculator gives for its inputs.
        for item in items where item.bucket == .equipment {
            guard let ci = item.equipmentInputs else { continue }
            let rate = try EquipmentCalc.rateCents(price: ci.priceCents, salvage: ci.salvageCents, lifeHours: ci.lifeHours,
                                                   annualHours: ci.annualHours, fuelOilPerHour: ci.fuelOilPerHourCents,
                                                   repairFactor: ci.repairFactor, insurancePerYear: ci.insurancePerYearCents,
                                                   costOfMoney: ci.costOfMoneyPct / 100)
            XCTAssertEqual(item.rateCents, rate, item.name)
        }
        XCTAssertTrue(items.allSatisfy { !$0.name.isEmpty && $0.rateCents >= 0 })
        print("catalog: added \(result.added), updated \(result.updated); \(items.count) rows total")
    }
}
