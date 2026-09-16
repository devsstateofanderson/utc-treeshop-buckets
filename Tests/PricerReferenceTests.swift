import XCTest
@testable import Buckets

/// 200 deterministic cases (LCG seed 20260914) checked against an independent pure-Int reference:
/// hours and qty as integer hundredths, every subtotal rounded once half-away-from-zero with integer division,
/// Cost = Σ subtotals, Price = max(min, round(cost × (100+markupPct) × mult / 100)), Profit = Price − Cost.
/// The same generator in python3 (fractions) produced checksum 360650820, printed here for cross-checking.
final class Probe_pricer_reference200: XCTestCase {
    private struct LCG {
        var x: UInt64
        mutating func next() -> Int {
            x = x &* 6364136223846793005 &+ 1442695040888963407
            return Int(x >> 33)
        }
    }

    /// Half away from zero for integer num / den, den > 0.
    private func rhaz(_ num: Int, _ den: Int) -> Int {
        let a = abs(num)
        var q = a / den
        if 2 * (a % den) >= den { q += 1 }
        return num >= 0 ? q : -q
    }

    func test200CasesAgainstIntegerReference() {
        var g = LCG(x: 20260914)
        var checksum = 0
        for i in 0..<200 {
            let hoursH = g.next() % 20001
            var rows: [(Bucket, Int, Bool, Int)] = []
            for _ in 0..<3 { let r = g.next() % 20001; let on = g.next() % 4 != 0; rows.append((.labor, r, on, 100)) }
            for _ in 0..<4 { let r = g.next() % 5001; let on = g.next() % 4 != 0; rows.append((.equipment, r, on, 100)) }
            for _ in 0..<5 { let r = g.next() % 2_000_001; let on = g.next() % 4 != 0; rows.append((.overhead, r, on, 100)) }
            for _ in 0..<3 { let r = g.next() % 20001; let q = g.next() % 1001; let on = g.next() % 2 == 0; rows.append((.materials, r, on, q)) }
            for _ in 0..<4 { let r = g.next() % 200_001; let q = g.next() % 2001; let on = g.next() % 2 == 0; rows.append((.consumables, r, on, q)) }
            let mult = 1 + g.next() % 3
            let markupPct = [0, 10, 35, 50, 100][g.next() % 5]
            let minimum = [0, 75_000][g.next() % 2]
            let billable = [1000, 1499, 1500, 2080][g.next() % 4]

            func hourly(_ b: Bucket) -> Int { rhaz(rows.filter { $0.0 == b && $0.2 }.map { $0.1 }.reduce(0, +) * hoursH, 100) }
            func qtyb(_ b: Bucket) -> Int { rhaz(rows.filter { $0.0 == b && $0.2 }.map { $0.1 * $0.3 }.reduce(0, +), 100) }
            let labor = hourly(.labor), equipment = hourly(.equipment)
            let overhead = rhaz(rows.filter { $0.0 == .overhead && $0.2 }.map { $0.1 }.reduce(0, +) * hoursH, 100 * billable)
            let materials = qtyb(.materials), consumables = qtyb(.consumables)
            let cost = labor + equipment + overhead + materials + consumables
            let price = max(minimum, rhaz(cost * (100 + markupPct) * mult, 100))
            let profit = price - cost
            let margin1 = price > 0 ? rhaz(profit * 1000, price) : 0

            let lines = rows.map { PriceLine(bucket: $0.0, rateCents: $0.1, isOn: $0.2, qty: Decimal($0.3) / 100) }
            let b = Pricer.price(lines: lines, hours: Decimal(hoursH) / 100, multiplier: mult, markup: Decimal(markupPct) / 100,
                                 minimumJobCents: minimum, billableHours: Decimal(billable))
            XCTAssertEqual([b.labor, b.equipment, b.overhead, b.materials, b.consumables, b.cost, b.price, b.profit],
                           [labor, equipment, overhead, materials, consumables, cost, price, profit], "case \(i)")
            XCTAssertEqual(Money.cents(b.marginPct * 10), margin1, "case \(i) margin one decimal")
            XCTAssertEqual(b.cost, b.labor + b.equipment + b.materials + b.consumables + b.subcontractors + b.overhead, "case \(i) Cost = Σ")
            XCTAssertEqual(b.profit, b.price - b.cost, "case \(i) Profit = Price − Cost")
            XCTAssertGreaterThanOrEqual(b.price, minimum, "case \(i) floor")
            checksum = (checksum * 31 + price + cost * 7 + margin1) % 1_000_000_007
            if i < 3 {
                print("PROBE200 case \(i): hoursH=\(hoursH) mult=\(mult) markup=\(markupPct) min=\(minimum) billable=\(billable) labor=\(labor) equip=\(equipment) ovh=\(overhead) mat=\(materials) cons=\(consumables) cost=\(cost) price=\(price) profit=\(profit) margin1=\(margin1)")
            }
        }
        print("PROBE200 checksum \(checksum)")
        XCTAssertEqual(checksum, 360_650_820, "reference generator drifted from the python mirror")
    }
}
