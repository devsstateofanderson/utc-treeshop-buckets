import Foundation
import SwiftData

/// A crew formation: the labor and equipment rows that go out together (DECISIONS 62). Applying a loadout to a
/// project sets its labor and equipment toggles; it adds no pricing of its own.
@Model final class Loadout {
    var name: String
    var notes: String?
    var sortOrder: Int
    @Relationship(inverse: \BucketItem.loadouts) var members: [BucketItem] = []

    init(name: String, notes: String? = nil, sortOrder: Int = 0) {
        self.name = name
        self.notes = notes
        self.sortOrder = sortOrder
    }
}

extension Loadout {
    var displayName: String { name.isEmpty ? "Untitled" : name }

    var sortedMembers: [BucketItem] {
        members.sorted { ($0.bucket.index, $0.sortOrder, $0.name) < ($1.bucket.index, $1.sortOrder, $1.name) }
    }

    func contains(_ item: BucketItem) -> Bool {
        members.contains { $0.persistentModelID == item.persistentModelID }
    }

    func setMember(_ item: BucketItem, _ on: Bool) {
        if on { if !contains(item) { members.append(item) } }
        else { members.removeAll { $0.persistentModelID == item.persistentModelID } }
    }

    /// Σ of the members' hourly rates, the crew's cost per project hour before overhead.
    var hourlyRateCents: Int {
        members.filter { $0.bucket == .labor || $0.bucket == .equipment }.reduce(0) { $0 + $1.rateCents }
    }

    func copy(named newName: String, sortOrder: Int) -> Loadout {
        let loadout = Loadout(name: newName, notes: notes, sortOrder: sortOrder)
        loadout.members = members
        return loadout
    }

    @MainActor
    static func nextSortOrder(context: ModelContext) -> Int {
        let all = (try? context.fetch(FetchDescriptor<Loadout>())) ?? []
        return (all.map(\.sortOrder).max() ?? -1) + 1
    }
}
