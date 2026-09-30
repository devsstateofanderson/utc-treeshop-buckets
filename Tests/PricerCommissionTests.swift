import XCTest
@testable import Buckets

/// DECISIONS 92: the sales allowance and its payroll tax in the one price division, and the commission on the base.
/// Every figure below was recomputed by hand with exact rational arithmetic, half away from zero once per figure.
/// The fixture is synthetic: a job shaped like a medium removal (a three-person crew at 10,503¢/h, equipment at
/// 4,113¢/h, $155,864.30 of overhead a year, two disposal loads) that costs exactly 222,056¢ at 8 hours.
final class PricerCommissionTests: XCTestCase {
    private static let burden = Decimal(string: "7.65")!

    private static let removal: [PriceLine] = [
        PriceLine(bucket: .labor, rateCents: 10_503),
        PriceLine(bucket: .equipment, rateCents: 4113),
        PriceLine(bucket: .overhead, rateCents: 15_586_430),
        PriceLine(bucket: .consumables, rateCents: 11_000, isOn: true, qty: 2),
    ]

    private func removal(_ rule: PriceRule, multiplier: Int = 1, commission: CommissionTerms = .none) -> Breakdown {
        Pricer.price(lines: Self.removal, hours: 8, multiplier: multiplier, rule: rule, commission: commission,
                     minimumJobCents: 75_000, billableHours: 1500)
    }

    private static let withAllowance = PriceRule.targetMargin(50, allowance: 7, burden: burden)
    private static let sevenPercent = CommissionTerms(pct: 7, burdenPct: burden)

    // MARK: A = 0 changes nothing

    /// Every pinned figure of `PricerSpecFiguresTests` and `MarginPricingTests`, priced through the old signatures and
    /// through the new one with no allowance (any payroll tax) and no commission: bit for bit the same.
    func testZeroAllowanceReproducesEveryPinnedPrice() {
        struct Case { var lines: [PriceLine]; var hours: Decimal; var multiplier: Int; var rule: PriceRule; var minimum: Int; var price: Int }
        let markup = PriceRule.markup(Decimal(string: "0.35")!)
        let tie = [PriceLine(bucket: .materials, rateCents: 2, isOn: true, qty: 1)]
        let cases: [Case] = [
            Case(lines: Fixture.lines(), hours: 8, multiplier: 1, rule: markup, minimum: 75_000, price: 250_150),
            Case(lines: Fixture.lines(miguelOn: false), hours: 8, multiplier: 1, rule: markup, minimum: 75_000, price: 217_048),
            Case(lines: Fixture.lines(skidSteerOn: true), hours: 8, multiplier: 1, rule: markup, minimum: 75_000, price: 267_462),
            Case(lines: Fixture.lines(skidSteerOn: true, stumps: 3), hours: 8, multiplier: 1, rule: markup, minimum: 75_000, price: 303_912),
            Case(lines: Fixture.lines(stumps: 3), hours: 8, multiplier: 1, rule: markup, minimum: 75_000, price: 286_600),
            Case(lines: Fixture.lines(), hours: 8, multiplier: 2, rule: markup, minimum: 75_000, price: 500_299),
            Case(lines: Fixture.lines(), hours: 8, multiplier: 3, rule: markup, minimum: 75_000, price: 750_449),
            Case(lines: Fixture.lines(), hours: 0, multiplier: 1, rule: markup, minimum: 75_000, price: 75_000),
            Case(lines: Fixture.lines(), hours: 8, multiplier: 1, rule: .targetMargin(50), minimum: 75_000, price: 370_592),
            Case(lines: Fixture.lines(miguelOn: false), hours: 8, multiplier: 1, rule: .targetMargin(50), minimum: 75_000, price: 321_552),
            Case(lines: Fixture.lines(skidSteerOn: true), hours: 8, multiplier: 1, rule: .targetMargin(50), minimum: 75_000, price: 396_240),
            Case(lines: Fixture.lines(skidSteerOn: true, stumps: 3), hours: 8, multiplier: 1, rule: .targetMargin(50), minimum: 75_000, price: 450_240),
            Case(lines: Fixture.lines(), hours: 8, multiplier: 3, rule: .targetMargin(50), minimum: 75_000, price: 185_296 * 6),
            Case(lines: Fixture.lines(), hours: 8, multiplier: 1, rule: .targetMargin(40), minimum: 75_000, price: 308_827),
            Case(lines: Fixture.lines(), hours: 8, multiplier: 1, rule: .targetMargin(Decimal(string: "33.5")!), minimum: 75_000,
                 price: Money.cents(Decimal(185_296) * 100 / Decimal(string: "66.5")!)),
            Case(lines: Fixture.lines(), hours: 8, multiplier: 1, rule: .targetMargin(95), minimum: 75_000, price: 185_296 * 20),
            Case(lines: tie, hours: 0, multiplier: 1, rule: .targetMargin(20), minimum: 0, price: 3),
        ]
        for (n, c) in cases.enumerated() {
            let old = Pricer.price(lines: c.lines, hours: c.hours, multiplier: c.multiplier, rule: c.rule,
                                   minimumJobCents: c.minimum, billableHours: 1500)
            XCTAssertEqual(old.price, c.price, "case \(n)")
            XCTAssertEqual(old.commission, 0, "case \(n)")
            XCTAssertEqual(old.commissionTax, 0, "case \(n)")
            XCTAssertEqual(old.profitAfterCommission, old.profit, "case \(n)")
            XCTAssertEqual(old.marginAfterCommissionPct, old.marginPct, "case \(n)")
            guard case .targetMargin(let m, _, _) = c.rule else { continue }
            for burden in [Decimal(0), Self.burden, 30, 100, -5] {
                let rule = PriceRule.targetMargin(m, allowance: 0, burden: burden)
                XCTAssertEqual(rule, c.rule, "case \(n): with no allowance the payroll tax prices nothing")
                XCTAssertEqual(rule.markupPercent, c.rule.markupPercent, "case \(n)")
                let new = Pricer.price(lines: c.lines, hours: c.hours, multiplier: c.multiplier, rule: rule, commission: .none,
                                       minimumJobCents: c.minimum, billableHours: 1500)
                XCTAssertEqual(new, old, "case \(n), burden \(burden)")
            }
        }
        XCTAssertEqual(PriceRule.targetMargin(50).markupPercent, 100)
        XCTAssertEqual(Project.rounded2(PriceRule.targetMargin(40, allowance: 0, burden: Self.burden).markupPercent), Decimal(string: "66.67")!)
    }

    // MARK: The allowance

    func testMediumRemovalPricesUnderEachRule() {
        XCTAssertEqual(removal(.targetMargin(50)).cost, 222_056)
        XCTAssertEqual(removal(.targetMargin(50)).price, 444_112, "A 0: today's price")
        XCTAssertEqual(removal(Self.withAllowance).price, 522_921, "50/7/7.65: 222,056 × 10,000 ÷ 4,246.45 = 522,921.499… (a near tie, rounded down)")
        XCTAssertEqual(removal(.targetMargin(50, allowance: 7, burden: 0)).price, 516_409, "the owner's plain formula, B = 0")
        XCTAssertEqual(removal(Self.withAllowance, multiplier: 2).price, 1_045_843, "rounded once, not 2 × 522,921")
        XCTAssertEqual(removal(Self.withAllowance, multiplier: 3).price, 1_568_764)
        XCTAssertEqual(removal(.targetMargin(Decimal(string: "42.5")!, allowance: 7, burden: Self.burden)).price, 444_428,
                       "keep today's price: margin 42.5 with the allowance")
        XCTAssertEqual(removal(.targetMargin(50, allowance: 7, burden: 30)).price, 542_924, "the crew's 30% burden would add $200")
        XCTAssertEqual(Project.rounded2(Self.withAllowance.markupPercent), Decimal(string: "135.49")!, "display markup equivalent")
    }

    func testCommissionTaxAndProfitAfterCommission() {
        let b = removal(Self.withAllowance, commission: Self.sevenPercent)
        XCTAssertEqual(b.price, 522_921)
        XCTAssertEqual(b.commission, 36_604, "522,921 × 7 ÷ 100 = 36,604.47")
        XCTAssertEqual(b.commissionTax, 2800, "522,921 × 53.55 ÷ 10,000 = 2,800.24")
        XCTAssertEqual(b.profitAfterCommission, 261_461)
        XCTAssertEqual(b.profitAfterCommission, b.price - b.cost - b.commission - b.commissionTax, "the header reconciles")
        XCTAssertEqual(b.profit, 300_865, "gross profit is unchanged in meaning")
        XCTAssertEqual(Project.rounded1(b.marginAfterCommissionPct), 50)
        XCTAssertGreaterThan(b.marginAfterCommissionPct, 50, "50.0001%: rounding once can land a hair over the target")

        // The owner sells it (C = 0) and keeps the allowance: Commission + CommTax at C = A, each rounded on its own.
        let owner = removal(Self.withAllowance)
        XCTAssertEqual(owner.profitAfterCommission, 300_865)
        XCTAssertEqual(owner.profitAfterCommission - b.profitAfterCommission, 39_404)
        XCTAssertEqual(Project.rounded1(owner.marginAfterCommissionPct), Decimal(string: "57.5")!)

        // The live defect: no allowance, 7% paid out of today's price → 42.5% after commission.
        let today = removal(.targetMargin(50), commission: Self.sevenPercent)
        XCTAssertEqual(today.commission, 31_088)
        XCTAssertEqual(today.commissionTax, 2378)
        XCTAssertEqual(today.profitAfterCommission, 188_590)
        XCTAssertEqual(Project.rounded1(today.marginAfterCommissionPct), Decimal(string: "42.5")!)
    }

    func testOverrideAndMinimumAndLoss() {
        let ten = removal(Self.withAllowance, commission: CommissionTerms(pct: 10, burdenPct: Self.burden))
        XCTAssertEqual([ten.commission, ten.commissionTax, ten.profitAfterCommission], [52_292, 4000, 244_573])

        // The floor: a customer price, never grossed up; commission is paid on the $750.
        let stump = Pricer.price(lines: [PriceLine(bucket: .subcontractors, rateCents: 29_992, isOn: true, qty: 1)], hours: 1,
                                 multiplier: 1, rule: Self.withAllowance, commission: Self.sevenPercent,
                                 minimumJobCents: 75_000, billableHours: 1500)
        XCTAssertEqual(stump.cost, 29_992)
        XCTAssertEqual(stump.price, 75_000, "29,992 × 10,000 ÷ 4,246.45 = 70,628 → the floor")
        XCTAssertEqual([stump.commission, stump.commissionTax, stump.profitAfterCommission], [5250, 402, 39_356])

        // Paying more than the headroom loses money: A 0, M 5, C 7.
        let loss = removal(.targetMargin(5, allowance: 0, burden: Self.burden), commission: Self.sevenPercent)
        XCTAssertEqual(loss.price, 233_743)
        XCTAssertEqual([loss.commission, loss.commissionTax], [16_362, 1252])
        XCTAssertEqual(loss.profitAfterCommission, -5927)
        XCTAssertLessThan(loss.marginAfterCommissionPct, 0)
    }

    func testCommissionRoundsOnceHalfAwayFromZero() {
        // 12,350¢ at 7% = 864.5 exactly → 865.
        let b = Pricer.price(lines: [PriceLine(bucket: .materials, rateCents: 12_350, isOn: true, qty: 1)], hours: 0,
                             multiplier: 1, rule: .markup(0), commission: CommissionTerms(pct: 7, burdenPct: 0),
                             minimumJobCents: 0, billableHours: 1500)
        XCTAssertEqual(b.price, 12_350)
        XCTAssertEqual(b.commission, 865)
        XCTAssertEqual(b.commissionTax, 0)
        XCTAssertEqual(b.profitAfterCommission, -865)
    }

    func testABasePassedInReplacesThePriceForCommissionOnly() {
        let sold = removal(Self.withAllowance, commission: CommissionTerms(pct: 7, burdenPct: Self.burden, baseCents: 500_000))
        XCTAssertEqual(sold.price, 522_921, "the price is still the rule's")
        XCTAssertEqual(sold.profit, 300_865)
        XCTAssertEqual(sold.commission, 35_000)
        XCTAssertEqual(sold.commissionTax, 2678, "500,000 × 53.55 ÷ 10,000 = 2,677.5 → 2,678")
        XCTAssertEqual(sold.profitAfterCommission, 500_000 - 222_056 - 35_000 - 2678)
    }

    func testShareAndPercentsAreClamped() {
        // 100·90 + 10·(100 + 0) = 10,000 → held at 9,500: ×20, as a 95% margin.
        XCTAssertEqual(removal(.targetMargin(90, allowance: 10, burden: 0)).price, 222_056 * 20)
        XCTAssertEqual(removal(.targetMargin(50, allowance: 150, burden: 0)).price, 222_056 * 20, "A over 100 → 100, share held")
        XCTAssertEqual(removal(.targetMargin(50, allowance: 7, burden: 250)).price,
                       removal(.targetMargin(50, allowance: 7, burden: 100)).price, "B over 100 → 100")
        XCTAssertEqual(removal(.targetMargin(50, allowance: -7, burden: Self.burden)).price, 444_112, "negative A → 0")
        XCTAssertEqual(removal(.targetMargin(50, allowance: .nan, burden: Self.burden)).price, 444_112, "NaN A → 0")
        XCTAssertEqual(removal(.targetMargin(50, allowance: 7, burden: .nan)).price, 516_409, "NaN B → 0")
        XCTAssertEqual(removal(.targetMargin(50, allowance: 7, burden: -3)).price, 516_409, "negative B → 0")

        let over = removal(.targetMargin(50), commission: CommissionTerms(pct: 250, burdenPct: 0))
        XCTAssertEqual(over.commission, 444_112, "C over 100 → 100")
        XCTAssertEqual(removal(.targetMargin(50), commission: CommissionTerms(pct: -7, burdenPct: 10)).commission, 0)
        XCTAssertEqual(removal(.targetMargin(50), commission: CommissionTerms(pct: .nan, burdenPct: 10)).commission, 0)
        let noTax = removal(.targetMargin(50), commission: CommissionTerms(pct: 7, burdenPct: .nan))
        XCTAssertEqual([noTax.commission, noTax.commissionTax], [31_088, 0])
        XCTAssertEqual(PriceRule.percent(-1), 0)
        XCTAssertEqual(PriceRule.percent(101), 100)
        XCTAssertEqual(PriceRule.percent(Decimal(string: "7.65")!), Decimal(string: "7.65")!)
    }

    func testLegacyMarkupIgnoresTheAllowanceButPaysCommission() {
        let b = Fixture.price(Fixture.lines())
        let paid = Pricer.price(lines: Fixture.lines(), hours: 8, multiplier: 1, rule: .markup(Decimal(string: "0.35")!),
                                commission: Self.sevenPercent, minimumJobCents: 75_000, billableHours: 1500)
        XCTAssertEqual(paid.price, 250_150)
        XCTAssertEqual(paid.price, b.price)
        XCTAssertEqual(paid.commission, 17_511, "250,150 × 7 ÷ 100 = 17,510.5 → 17,511")
        XCTAssertEqual(paid.profitAfterCommission, 250_150 - 185_296 - paid.commission - paid.commissionTax)
        XCTAssertEqual(Breakdown.zero.profitAfterCommission, 0)
    }
}
