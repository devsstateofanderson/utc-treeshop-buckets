import XCTest
import SwiftData
@testable import Buckets

/// Command-line tool disguised as a test: merges a catalog file into a real store file
/// (Settings → Add or Update Rows, without the app). Runs only when both env vars are set;
/// quit the app first so it reloads the rows on the next launch.
@MainActor
final class LiveStoreMergeTool: XCTestCase {
    func testMergeCatalogIntoStore() throws {
        let env = ProcessInfo.processInfo.environment
        guard let store = env["BUCKETS_MERGE_STORE"], !store.isEmpty, let file = env["BUCKETS_CATALOG_FILE"], !file.isEmpty else {
            throw XCTSkip("set BUCKETS_MERGE_STORE and BUCKETS_CATALOG_FILE")
        }
        let container = try Store.container(at: URL(fileURLWithPath: store))
        let result = try Transfer.mergeItems(try Data(contentsOf: URL(fileURLWithPath: file)), into: container.mainContext)
        let count = try container.mainContext.fetch(FetchDescriptor<BucketItem>()).count
        print("MERGE RESULT: added \(result.added), updated \(result.updated), unchanged \(result.unchanged); \(count) rows now in \(store)")
    }
}
