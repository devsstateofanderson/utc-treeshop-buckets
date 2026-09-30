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
    /// Whole percent. Before DECISIONS 70 this was the input; now it is the markup equivalent of the target margin,
    /// kept for display and for projects created before margins existed (`targetMarginPct == nil`).
    var markupPct: Decimal
    /// The target profit margin this project prices at, whole percent, snapshot from the company defaults (DECISIONS 70).
    var targetMarginPct: Decimal?
    /// Snapshot from Settings at creation (refreshed by Re-price).
    var minimumJobCents: Int
    var actualHours: Decimal?
    var notes: String?
    /// A package: a pre-built project used as a starting point, listed under Packages (DECISIONS 61).
    var isTemplate: Bool = false
    /// Name of the loadout last applied, cleared when a labor or equipment toggle is changed by hand (DECISIONS 62).
    var crewName: String?
    @Relationship(deleteRule: .cascade) var lines: [ProjectLine]
    /// Snapshots of the company's sales allowance and payroll tax on commission, whole percents, set with the target
    /// margin and refreshed by Re-price (DECISIONS 92). nil reads as 0 (a project from before the allowance).
    var salesAllowancePct: Decimal?
    var commissionBurdenPct: Decimal?
    /// Sold by (DECISIONS 94): the Labor row of the person who sold the job. Nullified if the row is deleted.
    var salesperson: BucketItem?
    /// The person's name when picked; survives archiving or deletion of the row.
    var salespersonName: String?
    /// The person's commission % when picked, refreshed from the row by Re-price while the link exists (17, 18).
    var commissionPct: Decimal?
    /// The negotiated %, typed on the project; never refreshed. Effective C = override ?? snapshot.
    var commissionPctOverride: Decimal?

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

    /// Target margin with the snapshot allowance and payroll tax when the project has a margin, else the legacy
    /// markup, which ignores the allowance (DECISIONS 70, 92).
    var pricingRule: PriceRule {
        targetMarginPct.map { .targetMargin($0, allowance: salesAllowancePct ?? 0, burden: commissionBurdenPct ?? 0) }
            ?? .markup(markup)
    }

    /// Snapshots the company's pricing defaults: the target margin, the sales allowance and its payroll tax, the
    /// minimum, and for display the markup equivalent (DECISIONS 70, 92).
    func setPricing(from settings: AppSettings) {
        targetMarginPct = settings.targetMarginPctDecimal
        salesAllowancePct = settings.salesAllowancePctDecimal
        commissionBurdenPct = settings.commissionBurdenPctDecimal
        markupPct = Project.rounded2(settings.pricingRule.markupPercent)
        minimumJobCents = settings.minimumJobCents
    }

    /// Whether a Sold by is set: the linked row, or the name kept after the row was deleted (DECISIONS 94).
    var hasSalesperson: Bool {
        salesperson != nil || !(salespersonName ?? "").trimmingCharacters(in: .whitespaces).isEmpty
    }

    /// The commission % this job pays: the override when set, else the person's snapshot; 0 without a salesperson,
    /// whatever override remains. Held to 0…100 (DECISIONS 92, 94).
    var effectiveCommissionPct: Decimal {
        guard hasSalesperson else { return 0 }
        return PriceRule.percent(commissionPctOverride ?? commissionPct ?? 0)
    }

    /// What the Pricer needs to compute the commission: C, the snapshot payroll tax and the base (the price until a
    /// sold price exists).
    var commissionTerms: CommissionTerms {
        CommissionTerms(pct: effectiveCommissionPct, burdenPct: commissionBurdenPct ?? 0)
    }

    /// Picks the person who sold the job, or clears it (nil): the link, the name and the % snapshot. The override
    /// stays as typed; without a salesperson it pays nothing. Packages never carry a salesperson (DECISIONS 94).
    func setSalesperson(_ item: BucketItem?) {
        guard !isTemplate || item == nil else { return }
        salesperson = item
        salespersonName = item?.name
        commissionPct = item?.commissionPct
    }

    static func rounded2(_ x: Decimal) -> Decimal {
        var value = x, out = Decimal()
        NSDecimalRound(&out, &value, 2, .plain)
        return out
    }

    /// One decimal, as the header displays a margin (half away from zero).
    static func rounded1(_ x: Decimal) -> Decimal {
        var value = x, out = Decimal()
        NSDecimalRound(&out, &value, 1, .plain)
        return out
    }

    /// The figures the header shows. Pure Core math on the line snapshots (DECISIONS 1).
    func breakdown(billableHours: Decimal) -> Breakdown {
        Pricer.price(lines: lines.map(\.priceLine), hours: hours, multiplier: multiplier, rule: pricingRule,
                     commission: commissionTerms, minimumJobCents: minimumJobCents, billableHours: billableHours)
    }

    /// Estimate vs actual, on cost at the snapshot rates; nil until actual hours are entered (DECISIONS 31).
    func actuals(billableHours: Decimal) -> Actuals? {
        guard let actualHours else { return nil }
        let estimate = breakdown(billableHours: billableHours)
        let actual = Pricer.price(lines: lines.map(\.actualPriceLine), hours: actualHours, multiplier: multiplier,
                                  rule: pricingRule, commission: commissionTerms, minimumJobCents: minimumJobCents,
                                  billableHours: billableHours)
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
    /// A new project: one line per active, priced row (track-only rows are skipped, DECISIONS 83), hourly on,
    /// quantity off with qty 1; the pricing defaults from Settings.
    static func make(name: String = "New project", date: Date, items: [BucketItem], settings: AppSettings) -> Project {
        let project = Project(name: name, date: date, hours: 0, multiplier: 1,
                              markupPct: 0, minimumJobCents: settings.minimumJobCents)
        project.setPricing(from: settings)
        project.lines = items.filter { $0.isActive && !$0.trackOnly }.map { ProjectLine(snapshotOf: $0) }
        return project
    }

    /// Everything copied verbatim (snapshots, toggles, quantities, item links, archived or nil included);
    /// name gets " copy", date is today, actuals are cleared. Does not re-snapshot.
    func duplicate(date: Date) -> Project {
        let copy = Project(name: name + " copy", client: client, date: date, hours: hours, multiplier: multiplier,
                           markupPct: markupPct, minimumJobCents: minimumJobCents, actualHours: nil, notes: notes)
        copy.isTemplate = isTemplate
        copy.crewName = crewName
        copy.targetMarginPct = targetMarginPct
        copy.salesAllowancePct = salesAllowancePct
        copy.commissionBurdenPct = commissionBurdenPct
        // The sale terms travel with a copy (DECISIONS 94); a package never has any to copy.
        copy.salesperson = salesperson
        copy.salespersonName = salespersonName
        copy.commissionPct = commissionPct
        copy.commissionPctOverride = commissionPctOverride
        copy.lines = lines.map { line in
            ProjectLine(item: line.item, bucket: line.bucket, name: line.name, unit: line.unit,
                        rateCents: line.rateCents, isOn: line.isOn, qty: line.qty, actualQty: nil)
        }
        return copy
    }

    /// A new project from this package: everything copied, today's date, today's rates, markup and minimum
    /// (DECISIONS 61). The package itself is untouched.
    func instantiate(date: Date, items: [BucketItem], settings: AppSettings) -> Project {
        let project = duplicate(date: date)
        project.name = name
        project.isTemplate = false
        project.reprice(items: items, settings: settings)
        return project
    }

    /// This project saved as a package under the same name (DECISIONS 61). A package carries no salesperson and no
    /// override, as it carries no actuals (DECISIONS 94).
    func asPackage(date: Date) -> Project {
        let package = duplicate(date: date)
        package.name = name
        package.isTemplate = true
        package.clearSaleTerms()
        return package
    }

    /// Sold by, the name and % snapshots and the override, all cleared.
    func clearSaleTerms() {
        salesperson = nil
        salespersonName = nil
        commissionPct = nil
        commissionPctOverride = nil
    }

    /// Applies a crew formation (DECISIONS 62): every labor and equipment line is turned on when its row is in the
    /// loadout and off otherwise; active member rows the project lacks are appended (on). Other buckets are untouched.
    /// A track-only member is not crew (DECISIONS 83): its line is never turned on and never appended.
    func apply(_ loadout: Loadout) {
        let members = Set(loadout.members.filter { !$0.trackOnly }.map(\.persistentModelID))
        for line in lines where line.bucket == .labor || line.bucket == .equipment {
            line.isOn = line.item.map { members.contains($0.persistentModelID) } ?? false
        }
        let linked = Set(lines.compactMap { $0.item?.persistentModelID })
        for item in loadout.sortedMembers where item.isActive && !item.trackOnly && !linked.contains(item.persistentModelID) {
            let line = ProjectLine(snapshotOf: item)
            line.isOn = true
            lines.append(line)
        }
        crewName = loadout.name
    }

    /// As if the project were created today, keeping toggles, quantities, hours and actuals:
    /// refresh every linked line's snapshot, refresh the pricing defaults (margin, allowance, payroll tax on
    /// commission, minimum) from AppSettings, refresh the salesperson's name and % from the linked row (the override
    /// stays, DECISIONS 94), and append a line for every active row the project lacks. A track-only row is skipped: no
    /// line is appended for it and an existing line keeps its snapshot (DECISIONS 83).
    func reprice(items: [BucketItem], settings: AppSettings) {
        for line in lines where !(line.item?.trackOnly ?? false) { line.refreshSnapshot() }
        setPricing(from: settings)
        if let row = salesperson {
            salespersonName = row.name
            commissionPct = row.commissionPct
        }
        let linked = Set(lines.compactMap { $0.item?.persistentModelID })
        for item in items where item.isActive && !item.trackOnly && !linked.contains(item.persistentModelID) {
            lines.append(ProjectLine(snapshotOf: item))
        }
    }

    /// Whether this package prices under a sales allowance other than today's (DECISIONS 92): its snapshot share
    /// `A·(100 + B)` differs from the company's. Legacy markup packages ignore the allowance and never count.
    func isPricedUnderOlderAllowance(_ settings: AppSettings) -> Bool {
        guard targetMarginPct != nil else { return false }
        return Project.allowanceShare(salesAllowancePct ?? 0, commissionBurdenPct ?? 0)
            != Project.allowanceShare(settings.salesAllowancePctDecimal, settings.commissionBurdenPctDecimal)
    }

    /// `A·(100 + B)`, both held to 0…100; 0 whenever A is 0, whatever B is.
    static func allowanceShare(_ allowance: Decimal, _ burden: Decimal) -> Decimal {
        let a = PriceRule.percent(allowance)
        return a == 0 ? 0 : a * (100 + PriceRule.percent(burden))
    }

    /// Packages priced under an older allowance, for the Company screen's banner (DECISIONS 92).
    static func templatesUnderOlderAllowance(_ projects: [Project], settings: AppSettings) -> Int {
        projects.filter { $0.isTemplate && $0.isPricedUnderOlderAllowance(settings) }.count
    }

    /// Re-price packages (DECISIONS 92): Re-price every package at today's rates and defaults so no list price is
    /// stale. Ordinary projects are untouched. Returns how many packages were priced under an older allowance.
    @discardableResult
    static func repriceTemplates(_ projects: [Project], items: [BucketItem], settings: AppSettings) -> Int {
        let templates = projects.filter(\.isTemplate)
        let stale = templates.filter { $0.isPricedUnderOlderAllowance(settings) }.count
        for template in templates { template.reprice(items: items, settings: settings) }
        return stale
    }

    /// The same over a store.
    @MainActor
    @discardableResult
    static func repriceTemplates(in context: ModelContext, settings: AppSettings) throws -> Int {
        let projects = try context.fetch(FetchDescriptor<Project>())
        let items = try context.fetch(FetchDescriptor<BucketItem>())
        let stale = repriceTemplates(projects, items: items, settings: settings)
        try context.save()
        return stale
    }
}
