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
    /// The sub this service belongs to; set on every row in the Subcontractors bucket (DECISIONS 60).
    var subcontractor: Subcontractor?
    /// Crew formations this labor or equipment row is part of (DECISIONS 62).
    var loadouts: [Loadout] = []
    /// Equipment identification (DECISIONS 66): the short code the crew uses ("SAW-01", "TRK-02"), and the
    /// make / model / year / serial or VIN that tell two identical units apart.
    var unitCode: String?
    var make: String?
    var model: String?
    var year: Int?
    var serial: String?
    /// Row trust and review (DECISIONS 72; issue #3): where the figure came from, when it was checked, when to
    /// look again, how far to trust it, who signed off, and what it assumes. All optional (or defaulted) so a
    /// store from v1.1 migrates in place with every row reading as `missing`.
    var evidence: String?
    var checkedAt: Date?
    var reviewDueAt: Date?
    /// `Confidence.rawValue`; nil is `missing`. Read and written through `confidence` (CatalogReview.swift).
    var confidenceRaw: String?
    var approvedBy: String?
    var assumption: String?
    /// Set by whoever entered the figure when the owner should look at it before it is trusted.
    var needsOwnerConfirmation: Bool = false
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

    /// Search across name, category, unit, source, notes, the equipment identification and the review fields
    /// (case- and diacritic-insensitive).
    func matches(_ query: String) -> Bool {
        let q = query.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return true }
        return [name, category ?? "", unit, source ?? "", notes ?? "", unitCode ?? "", make ?? "", model ?? "", serial ?? "",
                year.map(String.init) ?? "", evidence ?? "", approvedBy ?? "", assumption ?? ""].contains { $0.localizedStandardContains(q) }
    }

    /// "TRK-02 · Ford F250" when the row has a unit code, else the name.
    var codedName: String {
        let base = name.isEmpty ? "Untitled" : name
        guard let code = unitCode?.trimmingCharacters(in: .whitespaces), !code.isEmpty else { return base }
        return "\(code) · \(base)"
    }

    /// "2013 Chevrolet Silverado 1500 · VIN 3GCP…" for the tables; empty when nothing is filled in.
    var identification: String {
        let ymm = [year.map(String.init), make, model].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " ")
        let sn = serial?.trimmingCharacters(in: .whitespaces) ?? ""
        return [ymm, sn.isEmpty ? "" : "S/N \(sn)"].filter { !$0.isEmpty }.joined(separator: " · ")
    }

    /// Next free code with this prefix among `items`: "SAW-01", "SAW-02"… (DECISIONS 66).
    static func nextUnitCode(prefix: String, among items: [BucketItem]) -> String {
        let p = prefix.uppercased()
        let taken = items.compactMap { $0.unitCode?.uppercased() }
            .filter { $0.hasPrefix(p + "-") }
            .compactMap { Int($0.dropFirst(p.count + 1)) }
        return String(format: "%@-%02d", p, (taken.max() ?? 0) + 1)
    }

    static func nextUnitCodePrefixFallback(_ item: BucketItem) -> String { unitCodePrefix(for: item.category) }

    /// Code prefix suggested by the row's category: Chainsaws → SAW, Trucks → TRK…; otherwise the category's first letters.
    static func unitCodePrefix(for category: String?) -> String {
        let known: [String: String] = ["chainsaws": "SAW", "pole saws": "PSW", "trucks": "TRK", "trailers": "TRL", "machines": "MCH",
                                       "rigging": "RIG", "fuel cans": "CAN", "small tools": "TL", "chippers": "CHP", "climbing": "CLM"]
        let key = (category ?? "").trimmingCharacters(in: .whitespaces).lowercased()
        if let code = known[key] { return code }
        let letters = key.filter(\.isLetter)
        return letters.isEmpty ? "EQ" : String(letters.prefix(3)).uppercased()
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
