import Foundation

enum SalaryCalcError: Error, Equatable {
    case negativeAmount, negativeDaysPerWeek, negativeWeeksPerYear, negativeBurden, aboveMaximum
}

/// How often a salary amount is paid (DECISIONS 93). The raw value is what `calcInputs` stores.
enum SalaryPeriod: String, Codable, CaseIterable, Sendable {
    case day, week, biweekly, semimonthly, month, year

    /// "per day", "every two weeks"…, as the sheet's picker reads.
    var title: String {
        switch self {
        case .day: "per day"
        case .week: "per week"
        case .biweekly: "every two weeks"
        case .semimonthly: "twice a month"
        case .month: "per month"
        case .year: "per year"
        }
    }

    /// Whether the period count depends on days per week (a day rate only).
    var usesDaysPerWeek: Bool { self == .day }

    /// Whether the period count depends on weeks per year (a day or a week rate).
    var usesWeeksPerYear: Bool { self == .day || self == .week }

    /// Periods paid in a year: day = days per week × weeks per year; week = weeks per year; biweekly 26;
    /// semimonthly 24; month 12; year 1. Exact (a product of the inputs, never a division).
    func periodsPerYear(daysPerWeek: Decimal, weeksPerYear: Decimal) -> Decimal {
        switch self {
        case .day: daysPerWeek * weeksPerYear
        case .week: weeksPerYear
        case .biweekly: 26
        case .semimonthly: 24
        case .month: 12
        case .year: 1
        }
    }
}

/// Inputs the Overhead "Calculate…" sheet saves into `BucketItem.calcInputs` (DECISIONS 93), read back as
/// `BucketItem.salaryInputs`. The two counts are kept whatever the period, so switching the period back restores them.
struct SalaryCalcInputs: Codable, Equatable, Sendable {
    var amountCents: Int
    var period: SalaryPeriod
    var daysPerWeek: Decimal
    var weeksPerYear: Decimal
    var burdenPct: Decimal      // whole percent, e.g. 30
}

/// A salaried position as one Overhead line (DECISIONS 93, amending 34 for this case):
///
///     $/yr = round( amount × periods a year × (100 + burden) ÷ 100 )
///
/// One division, rounded once half away from zero (DECISIONS 7, 11); the $/hr a project sees is $/yr ÷ billable hours,
/// display only (DECISIONS 4).
enum SalaryCalc {
    /// The largest $/yr a row can store: $9,999,999.99 (DECISIONS 30).
    static let maximumCents = 999_999_999

    /// - Returns: $/yr in cents.
    /// - Throws: `SalaryCalcError` for a negative amount or burden, a negative count the period uses (DECISIONS 9), or a
    ///   result above `maximumCents`.
    static func annualCents(_ inputs: SalaryCalcInputs) throws -> Int {
        guard inputs.amountCents >= 0 else { throw SalaryCalcError.negativeAmount }
        guard inputs.burdenPct >= 0 else { throw SalaryCalcError.negativeBurden }
        if inputs.period.usesDaysPerWeek, inputs.daysPerWeek < 0 { throw SalaryCalcError.negativeDaysPerWeek }
        if inputs.period.usesWeeksPerYear, inputs.weeksPerYear < 0 { throw SalaryCalcError.negativeWeeksPerYear }
        let periods = inputs.period.periodsPerYear(daysPerWeek: inputs.daysPerWeek, weeksPerYear: inputs.weeksPerYear)
        let cents = Money.cents(Decimal(inputs.amountCents) * periods * (100 + inputs.burdenPct) / 100)
        guard cents <= maximumCents else { throw SalaryCalcError.aboveMaximum }
        return cents
    }
}
