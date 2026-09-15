import Foundation
import SwiftData

/// One row in one of the five buckets (BRIEF §5.3).
@Model final class BucketItem {
    var bucket: Bucket
    var name: String
    /// $/hr for labor & equipment; $/yr for overhead (shown as $/hr); unit cost for materials & consumables.
    var rateCents: Int
    /// "hr" | "yr" | "each" | "yard" | "load" | "day" | "stump" | "application" | "roll" …
    var unit: String
    /// Archived rows stay for old projects, hidden from new ones.
    var isActive: Bool
    /// Free text (vendor, supplier, sub name).
    var source: String?
    var notes: String?
    /// JSON of the Labor or Equipment calculator inputs so "Calculate…" reopens filled in.
    var calcInputs: Data?
    var sortOrder: Int
    /// Optional grouping shown in the tables and project sections: "Palms", "Chains & bars", "Trucks"… (DECISIONS 57).
    var category: String?
    /// Product or supplier page, opened from the Form (DECISIONS 57).
    var link: String?
    /// Inverse of `ProjectLine.item`. Declared so that deleting a row sets every referencing line's
    /// `item` to nil instead of leaving a dangling reference (DECISIONS 21); also the delete guard (22).
    @Relationship(deleteRule: .nullify, inverse: \ProjectLine.item) var lines: [ProjectLine] = []

    init(bucket: Bucket, name: String, rateCents: Int = 0, unit: String? = nil, isActive: Bool = true,
         source: String? = nil, notes: String? = nil, category: String? = nil, link: String? = nil,
         calcInputs: Data? = nil, sortOrder: Int = 0) {
        self.bucket = bucket
        self.name = name
        self.rateCents = rateCents
        self.unit = unit ?? bucket.fixedUnit ?? "each"
        self.isActive = isActive
        self.source = source
        self.notes = notes
        self.category = category
        self.link = link
        self.calcInputs = calcInputs
        self.sortOrder = sortOrder
    }
}

extension BucketItem {
    /// Category as text for sorting and display ("" when unset).
    var categoryText: String { category ?? "" }

    /// The link as a URL when it is one (a bare "homedepot.com/…" gets https://).
    var productURL: URL? {
        guard var text = link?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else { return nil }
        if !text.contains("://") { text = "https://" + text }
        guard let url = URL(string: text), let scheme = url.scheme, ["http", "https"].contains(scheme), url.host() != nil else { return nil }
        return url
    }

    /// Search across name, category, unit, source and notes (case- and diacritic-insensitive).
    func matches(_ query: String) -> Bool {
        let q = query.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return true }
        return [name, category ?? "", unit, source ?? "", notes ?? ""].contains { $0.localizedStandardContains(q) }
    }

    /// The figure a project prices with, in $/hr cents, for hourly rows (overhead: $/yr ÷ billable hours, display only).
    func hourlyRateCents(billableHours: Decimal) -> Int? {
        guard bucket.rowKind == .hourly else { return nil }
        guard bucket.isAnnual else { return rateCents }
        guard billableHours > 0 else { return 0 }
        return Money.cents(Decimal(rateCents) / billableHours)
    }

    var laborInputs: LaborCalcInputs? {
        guard bucket == .labor, let calcInputs else { return nil }
        return try? JSONDecoder().decode(LaborCalcInputs.self, from: calcInputs)
    }

    var equipmentInputs: EquipmentCalcInputs? {
        guard bucket == .equipment, let calcInputs else { return nil }
        return try? JSONDecoder().decode(EquipmentCalcInputs.self, from: calcInputs)
    }

    /// Lines in any project that still point at this row. Delete is allowed only when this is 0 (DECISIONS 22).
    var referenceCount: Int { lines.count }

    /// Next `sortOrder` for a new row in `bucket` (DECISIONS 28).
    @MainActor
    static func nextSortOrder(in bucket: Bucket, context: ModelContext) -> Int {
        let items = (try? context.fetch(FetchDescriptor<BucketItem>())) ?? []
        return (items.filter { $0.bucket == bucket }.map(\.sortOrder).max() ?? -1) + 1
    }
}
