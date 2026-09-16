import Foundation

/// The six fixed lists. Order here is the display order everywhere (DECISIONS 32).
/// Subcontractors joined as the sixth bucket on 2026-09-16 (DECISIONS 60): quantity rows, flat and all-in,
/// each belonging to a `Subcontractor` record.
enum Bucket: String, Codable, CaseIterable, Sendable {
    case labor, equipment, materials, consumables, subcontractors, overhead

    enum RowKind: Sendable { case hourly, quantity }

    /// Labor, Equipment, Overhead contribute `rate × project hours`; Materials, Consumables contribute `rate × qty`.
    var rowKind: RowKind {
        switch self {
        case .labor, .equipment, .overhead: .hourly
        case .materials, .consumables, .subcontractors: .quantity
        }
    }

    var title: String {
        switch self {
        case .labor: "Labor"
        case .equipment: "Equipment"
        case .materials: "Materials"
        case .consumables: "Consumables"
        case .subcontractors: "Subcontractors"
        case .overhead: "Overhead"
        }
    }

    /// Hourly buckets have a fixed unit (DECISIONS 25); quantity buckets are free text.
    var fixedUnit: String? {
        switch self {
        case .labor, .equipment: "hr"
        case .overhead: "yr"
        case .materials, .consumables, .subcontractors: nil
        }
    }

    /// Whether the row's stored rate is an annual figure shown and priced as $/yr ÷ billable hours.
    var isAnnual: Bool { self == .overhead }
}
