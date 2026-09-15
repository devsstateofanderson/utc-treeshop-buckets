import SwiftUI

/// Text field bound to a `Decimal` that updates on every keystroke (BRIEF §5.5 "recomputes on every keystroke").
/// Non-negative, at most two decimal places; empty or invalid text leaves the last good value (DECISIONS 30).
struct DecimalField: View {
    let label: String
    @Binding var value: Decimal
    var placeholder = "0"
    /// DECISIONS 30: hours ≤ 99,999.99; quantities ≤ 999,999.99.
    var maximum: Decimal = Decimal(string: "999999.99")!
    @State private var text = ""
    @FocusState private var focused: Bool

    var body: some View {
        TextField(label, text: $text, prompt: Text(placeholder))
            .multilineTextAlignment(.trailing)
            .focused($focused)
            .onAppear { text = Self.string(value) }
            .onChange(of: text) { _, new in
                if let parsed = Self.parse(new, maximum: maximum), parsed != value { value = parsed }
            }
            .onChange(of: value) { _, new in
                if Self.parse(text, maximum: maximum) != new { text = Self.string(new) }
            }
            .onChange(of: focused) { _, isFocused in
                if !isFocused { text = Self.string(value) }
            }
    }

    /// Accepts only a plain non-negative number with at most two decimals (DECISIONS 51); "" is 0; anything else is nil.
    static func parse(_ text: String, maximum: Decimal = Decimal(string: "999999.99")!) -> Decimal? {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty { return 0 }
        guard isPlainNumber(trimmed), let d = Decimal(string: trimmed, locale: Locale(identifier: "en_US_POSIX")),
              d.isFinite, d >= 0, d <= maximum else { return nil }
        return d
    }

    static func isPlainNumber(_ s: String) -> Bool {
        var seenDot = false, digits = 0, fraction = 0
        for ch in s {
            if ch == "." { if seenDot { return false }; seenDot = true; continue }
            guard ch.isASCII, ch.isNumber else { return false }
            digits += 1
            if seenDot { fraction += 1 }
        }
        return digits > 0 && fraction <= 2
    }

    static func string(_ value: Decimal) -> String {
        value == 0 ? "" : value.formatted(.number.precision(.fractionLength(0...2)).grouping(.never).locale(Locale(identifier: "en_US")))
    }
}

/// Text field bound to Int cents, edited as dollars ("54.08"), updating on every keystroke.
struct CentsField: View {
    let label: String
    @Binding var cents: Int
    var placeholder = "0.00"
    @State private var text = ""
    @FocusState private var focused: Bool

    var body: some View {
        TextField(label, text: $text, prompt: Text(placeholder))
            .multilineTextAlignment(.trailing)
            .focused($focused)
            .onAppear { text = Self.string(cents) }
            .onChange(of: text) { _, new in
                if let parsed = Self.parse(new), parsed != cents { cents = parsed }
            }
            .onChange(of: cents) { _, new in
                if Self.parse(text) != new { text = Self.string(new) }
            }
            .onChange(of: focused) { _, isFocused in
                if !isFocused { text = Self.string(cents) }
            }
    }

    /// Dollars with an optional "$" and thousands separators, at most two decimals, ≤ $9,999,999.99 (DECISIONS 30, 51).
    static func parse(_ text: String) -> Int? {
        var trimmed = text.trimmingCharacters(in: .whitespaces)
        trimmed.removeAll { $0 == "$" || $0 == "," }
        if trimmed.isEmpty { return 0 }
        guard DecimalField.isPlainNumber(trimmed), let d = Decimal(string: trimmed, locale: Locale(identifier: "en_US_POSIX")),
              d.isFinite, d >= 0, d <= Decimal(string: "9999999.99")! else { return nil }
        return Money.cents(d * 100)
    }

    static func string(_ cents: Int) -> String {
        cents == 0 ? "" : Money.decimal(cents: cents).formatted(.number.precision(.fractionLength(2)).grouping(.never).locale(Locale(identifier: "en_US")))
    }
}

/// Optional text bound to a `String?` model field (empty ⇢ nil).
struct OptionalTextField: View {
    let label: String
    @Binding var value: String?
    var prompt: String = ""
    /// `.vertical` grows with its text (notes); `.horizontal` is a one-line field.
    var axis: Axis = .horizontal

    var body: some View {
        TextField(label, text: Binding(get: { value ?? "" }, set: { value = $0.isEmpty ? nil : $0 }), prompt: Text(prompt), axis: axis)
    }
}

/// Formats a whole-percent Decimal with one decimal, e.g. 25.926 → "25.9%".
func percentString(_ pct: Decimal) -> String {
    pct.formatted(.number.precision(.fractionLength(1)).locale(Locale(identifier: "en_US"))) + "%"
}

/// Formats hours with grouping and up to two decimals, e.g. 2080 → "2,080", 1500 → "1,500", 6.5 → "6.5".
func hoursString(_ value: Decimal) -> String {
    value.formatted(.number.precision(.fractionLength(0...2)).grouping(.automatic).locale(Locale(identifier: "en_US")))
}
