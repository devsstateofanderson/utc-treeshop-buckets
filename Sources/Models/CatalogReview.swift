import Foundation
import SwiftData

// MARK: - Row trust and review (DECISIONS 72)

extension BucketItem {
    /// `missing` until someone reviews the row. Stored as `confidenceRaw`; `missing` is stored as nil so a
    /// store from before this field existed reads the same as a row that was never reviewed.
    var confidence: Confidence {
        get { confidenceRaw.flatMap(Confidence.init(rawValue:)) ?? .missing }
        set { confidenceRaw = newValue == .missing ? nil : newValue.rawValue }
    }

    /// Something a reviewer can go back to: a source, an evidence note, or a link.
    var hasEvidence: Bool {
        [source, evidence, link].contains { !($0 ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    /// Verified needs evidence and a checked date (issue #3 §3); nothing else can make a row verified.
    var canMarkVerified: Bool { hasEvidence && checkedAt != nil }

    func isOverdue(now: Date = .now) -> Bool { reviewDueAt.map { $0 < now } ?? false }

    /// nil when the row is resolved. Precedence: missing → owner confirmation → overdue → estimated, so a
    /// row waits in exactly one group and the group counts add up.
    func unresolvedReason(now: Date = .now) -> UnresolvedReason? {
        if confidence == .missing { return .missing }
        if needsOwnerConfirmation { return .ownerConfirmation }
        if isOverdue(now: now) { return .overdue }
        return confidence == .estimated ? .estimated : nil
    }

    func isResolved(now: Date = .now) -> Bool { unresolvedReason(now: now) == nil }

    /// Marks the row verified; false (and no change) when the evidence or the checked date is missing.
    @discardableResult
    func markVerified() -> Bool {
        guard canMarkVerified else { return false }
        confidence = .verified
        return true
    }

    /// The owner's sign-off: trusted without external evidence, and the confirmation request is cleared.
    func markOwnerConfirmed(now: Date = .now) {
        confidence = .ownerConfirmed
        needsOwnerConfirmation = false
        if checkedAt == nil { checkedAt = now }
    }

    /// Checked today; the review comes due in a year unless a date is already set.
    func markChecked(now: Date = .now) {
        checkedAt = now
        if reviewDueAt == nil { reviewDueAt = Calendar.current.date(byAdding: .year, value: 1, to: now) }
    }

    enum ReviewSeverity: Sendable { case ok, attention, overdue }

    func reviewSeverity(now: Date = .now) -> ReviewSeverity {
        switch unresolvedReason(now: now) {
        case nil: .ok
        case .overdue: .overdue
        default: .attention
        }
    }

    /// "Verified · Sep 16, 2026", "Estimated", "Missing", "Overdue · due Sep 1, 2026", "Owner to confirm".
    func reviewLabel(now: Date = .now) -> String {
        switch unresolvedReason(now: now) {
        case nil:
            return checkedAt.map { "\(confidence.title) · \(Self.shortDate($0))" } ?? confidence.title
        case .missing: return "Missing"
        case .estimated: return "Estimated"
        case .overdue: return reviewDueAt.map { "Overdue · due \(Self.shortDate($0))" } ?? "Overdue"
        case .ownerConfirmation: return "Owner to confirm"
        }
    }

    /// Copies the review fields a file carries; fields the file omits stay. Verified without evidence and a
    /// checked date drops to estimated, so a hand-edited file cannot vouch for a row the app would not.
    func applyReview(from record: TransferDocument.Item) {
        if let v = record.evidence { evidence = v }
        if let v = record.checkedAt { checkedAt = v }
        if let v = record.reviewDueAt { reviewDueAt = v }
        if let v = record.approvedBy { approvedBy = v }
        if let v = record.assumption { assumption = v }
        if let v = record.needsOwnerConfirmation { needsOwnerConfirmation = v }
        if let c = record.confidence { confidence = c }
        if confidence == .verified && !canMarkVerified { confidence = .estimated }
    }

    /// Whether the file's review fields would change nothing (the merge's "unchanged" test).
    func reviewMatches(_ record: TransferDocument.Item) -> Bool {
        evidence == (record.evidence ?? evidence) && checkedAt == (record.checkedAt ?? checkedAt)
            && reviewDueAt == (record.reviewDueAt ?? reviewDueAt) && approvedBy == (record.approvedBy ?? approvedBy)
            && assumption == (record.assumption ?? assumption)
            && needsOwnerConfirmation == (record.needsOwnerConfirmation ?? needsOwnerConfirmation)
            && confidence == (record.confidence ?? confidence)
    }

    static func shortDate(_ date: Date) -> String {
        date.formatted(Date.FormatStyle(date: .abbreviated, time: .omitted).locale(Locale(identifier: "en_US")))
    }
}

/// The Buckets table's "Show" menu (DECISIONS 72): every row, the unresolved ones, or one reason.
enum ReviewFilter: Hashable, Sendable {
    case all, unresolved, reason(UnresolvedReason)

    static let allCases: [ReviewFilter] = [.all, .unresolved] + UnresolvedReason.allCases.map(ReviewFilter.reason)

    var title: String {
        switch self {
        case .all: "All rows"
        case .unresolved: "Unresolved"
        case .reason(let r): r.title
        }
    }

    func includes(_ item: BucketItem, now: Date = .now) -> Bool {
        switch self {
        case .all: true
        case .unresolved: !item.isResolved(now: now)
        case .reason(let r): item.unresolvedReason(now: now) == r
        }
    }
}

// MARK: - Estimate visibility (issue #3 §4)

extension Project {
    /// Enabled lines whose current row is unresolved. The estimate still prices from its snapshots
    /// (DECISIONS 17); this only says which inputs deserve a look.
    func unresolvedEnabledLines(now: Date = .now) -> [ProjectLine] {
        sortedLines.filter { $0.isOn && $0.item?.unresolvedReason(now: now) != nil }
    }
}

extension ProjectLine {
    /// The warning caption for an enabled line whose row is unresolved; nil otherwise. Deleted and archived
    /// rows keep their own `statusCaption`.
    func reviewCaption(now: Date = .now) -> String? {
        guard isOn, let item, let reason = item.unresolvedReason(now: now) else { return nil }
        return reason.caption
    }
}
