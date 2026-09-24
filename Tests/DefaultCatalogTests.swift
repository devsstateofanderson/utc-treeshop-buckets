import XCTest
import SwiftData
@testable import Buckets

/// The product default catalog is neutral (DECISIONS 76–77): no company settings, no labor or equipment rows,
/// overhead as a $0 checklist, and none of the rows the 2026-09-24 audit removed. Read from the repository
/// through `#filePath`, so it runs wherever the tests run from source.
@MainActor
final class DefaultCatalogTests: XCTestCase {
    private var dataURL: URL {
        URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().appending(path: "Scripts/catalog/data")
    }

    private static let removed = ["Weeping Willow", "Majesty Palm", "Windmill Palm"]

    func testDefaultCatalogIsNeutralAndMergesIntoAnEmptyStore() throws {
        let data = try Data(contentsOf: dataURL.appending(path: "Buckets-default-catalog.json"))
        let doc = try Transfer.decoder().decode(TransferDocument.self, from: data)
        XCTAssertNil(doc.settings, "the default catalog carries no company settings (DECISIONS 76)")
        XCTAssertTrue(TransferDocument.readableFormatVersions.contains(doc.formatVersion))
        XCTAssertTrue(doc.projects.isEmpty)
        for name in Self.removed {
            XCTAssertFalse(doc.items.contains { $0.name.contains(name) }, "\(name) was removed by the audit (DECISIONS 77)")
        }
        let counts = Dictionary(grouping: doc.items, by: \.bucket).mapValues(\.count)
        XCTAssertEqual(counts, [.materials: 112, .consumables: 57, .overhead: 19])
        XCTAssertTrue(doc.items.filter { $0.bucket == .overhead }.allSatisfy { $0.rateCents == 0 }, "overhead is a $0 checklist")
        XCTAssertTrue(doc.items.allSatisfy { !$0.name.isEmpty && $0.rateCents >= 0 })
        let container = try Store.inMemoryContainer()
        XCTAssertEqual(try Transfer.mergeItems(data, into: container.mainContext).added, 188)
        // Importing it whole keeps the company's settings instead of overwriting them.
        XCTAssertEqual(try Transfer.importJSON(data, into: container.mainContext), AppSettings.current())
        XCTAssertEqual(try container.mainContext.fetch(FetchDescriptor<BucketItem>()).count, 188)
    }

    func testStarterCatalogCarriesNoSettingsAndNoRemovedRows() throws {
        let data = try Data(contentsOf: dataURL.appending(path: "Buckets-starter-catalog.json"))
        let doc = try Transfer.decoder().decode(TransferDocument.self, from: data)
        XCTAssertNil(doc.settings)
        for name in Self.removed {
            XCTAssertFalse(doc.items.contains { $0.name.contains(name) }, name)
        }
    }
}
