import SwiftUI
import SwiftData

/// The Overhead "Calculate…" sheet's inputs and live result (DECISIONS 93, amending 34 for a salary line). Plain data so
/// it is testable.
struct SalaryCalcDraft: Equatable {
    var amountCents: Int
    var period: SalaryPeriod
    /// Used by a day rate only; kept whatever the period.
    var daysPerWeek: Decimal
    /// Used by a day or a week rate; kept whatever the period.
    var weeksPerYear: Decimal
    /// Whole percent (30), editable per row; the default comes from Settings, as the Labor sheet's (DECISIONS 35).
    var burdenPct: Decimal
    /// Read-only, from Settings; divides the $/yr into the $/hr shown (display only, DECISIONS 4).
    var billableHours: Decimal

    init(saved: SalaryCalcInputs?, settings: AppSettings) {
        amountCents = saved?.amountCents ?? 0
        period = saved?.period ?? .year
        daysPerWeek = saved?.daysPerWeek ?? 5
        weeksPerYear = saved?.weeksPerYear ?? 52
        burdenPct = saved?.burdenPct ?? settings.laborBurdenPctDecimal
        billableHours = settings.billableHours
    }

    var inputs: SalaryCalcInputs {
        SalaryCalcInputs(amountCents: amountCents, period: period, daysPerWeek: daysPerWeek, weeksPerYear: weeksPerYear,
                         burdenPct: burdenPct)
    }

    /// $/yr in cents, or the typed error.
    var result: Result<Int, any Error> {
        Result { try SalaryCalc.annualCents(inputs) }
    }

    /// The $/hr a project sees, `$/yr ÷ billable hours` rounded once for display (DECISIONS 4); nil without billable hours.
    func hourlyCents(annualCents: Int) -> Int? {
        guard billableHours > 0 else { return nil }
        return Money.cents(Decimal(annualCents) / billableHours)
    }

    /// "= $67,600.00 per year · $45.07 per hour at 1,500 billable hours"
    func summary(annualCents: Int) -> String {
        let year = "= \(Money.format(annualCents)) per year"
        guard let hourly = hourlyCents(annualCents: annualCents) else { return year }
        return "\(year) · \(Money.format(hourly)) per hour at \(hoursString(billableHours)) billable hours"
    }

    /// "$200.00 × 5 × 52 × 1.30" for a day rate, "$1,000.00 × 52 × 1.30" for a week, "$52,000.00 × 1.30" for a year.
    var formula: String {
        let factor = (1 + burdenPct / 100).formatted(.number.precision(.fractionLength(2...4)).locale(Locale(identifier: "en_US")))
        let counts: [String] = switch period {
        case .day: [hoursString(daysPerWeek), hoursString(weeksPerYear)]
        case .week: [hoursString(weeksPerYear)]
        case .year: []
        default: [hoursString(period.periodsPerYear(daysPerWeek: daysPerWeek, weeksPerYear: weeksPerYear))]
        }
        return ([Money.format(amountCents)] + counts + [factor]).joined(separator: " × ")
    }

    /// Save: the rounded $/yr into `rateCents` and the inputs into `calcInputs`. Refused (false, nothing changed) while
    /// the inputs are in error or the row is not an Overhead line.
    @discardableResult
    func save(into item: BucketItem) -> Bool {
        guard item.bucket == .overhead, case .success(let cents) = result,
              let data = try? JSONEncoder().encode(inputs) else { return false }
        item.rateCents = cents
        item.calcInputs = data
        return true
    }
}

/// A salary → cost per year for an Overhead line. Save stores the rounded $/yr and the inputs; Cancel discards
/// (DECISIONS 93). Every other overhead line is typed as its $/yr and never opens this.
struct SalaryCalcSheet: View {
    let item: BucketItem
    @State private var draft: SalaryCalcDraft
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    init(item: BucketItem) {
        self.item = item
        _draft = State(initialValue: SalaryCalcDraft(saved: item.salaryInputs, settings: AppSettings.current()))
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Calculate salary").font(.headline)
                Text(item.displayName).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()

            Form {
                Section {
                    LabeledContent {
                        HStack {
                            CentsField(label: "Pay", cents: $draft.amountCents).labelsHidden().frame(width: 110)
                            Picker("Paid", selection: $draft.period) {
                                ForEach(SalaryPeriod.allCases, id: \.self) { Text($0.title).tag($0) }
                            }
                            .labelsHidden()
                            .fixedSize()
                        }
                    } label: {
                        Text("Pay")
                        Text("As agreed at hiring, and how often").foregroundStyle(.secondary)
                    }
                    if draft.period.usesDaysPerWeek {
                        LabeledContent {
                            HStack {
                                DecimalField(label: "Days per week", value: $draft.daysPerWeek, placeholder: "5", maximum: 7)
                                    .labelsHidden().frame(width: 110)
                                Text("days").foregroundStyle(.secondary)
                            }
                        } label: {
                            Text("Days per week")
                            Text("5 for a weekday schedule").foregroundStyle(.secondary)
                        }
                    }
                    if draft.period.usesWeeksPerYear {
                        LabeledContent {
                            HStack {
                                DecimalField(label: "Weeks per year", value: $draft.weeksPerYear, placeholder: "52", maximum: 53)
                                    .labelsHidden().frame(width: 110)
                                Text("weeks").foregroundStyle(.secondary)
                            }
                        } label: {
                            Text("Weeks per year")
                            Text("52 when paid time off is paid").foregroundStyle(.secondary)
                        }
                    }
                    LabeledContent {
                        HStack {
                            DecimalField(label: "Burden", value: $draft.burdenPct, placeholder: "30").labelsHidden().frame(width: 110)
                            Text("%").foregroundStyle(.secondary)
                        }
                    } label: {
                        Text("Burden")
                        Text("Payroll tax, workers comp and benefits as a % of pay").foregroundStyle(.secondary)
                    }
                    LabeledContent {
                        Text("\(hoursString(draft.billableHours)) hours")
                    } label: {
                        Text("Billable hours per year")
                        Text("From Settings").foregroundStyle(.secondary)
                    }
                }
                Section("Cost per year") {
                    switch draft.result {
                    case .success(let cents):
                        VStack(alignment: .leading, spacing: 4) {
                            Text(draft.summary(annualCents: cents)).font(.title3)
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
        .frame(width: 520, height: 560)
    }

    private var canSave: Bool {
        if case .success = draft.result { return true }
        return false
    }

    private func save() {
        guard draft.save(into: item) else { return }
        try? modelContext.save()
        dismiss()
    }
}
