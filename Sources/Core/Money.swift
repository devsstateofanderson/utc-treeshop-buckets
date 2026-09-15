import Foundation

/// Money is Int cents everywhere it is stored or displayed; arithmetic happens in `Decimal`.
/// Rounding is half-away-from-zero and happens once, at the moment a figure becomes cents.
enum Money {
    /// Rounds an amount expressed in cents (possibly fractional) to whole cents, half away from zero.
    /// A NaN or infinite amount is 0; an amount beyond `Int` saturates at `Int.max` / `Int.min`
    /// instead of wrapping (DECISIONS 49). Neither can happen with bounded inputs (DECISIONS 30).
    static func cents(_ amount: Decimal) -> Int {
        guard amount.isFinite else { return 0 }
        var value = amount
        var rounded = Decimal()
        NSDecimalRound(&rounded, &value, 0, .plain)   // .plain == half away from zero
        if rounded >= Decimal(Int.max) { return Int.max }
        if rounded <= Decimal(Int.min) { return Int.min }
        return NSDecimalNumber(decimal: rounded).intValue
    }

    /// `Decimal` dollars from Int cents, exactly (no floating point).
    static func decimal(cents: Int) -> Decimal {
        Decimal(cents) / 100
    }

    /// Lifts a `Double` (e.g. an `@AppStorage` percent) into `Decimal` through its shortest round-trip
    /// text, never through the binary value: 32.5 becomes exactly 32.5 (DECISIONS 11). Non-finite → 0.
    static func decimal(from double: Double) -> Decimal {
        guard double.isFinite else { return 0 }
        return Decimal(string: "\(double)", locale: Locale(identifier: "en_US_POSIX")) ?? 0
    }

    /// Formats Int cents as US dollars, e.g. 250150 → "$2,501.50". Negative amounts keep the sign.
    /// Pinned to en_US so the output is the same on every machine (STS prices in US dollars).
    static func format(_ cents: Int) -> String {
        let sign = cents < 0 ? "-" : ""
        let magnitude = cents.magnitude
        let dollars = magnitude / 100
        let rem = magnitude % 100
        let grouped = dollars.formatted(.number.grouping(.automatic).locale(Locale(identifier: "en_US")))
        return "\(sign)$\(grouped).\(rem < 10 ? "0\(rem)" : "\(rem)")"
    }
}
