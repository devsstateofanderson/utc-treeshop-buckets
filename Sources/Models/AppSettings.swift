import Foundation

/// The five settings (BRIEF §1). Stored in UserDefaults via `@AppStorage` in the Settings screen;
/// this struct is the same values as plain data for the Models layer (DECISIONS 12).
struct AppSettings: Equatable, Sendable {
    /// Crew project-hours per year; divides labor and overhead.
    var billableHoursPerYear: Int = 1500
    /// Payroll tax + workers comp + benefits, as a whole percent of wage.
    var laborBurdenPct: Double = 30
    /// The company's target profit margin (Profit ÷ Price), whole percent (DECISIONS 70). Markup is derived from it.
    var targetMarginPct: Double = 50
    /// Hard floor, cents.
    var minimumJobCents: Int = 75000
    /// Loan rate for financed equipment, whole percent; 0 if cash.
    var costOfMoneyPct: Double = 0

    enum Key {
        static let billableHoursPerYear = "billableHoursPerYear"
        static let laborBurdenPct = "laborBurdenPct"
        static let targetMarginPct = "targetMarginPct"
        static let minimumJobCents = "minimumJobCents"
        static let costOfMoneyPct = "costOfMoneyPct"
    }

    static let defaults = AppSettings()

    /// Registers the defaults so `@AppStorage` and `current` agree before anything is saved.
    static func register(in defaults: UserDefaults = .standard) {
        defaults.register(defaults: [
            Key.billableHoursPerYear: AppSettings.defaults.billableHoursPerYear,
            Key.laborBurdenPct: AppSettings.defaults.laborBurdenPct,
            Key.targetMarginPct: AppSettings.defaults.targetMarginPct,
            Key.minimumJobCents: AppSettings.defaults.minimumJobCents,
            Key.costOfMoneyPct: AppSettings.defaults.costOfMoneyPct,
        ])
    }

    static func current(from defaults: UserDefaults = .standard) -> AppSettings {
        var s = AppSettings.defaults
        if defaults.object(forKey: Key.billableHoursPerYear) != nil { s.billableHoursPerYear = defaults.integer(forKey: Key.billableHoursPerYear) }
        if defaults.object(forKey: Key.laborBurdenPct) != nil { s.laborBurdenPct = defaults.double(forKey: Key.laborBurdenPct) }
        if defaults.object(forKey: Key.targetMarginPct) != nil { s.targetMarginPct = defaults.double(forKey: Key.targetMarginPct) }
        if defaults.object(forKey: Key.minimumJobCents) != nil { s.minimumJobCents = defaults.integer(forKey: Key.minimumJobCents) }
        if defaults.object(forKey: Key.costOfMoneyPct) != nil { s.costOfMoneyPct = defaults.double(forKey: Key.costOfMoneyPct) }
        return s
    }

    func save(to defaults: UserDefaults = .standard) {
        defaults.set(billableHoursPerYear, forKey: Key.billableHoursPerYear)
        defaults.set(laborBurdenPct, forKey: Key.laborBurdenPct)
        defaults.set(targetMarginPct, forKey: Key.targetMarginPct)
        defaults.set(minimumJobCents, forKey: Key.minimumJobCents)
        defaults.set(costOfMoneyPct, forKey: Key.costOfMoneyPct)
    }

    // Exact Decimal views (DECISIONS 11, 12). `Double.description` is the shortest round-trip text,
    // so 32.5 becomes exactly 32.5, never 32.49999….
    var billableHours: Decimal { Decimal(billableHoursPerYear) }
    var laborBurdenPctDecimal: Decimal { Money.decimal(from: laborBurdenPct) }
    var targetMarginPctDecimal: Decimal { Money.decimal(from: targetMarginPct) }
    var costOfMoneyPctDecimal: Decimal { Money.decimal(from: costOfMoneyPct) }
    var laborBurden: Decimal { laborBurdenPctDecimal / 100 }
    var pricingRule: PriceRule { .targetMargin(targetMarginPctDecimal) }
    var costOfMoney: Decimal { costOfMoneyPctDecimal / 100 }
}
