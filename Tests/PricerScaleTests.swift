import XCTest
@testable import Buckets

/// Many rows: correctness of the sums and time per call (Pricer runs on every keystroke, BRIEF §5.5).
final class Probe_pricer_scale: XCTestCase {
    func testTenThousandRowsValuesAndTime() {
        // 400 copies of the 25-row §3.3 fixture = 10,000 rows: every subtotal scales exactly by 400
        let lines = Array(repeating: Fixture.lines(), count: 400).flatMap { $0 }
        XCTAssertEqual(lines.count, 10_000)
        let start = Date()
        let b = Fixture.price(lines)
        let elapsed = Date().timeIntervalSince(start)
        XCTAssertEqual(b.labor, 39_804_800)
        XCTAssertEqual(b.equipment, 22_553_600)
        XCTAssertEqual(b.overhead, 5_760_000)
        XCTAssertEqual(b.consumables, 6_000_000)
        XCTAssertEqual(b.cost, 74_118_400)
        XCTAssertEqual(b.price, 100_059_840)   // 74,118,400 × 1.35 exactly
        XCTAssertEqual(b.profit, 25_941_440)
        print("PROBE scale 10,000 rows: \(elapsed * 1000) ms")
        XCTAssertLessThan(elapsed, 0.25, "10,000 rows must price well within a keystroke")
    }

    func testHundredThousandRowsTime() {
        let lines = Array(repeating: Fixture.lines(), count: 4000).flatMap { $0 }
        let start = Date()
        let b = Fixture.price(lines)
        let elapsed = Date().timeIntervalSince(start)
        XCTAssertEqual(b.cost, 741_184_000)
        XCTAssertEqual(b.price, 1_000_598_400)
        print("PROBE scale 100,000 rows: \(elapsed * 1000) ms")
    }

    func testRepeatedCallsForTypingBurst() {
        // 25 rows × 1,000 keystrokes
        let lines = Fixture.lines()
        let start = Date()
        var last = 0
        for h in 1...1000 { last = Fixture.price(lines, hours: Decimal(h) / 100).price }
        let elapsed = Date().timeIntervalSince(start)
        // last call is 10.00 h: 124390 + 70480 + 18000 + 15000 = 227870 ; × 1.35 = 307624.5 → 307625 (tie, away from zero)
        XCTAssertEqual(last, 307_625)
        print("PROBE scale 1,000 calls × 25 rows: \(elapsed * 1000) ms")
        XCTAssertLessThan(elapsed, 1.0)
    }
}
