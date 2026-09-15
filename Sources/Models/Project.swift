import Foundation
import SwiftData

/// One priced job (BRIEF §5.3). Rates are snapshots taken when its lines were created (DECISIONS 17).
@Model final class Project {
    var name: String
    var client: String?
    var date: Date
    var hours: Decimal
    /// 1 normal · 2 after-hours · 3 emergency
    var multiplier: Int
    /// Whole percent, snapshot from Settings at creation (refreshed by Re-price).
    var markupPct: Decimal
    /// Snapshot from Settings at creation (refreshed by Re-price).
    var minimumJobCents: Int
    var actualHours: Decimal?
    var notes: String?
    @Relationship(deleteRule: .cascade) var lines: [ProjectLine]

    init(name: String, client: String? = nil, date: Date, hours: Decimal = 0, multiplier: Int = 1,
         markupPct: Decimal, minimumJobCents: Int, actualHours: Decimal? = nil, notes: String? = nil,
         lines: [ProjectLine] = []) {
        self.name = name
        self.client = client
        self.date = date
        self.hours = hours
        self.multiplier = multiplier
        self.markupPct = markupPct
        self.minimumJobCents = minimumJobCents
        self.actualHours = actualHours
        self.notes = notes
        self.lines = lines
    }
}

/// A row as copied into a project: name/unit/rate are snapshots; `item` only links back for Re-price and delete checks.
@Model final class ProjectLine {
    /// nil if the row was deleted later.
    var item: BucketItem?
    var bucket: Bucket
    var name: String
    var unit: String
    var rateCents: Int
    var isOn: Bool
    /// Ignored for hourly rows; user-entered for quantity rows.
    var qty: Decimal
    var actualQty: Decimal?

    init(item: BucketItem?, bucket: Bucket, name: String, unit: String, rateCents: Int, isOn: Bool,
         qty: Decimal = 1, actualQty: Decimal? = nil) {
        self.item = item
        self.bucket = bucket
        self.name = name
        self.unit = unit
        self.rateCents = rateCents
        self.isOn = isOn
        self.qty = qty
        self.actualQty = actualQty
    }

    /// Snapshot a bucket row with the §3.2 defaults: hourly on, quantity off with qty 1.
    convenience init(snapshotOf item: BucketItem) {
        self.init(item: item, bucket: item.bucket, name: item.name, unit: item.unit, rateCents: item.rateCents,
                  isOn: item.bucket.rowKind == .hourly, qty: 1)
    }

    /// Re-copy name/unit/rate from the linked row. No-op when the row is gone (DECISIONS 18).
    func refreshSnapshot() {
        guard let item else { return }
        name = item.name
        unit = item.unit
        rateCents = item.rateCents
    }

    var priceLine: PriceLine {
        PriceLine(bucket: bucket, rateCents: rateCents, isOn: isOn, qty: qty)
    }

    /// The same line with its actual quantity (or the estimate when none was entered) — DECISIONS 31.
    var actualPriceLine: PriceLine {
        PriceLine(bucket: bucket, rateCents: rateCents, isOn: isOn, qty: actualQty ?? qty)
    }
}

// MARK: - Pricing

extension Project {
    var markup: Decimal { markupPct / 100 }

    /// The figures the header shows. Pure Core math on the line snapshots (DECISIONS 1).
    func breakdown(billableHours: Decimal) -> Breakdown {
        Pricer.price(lines: lines.map(\.priceLine), hours: hours, multiplier: multiplier, markup: markup,
                     minimumJobCents: minimumJobCents, billableHours: billableHours)
    }

    /// Estimate vs actual, on cost at the snapshot rates; nil until actual hours are entered (DECISIONS 31).
    func actuals(billableHours: Decimal) -> Actuals? {
        guard let actualHours else { return nil }
        let estimate = breakdown(billableHours: billableHours)
        let actual = Pricer.price(lines: lines.map(\.actualPriceLine), hours: actualHours, multiplier: multiplier,
                                  markup: markup, minimumJobCents: minimumJobCents, billableHours: billableHours)
        return Actuals(estimate: estimate, actual: actual)
    }

    /// Lines in bucket order, then the row order of the Buckets screen; orphaned lines last (DECISIONS 28).
    var sortedLines: [ProjectLine] {
        lines.sorted { a, b in
            if a.bucket != b.bucket { return a.bucket.index < b.bucket.index }
            let sa = a.item?.sortOrder ?? Int.max, sb = b.item?.sortOrder ?? Int.max
            if sa != sb { return sa < sb }
            return a.name.localizedStandardCompare(b.name) == .orderedAscending
        }
    }

    func lines(in bucket: Bucket) -> [ProjectLine] {
        sortedLines.filter { $0.bucket == bucket }
    }
}

/// Estimate vs actual per bucket and in total (BRIEF §3.5).
struct Actuals: Equatable, Sendable {
    var estimate: Breakdown
    var actual: Breakdown

    func variance(_ bucket: Bucket) -> Int { actual[bucket] - estimate[bucket] }
    /// Positive = the job cost more than estimated.
    var totalVariance: Int { actual.cost - estimate.cost }
    /// Whole percent of the estimated cost; nil when the estimate is 0.
    var totalVariancePct: Decimal? {
        estimate.cost == 0 ? nil : Decimal(totalVariance) / Decimal(estimate.cost) * 100
    }
}

extension Bucket {
    var index: Int { Bucket.allCases.firstIndex(of: self) ?? 0 }
}

// MARK: - New / Duplicate / Re-price (DECISIONS 17–20)

extension Project {
    /// A new project: one line per active row, hourly on, quantity off with qty 1; markup and minimum from Settings.
    static func make(name: String = "New project", date: Date, items: [BucketItem], settings: Settings) -> Project {
        let project = Project(name: name, date: date, hours: 0, multiplier: 1,
                              markupPct: settings.markupPctDecimal, minimumJobCents: settings.minimumJobCents)
        project.lines = items.filter(\.isActive).map { ProjectLine(snapshotOf: $0) }
        return project
    }

    /// Everything copied verbatim (snapshots, toggles, quantities, item links, archived or nil included);
    /// name gets " copy", date is today, actuals are cleared. Does not re-snapshot.
    func duplicate(date: Date) -> Project {
        let copy = Project(name: name + " copy", client: client, date: date, hours: hours, multiplier: multiplier,
                           markupPct: markupPct, minimumJobCents: minimumJobCents, actualHours: nil, notes: notes)
        copy.lines = lines.map { line in
            ProjectLine(item: line.item, bucket: line.bucket, name: line.name, unit: line.unit,
                        rateCents: line.rateCents, isOn: line.isOn, qty: line.qty, actualQty: nil)
        }
        return copy
    }

    /// As if the project were created today, keeping toggles, quantities, hours and actuals:
    /// refresh every linked line's snapshot, refresh markup and minimum from Settings,
    /// and append a line for every active row the project lacks.
    func reprice(items: [BucketItem], settings: Settings) {
        for line in lines { line.refreshSnapshot() }
        markupPct = settings.markupPctDecimal
        minimumJobCents = settings.minimumJobCents
        let linked = Set(lines.compactMap { $0.item?.persistentModelID })
        for item in items where item.isActive && !linked.contains(item.persistentModelID) {
            lines.append(ProjectLine(snapshotOf: item))
        }
    }
}
