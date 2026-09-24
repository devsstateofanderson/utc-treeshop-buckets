import Foundation

/// How far a catalog row's figure can be trusted (Buckets Pro roadmap, Release 1 §2; issue #3).
/// Stored on the row as its raw value; a row that has never been reviewed is `missing`.
enum Confidence: String, Codable, CaseIterable, Sendable {
    case missing, estimated, ownerConfirmed, verified

    var title: String {
        switch self {
        case .missing: "Missing"
        case .estimated: "Estimated"
        case .ownerConfirmed: "Owner confirmed"
        case .verified: "Verified"
        }
    }

    /// A figure the company stands behind: checked against evidence, or confirmed by the owner.
    var isTrusted: Bool { self == .verified || self == .ownerConfirmed }
}

/// Why a row still needs attention. Every unresolved row is in exactly one group (see
/// `BucketItem.unresolvedReason`), so the readiness counts add up to the unresolved total.
/// The case order is the display order.
enum UnresolvedReason: String, CaseIterable, Sendable {
    case missing, estimated, overdue, ownerConfirmation

    var title: String {
        switch self {
        case .missing: "Missing"
        case .estimated: "Estimated"
        case .overdue: "Review overdue"
        case .ownerConfirmation: "Owner confirmation needed"
        }
    }

    /// The short caption a project line shows next to its toggle.
    var caption: String {
        switch self {
        case .missing: "no source yet"
        case .estimated: "estimated"
        case .overdue: "review overdue"
        case .ownerConfirmation: "needs owner confirmation"
        }
    }
}
