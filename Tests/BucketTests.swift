import XCTest
@testable import Buckets

/// BRIEF §5.3 `enum Bucket: String, Codable, CaseIterable { case labor, equipment, materials, consumables, overhead }`
/// plus the rowKind comment; DECISIONS 2, 25, 32. There is no Bucket test in the suite today.
final class Probe_spec_Bucket: XCTestCase {
    func testFiveCasesInSection53Order() {
        XCTAssertEqual(Bucket.allCases.count, 5)
        XCTAssertEqual(Bucket.allCases, [.labor, .equipment, .materials, .consumables, .overhead])
    }

    func testCodableRawValuesAreLowercaseNames() throws {
        XCTAssertEqual(Bucket.allCases.map(\.rawValue), ["labor", "equipment", "materials", "consumables", "overhead"])
        let json = try JSONEncoder().encode(Bucket.allCases)
        XCTAssertEqual(String(decoding: json, as: UTF8.self), #"["labor","equipment","materials","consumables","overhead"]"#)
        XCTAssertEqual(try JSONDecoder().decode([Bucket].self, from: json), Bucket.allCases)
        XCTAssertThrowsError(try JSONDecoder().decode([Bucket].self, from: Data(#"["Labor"]"#.utf8)))
        XCTAssertNil(Bucket(rawValue: "Equipment"))
    }

    func testRowKindMapping() {
        XCTAssertEqual(Bucket.labor.rowKind, .hourly)
        XCTAssertEqual(Bucket.equipment.rowKind, .hourly)
        XCTAssertEqual(Bucket.overhead.rowKind, .hourly)
        XCTAssertEqual(Bucket.materials.rowKind, .quantity)
        XCTAssertEqual(Bucket.consumables.rowKind, .quantity)
    }

    func testFixedUnitsAndAnnualFlag() {
        // DECISIONS 25: hourly buckets fixed ("hr", "hr", "yr"); quantity buckets free text.
        XCTAssertEqual(Bucket.allCases.map(\.fixedUnit), ["hr", "hr", nil, nil, "yr"])
        // DECISIONS 4: only overhead is an annual figure priced as $/yr ÷ billable hours.
        XCTAssertEqual(Bucket.allCases.filter(\.isAnnual), [.overhead])
        XCTAssertEqual(Bucket.allCases.map(\.title), ["Labor", "Equipment", "Materials", "Consumables", "Overhead"])
    }
}
