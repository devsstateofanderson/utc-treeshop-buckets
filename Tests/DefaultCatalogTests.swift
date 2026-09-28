import XCTest
import SwiftData
@testable import Buckets

/// The product default catalog is neutral (DECISIONS 76–77) and corrected to OpenLoadout Tree Service Baseline 0.1
/// (DECISIONS 87): no company settings, no labor or equipment rows, overhead as a $0 checklist, none of the rows the
/// 2026-09-24 audit or the Baseline removed, and one chain, bar and sprocket row per exact spec on the Baseline's saw
/// cards. Read from the repository through `#filePath`, so it runs wherever the tests run from source.
@MainActor
final class DefaultCatalogTests: XCTestCase {
    private var dataURL: URL {
        URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().appending(path: "Scripts/catalog/data")
    }

    /// Species removed by the 2026-09-24 audit (DECISIONS 77) and by Baseline 0.1 §10.3 (F-CAT-16).
    private static let removed = ["Weeping Willow", "Majesty Palm", "Windmill Palm", "Queen Palm", "Ligustrum", "Loquat",
                                  "Tabebuia", "Bottlebrush", "River Birch", "Lemon Tree", "Orange Tree", "Washingtonia",
                                  "Senegal", "Royal Palm"]
    private static let wearCategory = "Saw wear parts (priced on saw rows)"

    /// The Baseline 0.1 saw cards (STANDARD §4.0, Appendix A): code, the three numbers, price in cents.
    private static let chains: [(code: String, spec: String, cents: Int)] = [
        ("33 RS 66", "3/8 in, .050 in, 66 DL", 3699),
        ("33 RS 72", "3/8 in, .050 in, 72 DL", 3989),
        ("33 RS 84", "3/8 in, .050 in, 84 DL", 4699),
        ("63 PS3 44", "3/8 in P, .050 in, 44 DL", 2299),
        ("63 PS3 55", "3/8 in P, .050 in, 55 DL", 2799),
        ("49-16-2723", "3/8 in LP, .043 in, 40 DL", 2797),
        ("49-16-2759", ".325 in LP, .043 in, 46 DL", 2797),
    ]
    private static let parts: [(number: String, cents: Int)] = [
        ("3003 008 8917", 5699), ("3003 008 8921", 6799), ("3003 000 4030", 10199), ("3005 000 4805", 4599),
        ("3005 000 4813", 5399), ("0000 642 1223", 1299), ("1145 640 2010", 3299), ("1137 640 2005", 0),
        ("5605 750 4305", 5499), ("5605 750 4303", 5499), ("48-11-1881", 22900), ("48-11-1813", 27900),
    ]

    private func document(_ name: String) throws -> (Data, TransferDocument) {
        let data = try Data(contentsOf: dataURL.appending(path: name))
        return (data, try Transfer.decoder().decode(TransferDocument.self, from: data))
    }

    func testDefaultCatalogIsNeutralAndMergesIntoAnEmptyStore() throws {
        let (data, doc) = try document("Buckets-default-catalog.json")
        XCTAssertNil(doc.settings, "the default catalog carries no company settings (DECISIONS 76)")
        XCTAssertTrue(TransferDocument.readableFormatVersions.contains(doc.formatVersion))
        XCTAssertTrue(doc.projects.isEmpty)
        for name in Self.removed {
            XCTAssertFalse(doc.items.contains { $0.name.localizedCaseInsensitiveContains(name) }, "\(name) was removed (DECISIONS 77, 87)")
        }
        let counts = Dictionary(grouping: doc.items, by: \.bucket).mapValues(\.count)
        XCTAssertEqual(counts, [.materials: 99, .consumables: 63, .overhead: 21])
        XCTAssertTrue(doc.items.filter { $0.bucket == .overhead }.allSatisfy { $0.rateCents == 0 }, "overhead is a $0 checklist")
        for name in ["Computers & devices", "Shop & fleet maintenance supplies"] {
            XCTAssertTrue(doc.items.contains { $0.bucket == .overhead && $0.name == name }, "\(name) (F-CAT-18)")
        }
        XCTAssertTrue(doc.items.allSatisfy { !$0.name.isEmpty && $0.rateCents >= 0 })
        XCTAssertEqual(Set(doc.items.map { "\($0.bucket)|\($0.name)" }).count, doc.items.count, "bucket + name is unique (merge key, DECISIONS 55)")
        XCTAssertTrue(doc.items.allSatisfy { $0.confidence == nil }, "a catalog file never vouches for a row (DECISIONS 74)")
        let container = try Store.inMemoryContainer()
        XCTAssertEqual(try Transfer.mergeItems(data, into: container.mainContext).added, 183)
        // Importing it whole keeps the company's settings instead of overwriting them.
        XCTAssertEqual(try Transfer.importJSON(data, into: container.mainContext), AppSettings.current())
        XCTAssertEqual(try container.mainContext.fetch(FetchDescriptor<BucketItem>()).count, 183)
    }

    /// F-LIST-01, F-CAT-01/02/10–13: one row per exact spec, each chain row naming pitch, gauge and drive links.
    func testDefaultCatalogCarriesTheBaselineSawCards() throws {
        let (_, doc) = try document("Buckets-default-catalog.json")
        let consumables = doc.items.filter { $0.bucket == .consumables }
        for chain in Self.chains {
            let rows = consumables.filter { $0.name.contains(chain.code) && $0.unit == "loop" }
            XCTAssertEqual(rows.count, 1, chain.code)
            XCTAssertTrue(rows.first?.name.contains(chain.spec) ?? false, "\(chain.code) names pitch, gauge and drive links")
            XCTAssertEqual(rows.first?.rateCents, chain.cents, chain.code)
            XCTAssertEqual(rows.first?.category, Self.wearCategory, chain.code)
            XCTAssertTrue(rows.first?.notes?.contains("2026-09-28") ?? false, "\(chain.code) carries the date seen")
            XCTAssertNotNil(rows.first?.link, chain.code)
        }
        XCTAssertEqual(consumables.filter { $0.unit == "loop" }.count, Self.chains.count, "no generic chain loop is left")
        for part in Self.parts {
            let rows = consumables.filter { $0.name.contains(part.number) }
            XCTAssertEqual(rows.count, 1, part.number)
            XCTAssertEqual(rows.first?.rateCents, part.cents, part.number)
            XCTAssertNotNil(rows.first?.link, part.number)
        }
        // Rows the corrections replaced must be gone.
        for stale in ["3/8 RS3 .063", "Oregon 90PX)", "HIGH OUTPUT", "3003 000 5221", "56 drive links", "Pump gas", "Diesel \u{2013}"] {
            XCTAssertFalse(doc.items.contains { $0.name.contains(stale) }, stale)
        }
        let reel = try XCTUnwrap(consumables.first { $0.name.contains("72LPX") })
        XCTAssertTrue(reel.name.contains("3/8 in, .050 in, 410 DL") && !reel.name.contains("low-profile"), "72LPX is standard 3/8 in (F-CAT-10)")
        let files = consumables.filter { $0.name.hasPrefix("Round chainsaw file") }
        XCTAssertEqual(files.count, 2)
        XCTAssertTrue(files.allSatisfy { $0.unit == "pack" && $0.rateCents == 3199 }, "a dozen is $31.99 (F-CAT-03)")
        XCTAssertEqual(consumables.first { $0.name.hasPrefix("Bar and chain oil \u{2013} 5 gallon") }?.unit, "pail", "F-CAT-05")
    }

    /// The archive file lists every default row that was renamed or removed, under its old name, archived, so a store
    /// that merged the old default can archive them (merge matches by bucket + name, DECISIONS 55).
    func testBaselineArchiveCoversEveryRenamedOrRemovedRow() throws {
        let (_, current) = try document("Buckets-default-catalog.json")
        let (archiveData, archive) = try document("archive-2026-09-28-baseline-0.1.json")
        XCTAssertEqual(archive.items.count, 27)
        XCTAssertTrue(archive.items.allSatisfy { !$0.isActive })
        let now = Set(current.items.map { "\($0.bucket)|\($0.name)" })
        for item in archive.items {
            XCTAssertFalse(now.contains("\(item.bucket)|\(item.name)"), "\(item.name) is no longer a default row")
        }
        // A store holding one of the old rows gets it archived, and nothing else changes.
        let container = try Store.inMemoryContainer()
        let context = container.mainContext
        let old = try XCTUnwrap(archive.items.first)
        context.insert(BucketItem(bucket: old.bucket, name: old.name, rateCents: old.rateCents, sortOrder: 0))
        context.insert(BucketItem(bucket: .consumables, name: "A row the company typed", rateCents: 100, sortOrder: 1))
        try context.save()
        _ = try Transfer.mergeItems(archiveData, into: context)
        let rows = try context.fetch(FetchDescriptor<BucketItem>())
        XCTAssertFalse(try XCTUnwrap(rows.first { $0.name == old.name }).isActive)
        XCTAssertTrue(try XCTUnwrap(rows.first { $0.name == "A row the company typed" }).isActive)
    }

    func testStarterCatalogCarriesNoSettingsAndNoRemovedRows() throws {
        let (_, doc) = try document("Buckets-starter-catalog.json")
        XCTAssertNil(doc.settings)
        for name in Self.removed where name != "Royal Palm" {  // the company's own royal palm row is the owner's call
            XCTAssertFalse(doc.items.contains { $0.name.localizedCaseInsensitiveContains(name) }, name)
        }
        let counts = Dictionary(grouping: doc.items, by: \.bucket).mapValues(\.count)
        XCTAssertEqual(counts, [.equipment: 19, .materials: 76, .consumables: 19, .overhead: 18])
    }

    /// F-FLEET-01, -02, -04: the company edition's corrected saws and machine, with rates from the same one-division
    /// calculator the app uses (DECISIONS 7), never typed by hand.
    func testStarterFleetCorrectionsPriceThroughTheCalculator() throws {
        let (_, doc) = try document("Buckets-starter-catalog.json")
        let expected: [String: (price: Int, fuel: Int?)] = [
            "Stihl 201T": (94999, nil),
            "Stihl 194T (MS 193 T unit, honorary upgrade)": (50999, nil),
            "Toro Mini Skid": (3297600, 633),
        ]
        XCTAssertFalse(doc.items.contains { $0.name == "Stihl 193" })
        for (name, want) in expected {
            let row = try XCTUnwrap(doc.items.first { $0.bucket == .equipment && $0.name == name }, name)
            let data = try XCTUnwrap(row.calcInputs?.data, name)
            let ci = try JSONDecoder().decode(EquipmentCalcInputs.self, from: data)
            XCTAssertEqual(ci.priceCents, want.price, name)
            if let fuel = want.fuel { XCTAssertEqual(ci.fuelOilPerHourCents, fuel, name) }
            let rate = try EquipmentCalc.rateCents(price: ci.priceCents, salvage: ci.salvageCents, lifeHours: ci.lifeHours,
                                                   annualHours: ci.annualHours, fuelOilPerHour: ci.fuelOilPerHourCents,
                                                   repairFactor: ci.repairFactor, insurancePerYear: ci.insurancePerYearCents,
                                                   costOfMoney: ci.costOfMoneyPct / 100)
            XCTAssertEqual(row.rateCents, rate, name)
            XCTAssertTrue(row.notes?.contains("2026-09-28") ?? false, name)
        }
        let pole = try XCTUnwrap(doc.items.first { $0.name == "Milwaukee Pole Saw" })
        XCTAssertFalse(pole.notes?.contains("~13ft") ?? true, "the 3016-21PS reaches 7-10 ft (F-CAT-19)")
    }
}
