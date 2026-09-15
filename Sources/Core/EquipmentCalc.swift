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

/// The five exact components, in dollars, for display in the sheet. The stored rate is the
/// exact sum rounded once (DECISIONS 7).
struct EquipmentRate: Equatable, Sendable {
    var depreciation: Decimal
    var costOfMoney: Decimal
    var insurance: Decimal
    var fuelOil: Decimal
    var repairs: Decimal

    var total: Decimal { depreciation + costOfMoney + insurance + fuelOil + repairs }
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

        // Depreciation = (Price − Salvage) ÷ LifeHours
        let depreciation = (c - s) / lifeHours

        // N = LifeHours ÷ AnnualHours ; AVF = ((N−1)(1 + Salvage/Price) + 2) ÷ 2N ; AVF = 1 if N ≤ 1
        let n = lifeHours / annualHours
        let avf: Decimal = n <= 1 ? 1 : ((n - 1) * (1 + s / c) + 2) / (2 * n)

        // CostOfMoney = Price × AVF × Rate ÷ AnnualHours
        let costOfMoneyPerHour = c * avf * costOfMoney / annualHours

        // Insurance = Annual$ ÷ AnnualHours
        let insurance = i / annualHours

        // Fuel + oil = as entered
        let fuelOil = Money.decimal(cents: fuelOilPerHour)

        // Repairs = Price × RepairFactor ÷ LifeHours
        let repairs = c * repairFactor / lifeHours

        return EquipmentRate(depreciation: depreciation, costOfMoney: costOfMoneyPerHour,
                             insurance: insurance, fuelOil: fuelOil, repairs: repairs)
    }

    /// $/hr in cents: the exact sum of the five components, rounded once.
    static func rateCents(
        price: Int, salvage: Int, lifeHours: Decimal, annualHours: Decimal,
        fuelOilPerHour: Int, repairFactor: Decimal, insurancePerYear: Int, costOfMoney: Decimal
    ) throws -> Int {
        try rate(price: price, salvage: salvage, lifeHours: lifeHours, annualHours: annualHours,
                 fuelOilPerHour: fuelOilPerHour, repairFactor: repairFactor,
                 insurancePerYear: insurancePerYear, costOfMoney: costOfMoney).rateCents
    }
}
