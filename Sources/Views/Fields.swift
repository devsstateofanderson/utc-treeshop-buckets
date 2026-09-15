import SwiftUI

/// Text field bound to a `Decimal` that updates on every keystroke (BRIEF §5.5 "recomputes on every keystroke").
/// Non-negative, at most two decimal places; empty or invalid text leaves the last good value (DECISIONS 30).
struct DecimalField: View {
    let label: String
    @Binding var value: Decimal
    var placeholder = "0"
    @State private var text = ""
    @FocusState private var focused: Bool

    var body: some View {
        TextField(label, text: $text, prompt: Text(placeholder))
            .multilineTextAlignment(.trailing)
            .focused($focused)
            .onAppear { text = Self.string(value) }
            .onChange(of: text) { _, new in
                if let parsed = Self.parse(new), parsed != value { value = parsed }
            }
            .onChange(of: value) { _, new in
                if Self.parse(text) != new { text = Self.string(new) }
            }
            .onChange(of: focused) { _, isFocused in
                if !isFocused { text = Self.string(value) }
            }
    }

    static func parse(_ text: String) -> Decimal? {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty { return 0 }
        guard let d = Decimal(string: trimmed, locale: Locale(identifier: "en_US")), d.isFinite, d >= 0 else { return nil }
        return Money.decimal(cents: Money.cents(d * 100))     // at most two decimals
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

    static func parse(_ text: String) -> Int? {
        var trimmed = text.trimmingCharacters(in: .whitespaces)
        trimmed.removeAll { $0 == "$" || $0 == "," }
        if trimmed.isEmpty { return 0 }
        guard let d = Decimal(string: trimmed, locale: Locale(identifier: "en_US")), d.isFinite, d >= 0,
              d < 1_000_000_000 else { return nil }
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

    var body: some View {
        TextField(label, text: Binding(get: { value ?? "" }, set: { value = $0.isEmpty ? nil : $0 }), prompt: Text(prompt))
    }
}

/// Formats a whole-percent Decimal with one decimal, e.g. 25.926 → "25.9%".
func percentString(_ pct: Decimal) -> String {
    pct.formatted(.number.precision(.fractionLength(1)).locale(Locale(identifier: "en_US"))) + "%"
}
