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

/// How Price is derived from Cost (DECISIONS 70, 92): the brief's markup, or the owner's target margin with an
/// optional sales allowance.
///   .markup(0.35)                             Price = Cost × 1.35
///   .targetMargin(50)                         Price = Cost ÷ (1 − 0.50) = Cost × 100 ÷ (100 − 50), computed as ONE
///                                             division so a terminating result (50% → exactly ×2) is exact and no
///                                             half-cent tie can drift.
///   .targetMargin(50, allowance: 7, burden: 7.65)
///                                             Price = Cost × 10000 ÷ (10000 − 100·M − A·(100 + B)): the share of every
///                                             price set aside for sales commission (A) and its employer payroll tax
///                                             (B, a percent of the commission) sits in the same one division, so
///                                             margin M is what is left after the commission is paid. A = 0 keeps the
///                                             margin-only expression above, byte for byte.
enum PriceRule: Sendable {
    case markup(Decimal)
    /// Whole percents: the target margin after commission, the sales allowance, and the payroll tax on commission.
    case targetMargin(Decimal, allowance: Decimal = 0, burden: Decimal = 0)

    /// The equivalent markup as a whole percent, for display: 50% margin = 100% markup; 50/7/7.65 = 135.49%.
    var markupPercent: Decimal {
        switch self {
        case .markup(let f):
            return f * 100
        case .targetMargin(let m, let allowance, let burden):
            let m = m.isNaN ? 0 : max(0, min(m, PriceRule.maximumMarginPct))
            let a = PriceRule.percent(allowance)
            guard a > 0 else { return m / (100 - m) * 100 }
            let share = PriceRule.share(margin: m, allowance: a, burden: PriceRule.percent(burden))
            return share / (10000 - share) * 100
        }
    }

    /// Margins are held below this so the division never explodes (a 95% margin is already ×20).
    static let maximumMarginPct: Decimal = 95

    /// `100·M + A·(100 + B)` in hundredths of a percent, held to 9,500 (95%) so a price always exists (DECISIONS 92).
    /// M, A and B are whole percents already clamped by the caller.
    static func share(margin: Decimal, allowance: Decimal, burden: Decimal) -> Decimal {
        min(100 * margin + allowance * (100 + burden), 100 * maximumMarginPct)
    }

    /// A whole percent held to 0…100; negative or non-finite → 0 (DECISIONS 10, 92).
    static func percent(_ x: Decimal) -> Decimal {
        guard x.isFinite, x > 0 else { return 0 }
        return min(x, 100)
    }
}

/// Two rules are equal when they price every cost identically: with no allowance the payroll tax on commission
/// has nothing to act on, so `.targetMargin(50)` equals `.targetMargin(50, allowance: 0, burden: 7.65)`.
extension PriceRule: Equatable {
    static func == (lhs: PriceRule, rhs: PriceRule) -> Bool {
        switch (lhs, rhs) {
        case let (.markup(a), .markup(b)):
            return a == b
        case let (.targetMargin(m1, a1, b1), .targetMargin(m2, a2, b2)):
            let x1 = percent(a1), x2 = percent(a2)
            return m1 == m2 && x1 == x2 && (x1 == 0 || percent(b1) == percent(b2))
        default:
            return false
        }
    }
}

/// The commission terms of one project (DECISIONS 92, 94): the effective commission % paid on it, the payroll tax on
/// each commission dollar, and the base the commission is paid on (`soldPriceCents ?? price`; until a sold price
/// exists it is the price). Whole percents. `.none` pays no commission.
struct CommissionTerms: Equatable, Sendable {
    var pct: Decimal
    var burdenPct: Decimal
    /// nil = the computed price.
    var baseCents: Int?

    init(pct: Decimal, burdenPct: Decimal, baseCents: Int? = nil) {
        self.pct = pct
        self.burdenPct = burdenPct
        self.baseCents = baseCents
    }

    static let none = CommissionTerms(pct: 0, burdenPct: 0)
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
    /// Commission on the base, `round(Base × C ÷ 100)`, and its employer payroll tax, `round(Base × C × B ÷ 10000)`,
    /// each rounded once from cents (DECISIONS 92). 0 without a salesperson.
    var commission: Int
    var commissionTax: Int
    /// `Base − Cost − Commission − CommissionTax` by integer subtraction, so the header reconciles (DECISIONS 3, 92).
    var profitAfterCommission: Int
    /// `ProfitAfter ÷ Base × 100`, unrounded; 0 when the base is 0.
    var marginAfterCommissionPct: Decimal

    /// Without commission terms the profit after commission is the profit, and its margin the margin, so a breakdown
    /// written out by hand (the pinned fixtures) equals the one the Pricer computes with `.none`.
    init(labor: Int, equipment: Int, materials: Int, consumables: Int, subcontractors: Int, overhead: Int,
         cost: Int, price: Int, profit: Int, marginPct: Decimal, commission: Int = 0, commissionTax: Int = 0,
         profitAfterCommission: Int? = nil, marginAfterCommissionPct: Decimal? = nil) {
        self.labor = labor
        self.equipment = equipment
        self.materials = materials
        self.consumables = consumables
        self.subcontractors = subcontractors
        self.overhead = overhead
        self.cost = cost
        self.price = price
        self.profit = profit
        self.marginPct = marginPct
        self.commission = commission
        self.commissionTax = commissionTax
        self.profitAfterCommission = profitAfterCommission ?? profit
        self.marginAfterCommissionPct = marginAfterCommissionPct ?? marginPct
    }

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
                                cost: 0, price: 0, profit: 0, marginPct: 0, commission: 0, commissionTax: 0,
                                profitAfterCommission: 0, marginAfterCommissionPct: 0)
}

/// BRIEF §1:
///
///     Hourly = Σ Labor(on) + Σ Equipment(on) + Σ Overhead(on) ÷ billableHours
///     Cost   = Hourly × Hours + Σ Materials(on × qty) + Σ Consumables(on × qty)
///     Price  = max( MinimumJob , Cost × (1 + Markup) × Multiplier )
///     Profit = Price − Cost ;  Margin = Profit ÷ Price
///
/// With commission (DECISIONS 92): Base = the terms' base ?? Price; Commission = round(Base × C ÷ 100);
/// CommissionTax = round(Base × C × B ÷ 10000); ProfitAfter = Base − Cost − Commission − CommissionTax.
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

    /// - Parameters:
    ///   - rule: markup, or target margin with the sales allowance and its payroll tax (DECISIONS 70, 92)
    ///   - commission: the commission this project pays; `.none` leaves every commission figure 0 and the
    ///     profit after commission equal to the profit
    static func price(
        lines: [PriceLine], hours: Decimal, multiplier: Int, rule: PriceRule, commission: CommissionTerms = .none,
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
        case .targetMargin(let pct, let allowance, let burden):
            let margin = min(nonNegative(pct), PriceRule.maximumMarginPct)
            let a = PriceRule.percent(allowance)
            if a == 0 {
                // DECISIONS 70, unchanged: every price pinned before the allowance existed is reproduced bit for bit.
                marked = Money.cents(Decimal(cost) * 100 * Decimal(multiplier) / (100 - margin))
            } else {
                // DECISIONS 92: one division over the combined share, rounded once.
                let share = PriceRule.share(margin: margin, allowance: a, burden: PriceRule.percent(burden))
                marked = Money.cents(Decimal(cost) * 10000 * Decimal(multiplier) / (10000 - share))
            }
        }
        let price = max(minimumJobCents, marked)
        let profit = Money.cents(Decimal(price) - Decimal(cost))
        let marginPct: Decimal = price > 0 ? Decimal(profit) / Decimal(price) * 100 : 0

        // Commission after the floor and the multiplier, on the base (DECISIONS 92). Each figure rounded once from cents.
        let c = PriceRule.percent(commission.pct)
        let b = PriceRule.percent(commission.burdenPct)
        let base = max(commission.baseCents ?? price, 0)
        let paid = c > 0 ? Money.cents(Decimal(base) * c / 100) : 0
        let tax = c > 0 && b > 0 ? Money.cents(Decimal(base) * c * b / 10000) : 0
        let profitAfter = Money.cents(Decimal(base) - Decimal(cost) - Decimal(paid) - Decimal(tax))
        let marginAfter: Decimal = base > 0 ? Decimal(profitAfter) / Decimal(base) * 100 : 0

        return Breakdown(labor: labor, equipment: equipment, materials: materials,
                         consumables: consumables, subcontractors: subcontractors, overhead: overhead,
                         cost: cost, price: price, profit: profit, marginPct: marginPct,
                         commission: paid, commissionTax: tax, profitAfterCommission: profitAfter,
                         marginAfterCommissionPct: marginAfter)
    }

    private static func nonNegative(_ x: Decimal) -> Decimal {
        x.isFinite && x > 0 ? x : 0
    }
}
