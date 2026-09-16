import XCTest
import SwiftData
@testable import Buckets

/// Writes the §3.3 rows and two projects into a store file for screenshots, ONLY when
/// `BUCKETS_FIXTURE_STORE` names a path (Scripts/screenshot.sh --fixture). The app itself never seeds data.
@MainActor
final class FixtureStoreWriter: XCTestCase {
    func testWriteFixtureStore() throws {
        guard let path = ProcessInfo.processInfo.environment["BUCKETS_FIXTURE_STORE"], !path.isEmpty else {
            throw XCTSkip("set BUCKETS_FIXTURE_STORE to write a screenshot fixture store")
        }
        for suffix in ["", "-wal", "-shm"] { try? FileManager.default.removeItem(atPath: path + suffix) }
        let container = try Store.container(at: URL(fileURLWithPath: path))
        let context = container.mainContext
        let rows = StoreFixture.insertRows(into: context)
        rows["Marcus"]!.calcInputs = try JSONEncoder().encode(LaborCalcInputs(wageCents: 3000, paidHours: 2080, burdenPct: 30))
        rows["David"]!.calcInputs = try JSONEncoder().encode(LaborCalcInputs(wageCents: 2200, paidHours: 2080, burdenPct: 30))
        rows["Miguel"]!.calcInputs = try JSONEncoder().encode(LaborCalcInputs(wageCents: 1700, paidHours: 2080, burdenPct: 30))
        rows["Bucket truck (50 ft)"]!.calcInputs = try JSONEncoder().encode(EquipmentCalcInputs(
            priceCents: 6_500_000, salvageCents: 1_500_000, lifeHours: 8000, annualHours: 1500, fuelOilPerHourCents: 728,
            repairFactor: Decimal(string: "0.80")!, insurancePerYearCents: 240_000, costOfMoneyPct: 7))
        rows["Dump fee"]!.source = "Orange County landfill"
        rows["Grapple truck (sub)"]!.source = "Central FL Grapple"
        rows["Stump grinding (sub)"]!.source = "J&J Stump"
        rows["Queen palm, 10 gal"]!.source = "Cherry Lake"
        rows["Mulch"]!.source = "Royal"

        let removal = try StoreFixture.baseProject(in: context)
        removal.name = "Oak removal"
        removal.client = "R. Delgado"
        removal.date = Date(timeIntervalSince1970: 1_757_800_000)
        removal.notes = "Gate on the left; dump run at lunch."
        removal.actualHours = 10
        removal.line("Dump fee").actualQty = 3
        removal.setPricing(from: AppSettings())   // priced at the company's 50% target margin (DECISIONS 70)

        let palms = Project.make(name: "Palm install", date: Date(timeIntervalSince1970: 1_757_900_000),
                                 items: try StoreFixture.items(in: context), settings: AppSettings())
        context.insert(palms)
        palms.client = "Sunridge HOA"
        palms.hours = 4
        palms.line("Mini skid steer").isOn = true
        let palm = palms.line("Queen palm, 10 gal"); palm.isOn = true; palm.qty = 6
        let stakes = palms.line("Stakes + ties kit"); stakes.isOn = true; stakes.qty = 6
        let mulch = palms.line("Mulch"); mulch.isOn = true; mulch.qty = 3
        try context.save()
    }
}
