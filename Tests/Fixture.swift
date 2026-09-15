import Foundation
@testable import Buckets

/// BRIEF §3.3 worked example as `PriceLine`s. Test-target only — the app ships empty.
enum Fixture {
    static let billable: Decimal = 1500
    static let markup = Decimal(string: "0.35")!
    static let minimum = 75000

    // Labor ($/hr cents)
    static let marcus = PriceLine(bucket: .labor, rateCents: 5408)
    static let david = PriceLine(bucket: .labor, rateCents: 3966)
    static let miguel = PriceLine(bucket: .labor, rateCents: 3065)
    // Equipment ($/hr cents)
    static let bucketTruck = PriceLine(bucket: .equipment, rateCents: 2372)
    static let chipTruck = PriceLine(bucket: .equipment, rateCents: 2215)
    static let chipper = PriceLine(bucket: .equipment, rateCents: 1711)
    static let chainsaws = PriceLine(bucket: .equipment, rateCents: 750)
    static let skidSteer = PriceLine(bucket: .equipment, rateCents: 1603, isOn: false)
    // Overhead ($/yr cents)
    static let overhead: [PriceLine] = [600_000, 960_000, 360_000, 240_000, 240_000, 180_000, 120_000]
        .map { PriceLine(bucket: .overhead, rateCents: $0) }
    // Materials (unit cost cents, all off)
    static let materials: [PriceLine] = [8500, 4500, 3200, 1200]
        .map { PriceLine(bucket: .materials, rateCents: $0, isOn: false) }
    // Consumables (unit cost cents)
    static let dumpFee = PriceLine(bucket: .consumables, rateCents: 7500, isOn: true, qty: 2)
    static let grapple = PriceLine(bucket: .consumables, rateCents: 65_000, isOn: false)
    static let stumpGrinding = PriceLine(bucket: .consumables, rateCents: 9000, isOn: false)
    static let crane = PriceLine(bucket: .consumables, rateCents: 180_000, isOn: false)
    static let cambistat = PriceLine(bucket: .consumables, rateCents: 12_000, isOn: false)
    static let permit = PriceLine(bucket: .consumables, rateCents: 5000, isOn: false)

    /// The 25 rows of §2.1–§2.5 in the §3.3 base state (skid steer off, dump fee on ×2, all else default).
    static func lines(miguelOn: Bool = true, skidSteerOn: Bool = false, stumps: Decimal? = nil) -> [PriceLine] {
        var miguelLine = miguel; miguelLine.isOn = miguelOn
        var skid = skidSteer; skid.isOn = skidSteerOn
        var stump = stumpGrinding
        if let stumps { stump.isOn = true; stump.qty = stumps }
        return [marcus, david, miguelLine,
                bucketTruck, chipTruck, chipper, chainsaws, skid]
            + overhead + materials
            + [dumpFee, grapple, stump, crane, cambistat, permit]
    }

    static func price(_ lines: [PriceLine], hours: Decimal = 8, multiplier: Int = 1,
                      markup: Decimal = markup, minimum: Int = minimum, billable: Decimal = billable) -> Breakdown {
        Pricer.price(lines: lines, hours: hours, multiplier: multiplier, markup: markup,
                     minimumJobCents: minimum, billableHours: billable)
    }
}
