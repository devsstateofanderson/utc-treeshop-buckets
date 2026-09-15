import Foundation

enum EquipmentCalcError: Error, Equatable {
    case nonPositivePrice
    case negativeSalvage
    case salvageNotBelowPrice
    case nonPositiveLifeHours
    case nonPositiveAnnualHours
    case negativeFuelOil
    case negativeRepairFactor
    case negativeInsurance
    case negativeCostOfMoney
}

/// The 7 inputs the Equipment "Calculate…" sheet saves into `BucketItem.calcInputs`,
/// plus the cost-of-money percent that was in Settings when the rate was saved (DECISIONS 13, 36).
struct EquipmentCalcInputs: Codable, Equatable, Sendable {
    var priceCents: Int
    var salvageCents: Int
    var lifeHours: Decimal
    var annualHours: Decimal
    var fuelOilPerHourCents: Int
    var repairFactor: Decimal
    var insurancePerYearCents: Int
    var costOfMoneyPct: Decimal     // whole percent, e.g. 7
}

/// The five components, in dollars, for display in the sheet, plus the exact total the stored rate
/// comes from. Each figure is produced by ONE Decimal division so that a value which is exactly a
/// half cent is computed exactly and then rounds half away from zero (DECISIONS 7): `Decimal`
/// division truncates at 38 digits, so summing separately divided components would put an exact
/// tie one unit below the boundary.
struct EquipmentRate: Equatable, Sendable {
    var depreciation: Decimal
    var costOfMoney: Decimal
    var insurance: Decimal
    var fuelOil: Decimal
    var repairs: Decimal
    /// The five components over their common denominator 2·life·annual, one division.
    var total: Decimal

    var rateCents: Int { Money.cents(total * 100) }
}

/// BRIEF §2.2 — the USACE EP 1110-1-8 core reduced to 7 inputs + cost of money.
enum EquipmentCalc {
    /// All money inputs are cents; `repairFactor` and `costOfMoney` are fractions (0.80, 0.07).
    static func rate(
        price: Int, salvage: Int, lifeHours: Decimal, annualHours: Decimal,
        fuelOilPerHour: Int, repairFactor: Decimal, insurancePerYear: Int, costOfMoney: Decimal
    ) throws -> EquipmentRate {
        guard price > 0 else { throw EquipmentCalcError.nonPositivePrice }
        guard salvage >= 0 else { throw EquipmentCalcError.negativeSalvage }
        guard salvage < price else { throw EquipmentCalcError.salvageNotBelowPrice }
        guard lifeHours > 0 else { throw EquipmentCalcError.nonPositiveLifeHours }
        guard annualHours > 0 else { throw EquipmentCalcError.nonPositiveAnnualHours }
        guard fuelOilPerHour >= 0 else { throw EquipmentCalcError.negativeFuelOil }
        guard repairFactor >= 0 else { throw EquipmentCalcError.negativeRepairFactor }
        guard insurancePerYear >= 0 else { throw EquipmentCalcError.negativeInsurance }
        guard costOfMoney >= 0 else { throw EquipmentCalcError.negativeCostOfMoney }

        let c = Money.decimal(cents: price)
        let s = Money.decimal(cents: salvage)
        let i = Money.decimal(cents: insurancePerYear)
        let f = Money.decimal(cents: fuelOilPerHour)
        let l = lifeHours
        let a = annualHours

        // BRIEF §2.2:
        //   Depreciation = (Price − Salvage) ÷ LifeHours
        //   CostOfMoney  = Price × AVF × Rate ÷ AnnualHours
        //                  N = LifeHours ÷ AnnualHours
        //                  AVF = ((N−1)(1 + Salvage/Price) + 2) ÷ 2N ;  AVF = 1 if N ≤ 1
        //   Insurance    = Annual$ ÷ AnnualHours
        //   Fuel+oil     = as entered
        //   Repairs      = Price × RepairFactor ÷ LifeHours
        //
        // Price × AVF × Rate ÷ AnnualHours expands to K × Rate ÷ (2·L·A) with
        //   K = (L − A)(Price + Salvage) + 2·A·Price   when N > 1  (i.e. L > A)
        //   K = 2·L·Price                              when N ≤ 1  (AVF = 1)
        // so every component shares the denominator 2·L·A and the total needs one division.
        let k: Decimal = l <= a ? 2 * l * c : (l - a) * (c + s) + 2 * a * c
        let denominator = 2 * l * a
        let numerator = 2 * a * (c - s) + k * costOfMoney + 2 * l * i + denominator * f + 2 * a * c * repairFactor

        return EquipmentRate(depreciation: (c - s) / l,
                             costOfMoney: k * costOfMoney / denominator,
                             insurance: i / a,
                             fuelOil: f,
                             repairs: c * repairFactor / l,
                             total: numerator / denominator)
    }

    /// $/hr in cents: the exact total, rounded once.
    static func rateCents(
        price: Int, salvage: Int, lifeHours: Decimal, annualHours: Decimal,
        fuelOilPerHour: Int, repairFactor: Decimal, insurancePerYear: Int, costOfMoney: Decimal
    ) throws -> Int {
        try rate(price: price, salvage: salvage, lifeHours: lifeHours, annualHours: annualHours,
                 fuelOilPerHour: fuelOilPerHour, repairFactor: repairFactor,
                 insurancePerYear: insurancePerYear, costOfMoney: costOfMoney).rateCents
    }
}
