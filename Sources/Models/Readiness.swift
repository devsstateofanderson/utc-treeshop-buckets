import Foundation

/// What still stands between this company and a pricing it can defend (roadmap Release 1 §1; issue #3 §2).
/// Plain data computed from the rows, the company profile and the settings; the Company screen renders it
/// (DECISIONS 73). "Ready" is never claimed while a required setup input is unresolved.
struct Readiness: Equatable {
    enum Status: Equatable {
        case notReady(missingInputs: Int)
        case needsReview(unresolvedRows: Int)
        case ready

        var title: String {
            switch self {
            case .notReady: "Not ready"
            case .needsReview: "Needs review"
            case .ready: "Ready"
            }
        }

        var detail: String {
            switch self {
            case .notReady(let n): "\(n) setup \(n == 1 ? "input" : "inputs") unresolved."
            case .needsReview(let n): "\(n) active catalog \(n == 1 ? "row" : "rows") unresolved."
            case .ready: "Every setup input and every active row is resolved."
            }
        }
    }

    struct SetupInput: Equatable, Identifiable {
        var id: String { title }
        var title: String
        var isResolved: Bool
        var detail: String
    }

    struct BucketSummary: Equatable, Identifiable {
        var id: Bucket { bucket }
        var bucket: Bucket
        var active: Int
        var resolved: Int
        var lastVerified: Date?
        /// Whole percent of active rows that are resolved; 0 with no rows.
        var completionPct: Int { active == 0 ? 0 : Int((Double(resolved) / Double(active) * 100).rounded()) }
    }

    var setupInputs: [SetupInput]
    var buckets: [BucketSummary]
    var unresolved: [UnresolvedReason: Int]
    /// The first bucket (in bucket order) holding a row in each group, for the "Show" buttons.
    var firstBucket: [UnresolvedReason: Bucket]
    var lastVerified: Date?

    var unresolvedTotal: Int { unresolved.values.reduce(0, +) }
    var missingInputs: Int { setupInputs.filter { !$0.isResolved }.count }

    var status: Status {
        if missingInputs > 0 { return .notReady(missingInputs: missingInputs) }
        if unresolvedTotal > 0 { return .needsReview(unresolvedRows: unresolvedTotal) }
        return .ready
    }

    /// Active rows only: archived rows are hidden from new projects, and the projects that still use them get
    /// their own warning on the Project screen. The Labor and Equipment gates count priced rows: a track-only row
    /// (a salaried manager "not on the crew", DECISIONS 83, 93) does not make a crew, and is listed separately.
    init(items: [BucketItem], company: Company?, settings: AppSettings, now: Date = .now) {
        let active = items.filter(\.isActive)
        func count(_ bucket: Bucket) -> Int { active.filter { $0.bucket == bucket }.count }
        func priced(_ bucket: Bucket) -> Int { active.filter { $0.bucket == bucket && !$0.trackOnly }.count }
        func rowsDetail(_ bucket: Bucket) -> String {
            let n = count(bucket)
            return n == 0 ? "none yet" : "\(n) active \(n == 1 ? "row" : "rows")"
        }
        /// "3 active rows", or with track-only rows "3 priced · 1 not on the crew" (Labor) / "· 1 track only" (Equipment).
        func crewDetail(_ bucket: Bucket) -> String {
            let tracked = count(bucket) - priced(bucket)
            guard tracked > 0 else { return rowsDetail(bucket) }
            let n = priced(bucket)
            return "\(n == 0 ? "none" : "\(n)") priced · \(tracked) \(bucket.trackOnlyLabel.lowercased())"
        }
        let name = (company?.name ?? "").trimmingCharacters(in: .whitespaces)
        let area = (company?.serviceArea ?? "").trimmingCharacters(in: .whitespaces)
        let radius = company?.serviceRadiusMiles ?? 0
        let zone = (company?.growingZone ?? "").trimmingCharacters(in: .whitespaces)
        let areaDetail = [area.isEmpty ? nil : area, radius > 0 ? "\(radius)-mile radius" : nil, zone.isEmpty ? nil : zone]
            .compactMap { $0 }.joined(separator: " · ")
        setupInputs = [
            .init(title: "Company name", isResolved: !name.isEmpty, detail: name.isEmpty ? "not set" : name),
            .init(title: "Service area", isResolved: !area.isEmpty || radius > 0, detail: areaDetail.isEmpty ? "not set" : areaDetail),
            .init(title: "Billable hours", isResolved: settings.billableHoursPerYear >= 1,
                  detail: "\(settings.billableHoursPerYear.formatted(.number.locale(Locale(identifier: "en_US")))) hours per year"),
            .init(title: "Target margin", isResolved: settings.targetMarginPct > 0,
                  detail: settings.targetMarginPct > 0 ? "\(settings.targetMarginPctDecimal)%" : "not set"),
            .init(title: "Minimum job", isResolved: settings.minimumJobCents > 0,
                  detail: settings.minimumJobCents > 0 ? Money.format(settings.minimumJobCents) : "not set"),
            .init(title: "Labor rows", isResolved: priced(.labor) > 0, detail: crewDetail(.labor)),
            .init(title: "Equipment rows", isResolved: priced(.equipment) > 0, detail: crewDetail(.equipment)),
            .init(title: "Overhead rows", isResolved: count(.overhead) > 0, detail: rowsDetail(.overhead)),
        ]
        buckets = Bucket.allCases.map { bucket in
            let rows = active.filter { $0.bucket == bucket }
            return BucketSummary(bucket: bucket, active: rows.count, resolved: rows.filter { $0.isResolved(now: now) }.count,
                                 lastVerified: rows.filter { $0.confidence.isTrusted }.compactMap(\.checkedAt).max())
        }
        var counts: [UnresolvedReason: Int] = [:]
        var first: [UnresolvedReason: Bucket] = [:]
        for item in active.sorted(by: { $0.bucket.index < $1.bucket.index }) {
            guard let reason = item.unresolvedReason(now: now) else { continue }
            counts[reason, default: 0] += 1
            if first[reason] == nil { first[reason] = item.bucket }
        }
        unresolved = counts
        firstBucket = first
        lastVerified = buckets.compactMap(\.lastVerified).max()
    }
}

extension Bucket {
    /// What a track-only row is called in this bucket (DECISIONS 83): "Not on the crew" for Labor, "Track only" elsewhere.
    var trackOnlyLabel: String { self == .labor ? "Not on the crew" : "Track only" }
}
