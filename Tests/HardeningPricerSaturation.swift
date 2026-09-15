import XCTest
@testable import Buckets

/// Values whose exact result exceeds Int64: Money.cents goes through NSDecimalNumber.intValue, which wraps modulo 2^64
/// on this toolchain instead of saturating. Nothing traps here; the figures are silently wrong (and can go negative).
final class Probe_pricer_wrap: XCTestCase {
    func testIntMaxRateAtEightHoursWrapsToMinusEightCents() {
        // exact 8 × Int.max = 73,786,976,294,838,206,456 ; mod 2^64 = 2^64 − 8 → −8
        let b = Fixture.price([PriceLine(bucket: .labor, rateCents: Int.max)], hours: 8)
        XCTAssertGreaterThanOrEqual(b.labor, 0, "a positive rate × positive hours must never price negative (got \(b.labor))")
        XCTAssertNotEqual(b.labor, -8)
    }

    func testIntMaxMultiplierWrapsThePriceNegativeAndTheFloorHidesIt() {
        // 185296 × 1.35 × Int.max ≈ 2.3e24 ; mod 2^64 → −3,689,348,814,742,160,473 ; price = max(75000, that) = 75000
        let b = Fixture.price(Fixture.lines(), multiplier: Int.max)
        XCTAssertGreaterThanOrEqual(b.price, b.cost, "price fell below cost at an absurd multiplier: price \(b.price), cost \(b.cost)")
        let noFloor = Fixture.price(Fixture.lines(), multiplier: Int.max, minimum: 0)
        XCTAssertGreaterThanOrEqual(noFloor.price, 0, "price is negative: \(noFloor.price)")
    }

    func testHugeQtyTimesHugeRateWrapsInsteadOfSaturating() {
        // 1e10 ¢ × 1e10 = 1e20 > Int.max ; 1e20 mod 2^64 = 7,766,279,631,452,241,920
        let b = Fixture.price([PriceLine(bucket: .consumables, rateCents: 10_000_000_000, isOn: true, qty: 10_000_000_000)], hours: 0, minimum: 0)
        XCTAssertNotEqual(b.consumables, 7_766_279_631_452_241_920, "subtotal wrapped modulo 2^64")
        XCTAssertEqual(b.consumables, Int.max, "an over-range subtotal should saturate (or be rejected upstream), not wrap")
    }

    func testSixteenDigitHoursOnTheBriefProjectPriceLaborNegative() {
        // hours = 1e15 (typeable, two-decimal rule satisfied): 12439 × 1e15 = 1.2439e19 > Int.max → wraps to −6,007,744,073,709,551,616
        let b = Fixture.price(Fixture.lines(), hours: 1_000_000_000_000_000)
        XCTAssertGreaterThanOrEqual(b.labor, 0, "labor priced at \(b.labor) cents for 1e15 hours")
        XCTAssertNotEqual(b.labor, -6_007_744_073_709_551_616)
        // at 3× the marked price wraps too and the floor hides it: price 75000 against a cost of 2.84e18
        let three = Fixture.price(Fixture.lines(), hours: 1_000_000_000_000_000, multiplier: 3)
        XCTAssertGreaterThanOrEqual(three.price, three.cost, "price \(three.price) < cost \(three.cost)")
    }

    func testMoneyCentsAboveInt64WrapsModulo2Pow64() {
        XCTAssertEqual(Money.cents(Decimal(string: "1e20")!), Int.max, "expected saturation; wrap gives 7766279631452241920")
        XCTAssertEqual(Money.cents(Decimal(string: "-1e20")!), Int.min, "expected saturation; wrap gives -7766279631452241920")
        // and exactness inside the range, including above 2^53 where a double round-trip would lose bits
        XCTAssertEqual(Money.cents(Decimal(string: "9007199254740993")!), 9_007_199_254_740_993)
        XCTAssertEqual(Money.cents(Decimal(Int.max)), Int.max)
        XCTAssertEqual(Money.cents(Decimal(Int.min)), Int.min)
        XCTAssertEqual(Decimal(Int.max), Decimal(string: "9223372036854775807")!)
        XCTAssertEqual(Decimal(Int.min), Decimal(string: "-9223372036854775808")!)
    }
}
