import Foundation

/// Money is Int cents everywhere it is stored or displayed; arithmetic happens in `Decimal`.
/// Rounding is half-away-from-zero and happens once, at the moment a figure becomes cents.
enum Money {
    /// Rounds a `Decimal` amount of dollars-and-fractions-of-cents to whole cents, half away from zero.
    static func cents(_ amount: Decimal) -> Int {
        var value = amount
        var rounded = Decimal()
        NSDecimalRound(&rounded, &value, 0, .plain)   // .plain == half away from zero
        return NSDecimalNumber(decimal: rounded).intValue
    }

    /// `Decimal` dollars from Int cents, exactly (no floating point).
    static func decimal(cents: Int) -> Decimal {
        Decimal(cents) / 100
    }

    /// Formats Int cents as US dollars, e.g. 250150 → "$2,501.50". Negative amounts keep the sign.
    /// Pinned to en_US so the output is the same on every machine (STS prices in US dollars).
    static func format(_ cents: Int) -> String {
        let sign = cents < 0 ? "-" : ""
        let abs = Swift.abs(cents)
        let dollars = abs / 100
        let rem = abs % 100
        let grouped = dollars.formatted(.number.grouping(.automatic).locale(Locale(identifier: "en_US")))
        return "\(sign)$\(grouped).\(String(format: "%02d", rem))"
    }
}
