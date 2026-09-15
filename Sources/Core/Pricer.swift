import Foundation

/// One toggled row as the pricer sees it: the snapshot a `ProjectLine` carries, nothing more.
struct PriceLine: Equatable, Sendable {
    var bucket: Bucket
    /// $/hr cents for labor and equipment; $/yr cents for overhead; unit cost cents for materials and consumables.
    var rateCents: Int
    var isOn: Bool
    /// Used only by quantity rows (materials, consumables).
    var qty: Decimal

    init(bucket: Bucket, rateCents: Int, isOn: Bool = true, qty: Decimal = 1) {
        self.bucket = bucket
        self.rateCents = rateCents
        self.isOn = isOn
        self.qty = qty
    }
}

/// Every figure the Project header shows, in cents, each rounded exactly once (DECISIONS 3).
struct Breakdown: Equatable, Sendable {
    var labor: Int
    var equipment: Int
    var materials: Int
    var consumables: Int
    var overhead: Int
    var cost: Int
    var price: Int
    var profit: Int
    /// Whole percent, e.g. 25.926…; display rounds to one decimal.
    var marginPct: Decimal

    subscript(bucket: Bucket) -> Int {
        switch bucket {
        case .labor: labor
        case .equipment: equipment
        case .materials: materials
        case .consumables: consumables
        case .overhead: overhead
        }
    }

    static let zero = Breakdown(labor: 0, equipment: 0, materials: 0, consumables: 0, overhead: 0,
                                cost: 0, price: 0, profit: 0, marginPct: 0)
}

/// BRIEF §1:
///
///     Hourly = Σ Labor(on) + Σ Equipment(on) + Σ Overhead(on) ÷ billableHours
///     Cost   = Hourly × Hours + Σ Materials(on × qty) + Σ Consumables(on × qty)
///     Price  = max( MinimumJob , Cost × (1 + Markup) × Multiplier )
///     Profit = Price − Cost ;  Margin = Profit ÷ Price
///
/// Pure: no SwiftData, no SwiftUI. Never throws (it runs on every keystroke, DECISIONS 10).
enum Pricer {
    /// - Parameters:
    ///   - lines: the project's line snapshots
    ///   - hours: crew clock hours for the job (negative → 0)
    ///   - multiplier: 1 normal, 2 after-hours, 3 emergency (below 1 → 1)
    ///   - markup: fraction applied once to the whole project (0.35)
    ///   - minimumJobCents: the floor (75000)
    ///   - billableHours: billable hours per year that turns overhead $/yr into $/hr (≤ 0 → overhead contributes 0)
    static func price(
        lines: [PriceLine], hours: Decimal, multiplier: Int, markup: Decimal,
        minimumJobCents: Int, billableHours: Decimal
    ) -> Breakdown {
        let hours = max(hours, 0)
        let multiplier = max(multiplier, 1)

        // Subtotal of each bucket, exact in Decimal cents, rounded once.
        func subtotal(_ bucket: Bucket) -> Int {
            let on = lines.filter { $0.bucket == bucket && $0.isOn }
            switch bucket.rowKind {
            case .hourly:
                let rateSum = Decimal(on.reduce(0) { $0 + $1.rateCents })
                if bucket.isAnnual {
                    guard billableHours > 0 else { return 0 }
                    return Money.cents(rateSum * hours / billableHours)
                }
                return Money.cents(rateSum * hours)
            case .quantity:
                let exact = on.reduce(Decimal(0)) { $0 + Decimal($1.rateCents) * max($1.qty, 0) }
                return Money.cents(exact)
            }
        }

        let labor = subtotal(.labor)
        let equipment = subtotal(.equipment)
        let materials = subtotal(.materials)
        let consumables = subtotal(.consumables)
        let overhead = subtotal(.overhead)

        let cost = labor + equipment + materials + consumables + overhead
        let marked = Money.cents(Decimal(cost) * (1 + markup) * Decimal(multiplier))
        let price = max(minimumJobCents, marked)
        let profit = price - cost
        let marginPct: Decimal = price > 0 ? Decimal(profit) / Decimal(price) * 100 : 0

        return Breakdown(labor: labor, equipment: equipment, materials: materials,
                         consumables: consumables, overhead: overhead,
                         cost: cost, price: price, profit: profit, marginPct: marginPct)
    }
}
