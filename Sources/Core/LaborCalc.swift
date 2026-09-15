import Foundation

enum LaborCalcError: Error, Equatable {
    case negativeWage, negativePaidHours, negativeBurden, nonPositiveBillableHours
}

/// Inputs the Labor "Calculate…" sheet saves into `BucketItem.calcInputs` (DECISIONS 35).
struct LaborCalcInputs: Codable, Equatable, Sendable {
    var wageCents: Int
    var paidHours: Decimal
    var burdenPct: Decimal      // whole percent, e.g. 30
}

/// BRIEF §2.1: `Rate/project-hr = Wage × (1 + Burden%) × PaidHours/yr ÷ BillableHours/yr`.
enum LaborCalc {
    /// - Parameters:
    ///   - wage: $/hr in cents (Marcus: 3000)
    ///   - paidHours: hours paid per year (2080)
    ///   - burden: fraction (0.30), not a percent
    ///   - billable: billable hours per year (1500)
    /// - Returns: $/project-hour in cents, rounded once half-away-from-zero.
    static func rateCents(wage: Int, paidHours: Decimal, burden: Decimal, billable: Decimal) throws -> Int {
        guard wage >= 0 else { throw LaborCalcError.negativeWage }
        guard paidHours >= 0 else { throw LaborCalcError.negativePaidHours }
        guard burden >= 0 else { throw LaborCalcError.negativeBurden }
        guard billable > 0 else { throw LaborCalcError.nonPositiveBillableHours }
        let exact = Decimal(wage) * (1 + burden) * paidHours / billable
        return Money.cents(exact)
    }
}
