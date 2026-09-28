import XCTest

/// The privacy guard (DECISIONS 88): no VIN, EIN or insurance policy number in the catalog data or the docs, which are
/// public. Scans every UTF-8 text file under `Scripts/catalog/data` and `docs`, located from `#filePath` so it runs
/// wherever the tests run from source. `Tests/` is deliberately not scanned: its fixtures carry synthetic test values.
/// A hit is reported by file and pattern only, never by the matched text, so a failing run does not repeat the number.
final class PrivacyGuardTests: XCTestCase {
    private var root: URL {
        URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
    }

    /// 17 characters from the VIN alphabet (no I, O or Q), standing alone, with at least one digit and one letter.
    static let vin = try! NSRegularExpression(
        pattern: "(?<![A-Za-z0-9])(?=[A-HJ-NPR-Z0-9]{0,16}[0-9])(?=[A-HJ-NPR-Z0-9]{0,16}[A-HJ-NPR-Z])[A-HJ-NPR-Z0-9]{17}(?![A-Za-z0-9])")
    /// NN-NNNNNNN standing alone. A match preceded by "%", "/", "-", "_" or "." is part of a URL or a part number
    /// (a percent-encoded quote followed by a product id reads "%22-1027153"), not an EIN.
    static let ein = try! NSRegularExpression(pattern: "(?<![0-9A-Za-z%/._-])[0-9]{2}-[0-9]{7}(?![0-9A-Za-z/_-])")
    /// "policy" followed by six or more digits, allowing "#", ":", "no." or "number" between them.
    static let policy = try! NSRegularExpression(
        pattern: "\\bpolic(?:y|ies)\\b[\\s#:.]*(?:no\\.?|number|num\\.?)?[\\s#:.]*[0-9]{6,}", options: [.caseInsensitive])

    static func hits(in text: String) -> [String] {
        let range = NSRange(text.startIndex..., in: text)
        return [("VIN", vin), ("EIN", ein), ("policy number", policy)]
            .filter { $0.1.firstMatch(in: text, range: range) != nil }.map(\.0)
    }

    func testCatalogDataAndDocsCarryNoVinEinOrPolicyNumber() throws {
        var scanned = 0
        var findings: [String] = []
        for folder in ["Scripts/catalog/data", "docs"] {
            let base = root.appending(path: folder)
            let files = try XCTUnwrap(FileManager.default.enumerator(at: base, includingPropertiesForKeys: [.isRegularFileKey]))
            for case let url as URL in files where (try? url.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) == true {
                guard let text = try? String(contentsOf: url, encoding: .utf8) else { continue }  // images and other binaries
                scanned += 1
                for kind in Self.hits(in: text) {
                    findings.append("\(url.path.replacingOccurrences(of: root.path + "/", with: "")): \(kind)-shaped token")
                }
            }
        }
        XCTAssertGreaterThan(scanned, 20, "the scan found the catalog data and docs")
        XCTAssertTrue(findings.isEmpty, "private identifiers in public files:\n" + findings.joined(separator: "\n"))
    }

    /// The patterns themselves, on synthetic values built at run time so no identifier-shaped literal sits in the source.
    func testPatternsCatchTheShapesAndIgnoreTheCatalogsOwnNumbers() {
        let fakeVin = String(repeating: "A1", count: 8) + "B"
        XCTAssertEqual(fakeVin.count, 17)
        XCTAssertEqual(Self.hits(in: "VIN \(fakeVin) on the door"), ["VIN"])
        XCTAssertEqual(Self.hits(in: "\"notes\": \"\(fakeVin)\""), ["VIN"])
        XCTAssertEqual(Self.hits(in: "EIN " + "12" + "-" + "3456789"), ["EIN"])
        XCTAssertEqual(Self.hits(in: "GEICO policy " + String(repeating: "7", count: 9) + "-0"), ["policy number"])
        XCTAssertEqual(Self.hits(in: "Policy #: " + String(repeating: "4", count: 6)), ["policy number"])
        // Not identifiers: all digits or all letters, a lowercase hash, part numbers, prices, dates, URLs, phone numbers.
        XCTAssertEqual(Self.hits(in: String(repeating: "7", count: 17)), [])
        XCTAssertEqual(Self.hits(in: String(repeating: "AB", count: 8) + "C"), [])
        XCTAssertEqual(Self.hits(in: String(repeating: "a1", count: 8) + "b"), [])
        XCTAssertEqual(Self.hits(in: "Milwaukee 49-16-2723, STIHL 3003 008 8917, 48-11-1881, $32,976.00 on 2026-09-28"), [])
        XCTAssertEqual(Self.hits(in: "https://www.stihlusa.com/en/ap/picco-super-3-ps3-3-8%22-050%22-1027153"), [])
        XCTAssertEqual(Self.hits(in: "(321) 204-8459; fleet policy \u{00f7} 4 units; policy renews 2027"), [])
    }
}
