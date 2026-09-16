import Foundation

/// One toggled row as the pricer sees it: the snapshot a `ProjectLine` carries, nothing more.
struct PriceLine: Equatable, Sendable {
    var bucket: Bucket
    /// $/hr cents for labor and equipment; $/yr cents for overhead; unit cost cents for materials and consumables.
    var rateCents: Int
    var isOn: Bool
    /// Used only by quantity rows (materials, consumables).
    var qty: Decimal

    /// `isOn` defaults to the §3.2 rule: hourly rows on, quantity rows off.
    init(bucket: Bucket, rateCents: Int, isOn: Bool? = nil, qty: Decimal = 1) {
        self.bucket = bucket
        self.rateCents = rateCents
        self.isOn = isOn ?? (bucket.rowKind == .hourly)
        self.qty = qty
    }
}

/// How Price is derived from Cost (DECISIONS 70): the brief's markup, or the owner's target margin.
///   .markup(0.35)       Price = Cost × 1.35
///   .targetMargin(50)   Price = Cost ÷ (1 − 0.50) = Cost × 100 ÷ (100 − 50), computed as ONE division so a
///                       terminating result (50% → exactly ×2) is exact and no half-cent tie can drift.
enum PriceRule: Equatable, Sendable {
    case markup(Decimal)
    case targetMargin(Decimal)

    /// The equivalent markup as a whole percent, for display: 50% margin = 100% markup.
    var markupPercent: Decimal {
        switch self {
        case .markup(let f):
            return f * 100
        case .targetMargin(let m):
            let m = m.isNaN ? 0 : max(0, min(m, PriceRule.maximumMarginPct))
            return m / (100 - m) * 100
        }
    }

    /// Margins are held below this so the division never explodes (a 95% margin is already ×20).
    static let maximumMarginPct: Decimal = 95
}

/// Every figure the Project header shows, in cents, each rounded exactly once (DECISIONS 3).
/// `marginPct` is the one figure left unrounded; the view formats it to one decimal.
struct Breakdown: Equatable, Sendable {
    var labor: Int
    var equipment: Int
    var materials: Int
    var consumables: Int
    var subcontractors: Int
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
        case .subcontractors: subcontractors
        case .overhead: overhead
        }
    }

    static let zero = Breakdown(labor: 0, equipment: 0, materials: 0, consumables: 0, subcontractors: 0, overhead: 0,
                                cost: 0, price: 0, profit: 0, marginPct: 0)
}

/// BRIEF §1:
///
///     Hourly = Σ Labor(on) + Σ Equipment(on) + Σ Overhead(on) ÷ billableHours
///     Cost   = Hourly × Hours + Σ Materials(on × qty) + Σ Consumables(on × qty)
///     Price  = max( MinimumJob , Cost × (1 + Markup) × Multiplier )
///     Profit = Price − Cost ;  Margin = Profit ÷ Price
///
/// Pure: no SwiftData, no SwiftUI. Never throws or traps (it runs on every keystroke, DECISIONS 10):
/// negative or non-finite inputs are treated as 0, the multiplier is held to 1…3, and all sums are
/// carried in `Decimal` so no Int arithmetic can overflow.
enum Pricer {
    /// - Parameters:
    ///   - lines: the project's line snapshots
    ///   - hours: crew clock hours for the job (negative → 0)
    ///   - multiplier: 1 normal, 2 after-hours, 3 emergency (held to 1…3)
    ///   - markup: fraction applied once to the whole project (0.35; negative → 0)
    ///   - minimumJobCents: the floor (75000; negative → 0)
    ///   - billableHours: billable hours per year that turns overhead $/yr into $/hr (≤ 0 → overhead contributes 0)
    static func price(
        lines: [PriceLine], hours: Decimal, multiplier: Int, markup: Decimal,
        minimumJobCents: Int, billableHours: Decimal
    ) -> Breakdown {
        price(lines: lines, hours: hours, multiplier: multiplier, rule: .markup(markup),
              minimumJobCents: minimumJobCents, billableHours: billableHours)
    }

    static func price(
        lines: [PriceLine], hours: Decimal, multiplier: Int, rule: PriceRule,
        minimumJobCents: Int, billableHours: Decimal
    ) -> Breakdown {
        let hours = nonNegative(hours)
        let multiplier = min(max(multiplier, 1), 3)
        let minimumJobCents = max(minimumJobCents, 0)
        let billableHours = nonNegative(billableHours)

        // Subtotal of each bucket, exact in Decimal cents, rounded once.
        func subtotal(_ bucket: Bucket) -> Int {
            let on = lines.filter { $0.bucket == bucket && $0.isOn }
            switch bucket.rowKind {
            case .hourly:
                let rateSum = on.reduce(Decimal(0)) { $0 + Decimal(max($1.rateCents, 0)) }
                if bucket.isAnnual {
                    guard billableHours > 0 else { return 0 }
                    return Money.cents(rateSum * hours / billableHours)
                }
                return Money.cents(rateSum * hours)
            case .quantity:
                let exact = on.reduce(Decimal(0)) { $0 + Decimal(max($1.rateCents, 0)) * nonNegative($1.qty) }
                return Money.cents(exact)
            }
        }

        let labor = subtotal(.labor)
        let equipment = subtotal(.equipment)
        let materials = subtotal(.materials)
        let consumables = subtotal(.consumables)
        let subcontractors = subtotal(.subcontractors)
        let overhead = subtotal(.overhead)

        let exactCost = Decimal(labor) + Decimal(equipment) + Decimal(materials) + Decimal(consumables)
            + Decimal(subcontractors) + Decimal(overhead)
        let cost = Money.cents(exactCost)
        let marked: Int
        switch rule {
        case .markup(let markup):
            marked = Money.cents(Decimal(cost) * (1 + nonNegative(markup)) * Decimal(multiplier))
        case .targetMargin(let pct):
            let margin = min(nonNegative(pct), PriceRule.maximumMarginPct)
            marked = Money.cents(Decimal(cost) * 100 * Decimal(multiplier) / (100 - margin))
        }
        let price = max(minimumJobCents, marked)
        let profit = Money.cents(Decimal(price) - Decimal(cost))
        let marginPct: Decimal = price > 0 ? Decimal(profit) / Decimal(price) * 100 : 0

        return Breakdown(labor: labor, equipment: equipment, materials: materials,
                         consumables: consumables, subcontractors: subcontractors, overhead: overhead,
                         cost: cost, price: price, profit: profit, marginPct: marginPct)
    }

    private static func nonNegative(_ x: Decimal) -> Decimal {
        x.isFinite && x > 0 ? x : 0
    }
}
