import Foundation
import SwiftData

/// A subcontractor with its own list of priced services (DECISIONS 60). Each service is a `BucketItem` in the
/// Subcontractors bucket, so a project prices it like any quantity row: flat, all-in, per unit, never shown to a customer.
@Model final class Subcontractor {
    var name: String
    var contact: String?
    var phone: String?
    var email: String?
    var notes: String?
    /// Archived subs keep their services on old projects and are hidden from new ones.
    var isActive: Bool
    var sortOrder: Int
    @Relationship(deleteRule: .cascade, inverse: \BucketItem.subcontractor) var services: [BucketItem] = []

    init(name: String, contact: String? = nil, phone: String? = nil, email: String? = nil, notes: String? = nil,
         isActive: Bool = true, sortOrder: Int = 0) {
        self.name = name
        self.contact = contact
        self.phone = phone
        self.email = email
        self.notes = notes
        self.isActive = isActive
        self.sortOrder = sortOrder
    }
}

extension Subcontractor {
    var displayName: String { name.isEmpty ? "Untitled" : name }

    var sortedServices: [BucketItem] {
        services.sorted { ($0.sortOrder, $0.name) < ($1.sortOrder, $1.name) }
    }

    /// Project lines that still point at any of this sub's services; delete only when 0 (DECISIONS 22).
    var referenceCount: Int { services.reduce(0) { $0 + $1.referenceCount } }

    /// Archiving a sub archives its services too, so new projects stop offering them.
    func setActive(_ active: Bool) {
        isActive = active
        for service in services { service.isActive = active }
    }

    @MainActor
    static func nextSortOrder(context: ModelContext) -> Int {
        let all = (try? context.fetch(FetchDescriptor<Subcontractor>())) ?? []
        return (all.map(\.sortOrder).max() ?? -1) + 1
    }
}
