import Foundation
import SwiftData

/// The one store file (DECISIONS 44): ~/Library/Application Support/Buckets/Buckets.store.
/// `BUCKETS_STORE=<path>` overrides it (used by the screenshot script), and it never carries data of its own.
enum Store {
    static let schema = Schema([BucketItem.self, Project.self, ProjectLine.self])

    static var defaultURL: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return base.appending(path: "Buckets", directoryHint: .isDirectory).appending(path: "Buckets.store")
    }

    static var url: URL {
        if let override = ProcessInfo.processInfo.environment["BUCKETS_STORE"], !override.isEmpty {
            return URL(fileURLWithPath: override)
        }
        return defaultURL
    }

    static func container(at url: URL = Store.url) throws -> ModelContainer {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let config = ModelConfiguration(url: url)
        return try ModelContainer(for: schema, configurations: config)
    }

    static func inMemoryContainer() throws -> ModelContainer {
        try ModelContainer(for: schema, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    }
}
