import SwiftUI
import SwiftData

/// The Labor "Calculate…" sheet's inputs and live result (BRIEF §2.1; DECISIONS 35). Plain data so it is testable.
struct LaborCalcDraft: Equatable {
    var wageCents: Int
    var paidHours: Decimal
    /// Whole percent (30), editable per row; the default comes from Settings.
    var burdenPct: Decimal
    /// Read-only, from Settings.
    var billableHours: Decimal

    init(saved: LaborCalcInputs?, settings: AppSettings) {
        wageCents = saved?.wageCents ?? 0
        paidHours = saved?.paidHours ?? 2080
        burdenPct = saved?.burdenPct ?? settings.laborBurdenPctDecimal
        billableHours = settings.billableHours
    }

    var inputs: LaborCalcInputs {
        LaborCalcInputs(wageCents: wageCents, paidHours: paidHours, burdenPct: burdenPct)
    }

    /// $/project-hour in cents, or the typed error. Burden enters as the exact fraction pct ÷ 100 (DECISIONS 11).
    var result: Result<Int, any Error> {
        Result { try LaborCalc.rateCents(wage: wageCents, paidHours: paidHours, burden: burdenPct / 100, billable: billableHours) }
    }

    /// "$30.00 × 1.30 × 2,080 ÷ 1,500"
    var formula: String {
        let factor = (1 + burdenPct / 100).formatted(.number.precision(.fractionLength(2...4)).locale(Locale(identifier: "en_US")))
        return "\(Money.format(wageCents)) × \(factor) × \(hoursString(paidHours)) ÷ \(hoursString(billableHours))"
    }
}

/// One-line messages for the calculators' typed errors.
enum CalcMessage {
    static func text(for error: any Error) -> String {
        if let e = error as? LaborCalcError {
            switch e {
            case .negativeWage: return "The wage can't be negative."
            case .negativePaidHours: return "Paid hours can't be negative."
            case .negativeBurden: return "Burden can't be negative."
            case .nonPositiveBillableHours: return "Billable hours per year must be at least 1. Fix it in Settings."
            }
        }
        if let e = error as? EquipmentCalcError {
            switch e {
            case .nonPositivePrice: return "Enter the purchase price."
            case .negativeSalvage: return "Salvage value can't be negative."
            case .salvageNotBelowPrice: return "Salvage value must be below the purchase price."
            case .nonPositiveLifeHours: return "Economic life must be more than 0 hours."
            case .nonPositiveAnnualHours: return "Annual use must be more than 0 hours."
            case .negativeFuelOil: return "Fuel + oil can't be negative."
            case .negativeRepairFactor: return "The repair factor can't be negative."
            case .negativeInsurance: return "Insurance + storage can't be negative."
            case .negativeCostOfMoney: return "Cost of money in Settings can't be negative."
            }
        }
        return error.localizedDescription
    }
}

/// Wage → rate per project hour. Save stores the rounded rate and the inputs; Cancel discards (DECISIONS 35).
struct LaborCalcSheet: View {
    let item: BucketItem
    @State private var draft: LaborCalcDraft
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    init(item: BucketItem) {
        self.item = item
        _draft = State(initialValue: LaborCalcDraft(saved: item.laborInputs, settings: AppSettings.current()))
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Calculate labor rate").font(.headline)
                Text(item.displayName).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()

            Form {
                Section {
                    LabeledContent("Wage") {
                        HStack {
                            CentsField(label: "Wage", cents: $draft.wageCents).labelsHidden().frame(width: 110)
                            Text("per hour").foregroundStyle(.secondary)
                        }
                    }
                    LabeledContent {
                        HStack {
                            CentsField(label: "Pay per day", cents: Binding(
                                get: { draft.wageCents * 8 },
                                set: { draft.wageCents = Money.cents(Decimal($0) / 8) })).labelsHidden().frame(width: 110)
                            Text("per 8-hour day").foregroundStyle(.secondary)
                        }
                    } label: {
                        Text("Pay per day")
                        Text("The way pay is agreed at hiring; $300/day is a $37.50 wage").foregroundStyle(.secondary)
                    }
                    LabeledContent {
                        HStack {
                            DecimalField(label: "Paid hours per year", value: $draft.paidHours, placeholder: "2080").labelsHidden().frame(width: 110)
                            Text("hours").foregroundStyle(.secondary)
                        }
                    } label: {
                        Text("Paid hours per year")
                        Text("2,080 for a full-time employee").foregroundStyle(.secondary)
                    }
                    LabeledContent {
                        HStack {
                            DecimalField(label: "Burden", value: $draft.burdenPct, placeholder: "30").labelsHidden().frame(width: 110)
                            Text("%").foregroundStyle(.secondary)
                        }
                    } label: {
                        Text("Burden")
                        Text("Payroll tax, workers comp and benefits as a % of wage").foregroundStyle(.secondary)
                    }
                    LabeledContent {
                        Text("\(hoursString(draft.billableHours)) hours")
                    } label: {
                        Text("Billable hours per year")
                        Text("From Settings").foregroundStyle(.secondary)
                    }
                }
                Section("Rate per project hour") {
                    switch draft.result {
                    case .success(let cents):
                        VStack(alignment: .leading, spacing: 4) {
                            Text("= \(Money.format(cents)) per project hour").font(.title2)
                            Text(draft.formula).font(.caption).foregroundStyle(.secondary)
                        }
                    case .failure(let error):
                        Label(CalcMessage.text(for: error), systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.red)
                    }
                }
            }
            .formStyle(.grouped)

            Divider()
            HStack {
                Button("Cancel", role: .cancel) { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Save") { save() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(!canSave)
            }
            .padding()
        }
        .frame(width: 500, height: 470)
    }

    private var canSave: Bool {
        if case .success = draft.result { return true }
        return false
    }

    private func save() {
        guard case .success(let cents) = draft.result else { return }
        item.rateCents = cents
        item.calcInputs = try? JSONEncoder().encode(draft.inputs)
        try? modelContext.save()
        dismiss()
    }
}
