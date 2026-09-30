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
        // A salaried salesperson, not on the crew, who sold the removal at 7% (DECISIONS 83, 94). Synthetic.
        let sales = BucketItem(bucket: .labor, name: "Sam Rivera", rateCents: 4000,
                               sortOrder: BucketItem.nextSortOrder(in: .labor, context: context))
        sales.trackOnly = true
        sales.commissionPct = 7
        context.insert(sales)
        removal.setSalesperson(sales)

        let palms = Project.make(name: "Palm install", date: Date(timeIntervalSince1970: 1_757_900_000),
                                 items: try StoreFixture.items(in: context), settings: AppSettings())
        context.insert(palms)
        palms.client = "Sunridge HOA"
        palms.hours = 4
        palms.line("Mini skid steer").isOn = true
        let palm = palms.line("Queen palm, 10 gal"); palm.isOn = true; palm.qty = 6
        let stakes = palms.line("Stakes + ties kit"); stakes.isOn = true; stakes.qty = 6
        let mulch = palms.line("Mulch"); mulch.isOn = true; mulch.qty = 3
        // The salesperson's salary as an Overhead line worked out by the salary calculator (DECISIONS 93). Synthetic;
        // added after both projects so their prices stay the brief's.
        let pay = SalaryCalcInputs(amountCents: 22_500, period: .day, daysPerWeek: 5, weeksPerYear: 52, burdenPct: 30)
        context.insert(BucketItem(bucket: .overhead, name: "Sales salary", rateCents: try SalaryCalc.annualCents(pay),
                                  calcInputs: try JSONEncoder().encode(pay),
                                  sortOrder: BucketItem.nextSortOrder(in: .overhead, context: context)))
        try context.save()
    }
}
