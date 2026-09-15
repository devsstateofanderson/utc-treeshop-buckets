import SwiftUI
import SwiftData

/// The Equipment "Calculate…" sheet's seven inputs plus the cost-of-money percent in force (BRIEF §2.2;
/// DECISIONS 13, 36). Plain data so it is testable.
struct EquipmentCalcDraft: Equatable {
    var priceCents: Int
    var salvageCents: Int
    var lifeHours: Decimal
    var annualHours: Decimal
    var fuelOilPerHourCents: Int
    var repairFactor: Decimal
    var insurancePerYearCents: Int
    /// Whole percent, always the live Settings value (shown read-only); stored with the inputs on Save.
    var costOfMoneyPct: Decimal

    init(saved: EquipmentCalcInputs?, settings: AppSettings) {
        priceCents = saved?.priceCents ?? 0
        salvageCents = saved?.salvageCents ?? 0
        lifeHours = saved?.lifeHours ?? 8000
        annualHours = saved?.annualHours ?? settings.billableHours
        fuelOilPerHourCents = saved?.fuelOilPerHourCents ?? 0
        repairFactor = saved?.repairFactor ?? Decimal(string: "0.80")!
        insurancePerYearCents = saved?.insurancePerYearCents ?? 0
        costOfMoneyPct = settings.costOfMoneyPctDecimal
    }

    var inputs: EquipmentCalcInputs {
        EquipmentCalcInputs(priceCents: priceCents, salvageCents: salvageCents, lifeHours: lifeHours, annualHours: annualHours,
                            fuelOilPerHourCents: fuelOilPerHourCents, repairFactor: repairFactor,
                            insurancePerYearCents: insurancePerYearCents, costOfMoneyPct: costOfMoneyPct)
    }

    /// The five components and the total, or the typed error. Cost of money enters as the exact fraction pct ÷ 100.
    var result: Result<EquipmentRate, any Error> {
        Result {
            try EquipmentCalc.rate(price: priceCents, salvage: salvageCents, lifeHours: lifeHours, annualHours: annualHours,
                                   fuelOilPerHour: fuelOilPerHourCents, repairFactor: repairFactor,
                                   insurancePerYear: insurancePerYearCents, costOfMoney: costOfMoneyPct / 100)
        }
    }

    /// A component in dollars, rounded once for display: 6.25 → "$6.25".
    static func dollars(_ amount: Decimal) -> String {
        Money.format(Money.cents(amount * 100))
    }
}

/// The 7 inputs → rate per hour, with the BRIEF §2.2 ranges as static help. Save stores the rate and the inputs (DECISIONS 36).
struct EquipmentCalcSheet: View {
    let item: BucketItem
    @State private var draft: EquipmentCalcDraft
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    init(item: BucketItem) {
        self.item = item
        _draft = State(initialValue: EquipmentCalcDraft(saved: item.equipmentInputs, settings: AppSettings.current()))
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Calculate equipment rate").font(.headline)
                Text(item.displayName).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()

            HStack(spacing: 0) {
                Form {
                    Section("Purchase") {
                        money("Purchase price", "Delivered", cents: $draft.priceCents, suffix: "")
                        money("Salvage value", "What it sells for at the end of its life", cents: $draft.salvageCents, suffix: "")
                        hours("Economic life", "Saws 2,000 · chipper 8,000 · truck 8,000–12,000 · skid steer 7,500",
                              value: $draft.lifeHours, placeholder: "8000")
                        hours("Annual use", "Billable hours from Settings, unless this unit runs fewer",
                              value: $draft.annualHours, placeholder: hoursString(AppSettings.current().billableHours))
                    }
                    Section("Operating") {
                        money("Fuel + oil", "Per hour of use; fuel is never a consumable", cents: $draft.fuelOilPerHourCents, suffix: "per hour")
                        LabeledContent {
                            DecimalField(label: "Repair factor", value: $draft.repairFactor, placeholder: "0.80").labelsHidden().frame(width: 110)
                        } label: {
                            Text("Repair factor")
                            Text("Trucks 0.65–0.75 · chipper 0.90 · skid steer 0.80 · chainsaw 2.50 · trailer 0.50")
                                .foregroundStyle(.secondary)
                        }
                        money("Insurance + storage", "Per year, for this unit", cents: $draft.insurancePerYearCents, suffix: "per year")
                        LabeledContent {
                            Text(percentString(draft.costOfMoneyPct))
                        } label: {
                            Text("Cost of money")
                            Text("From Settings; 0% if bought with cash").foregroundStyle(.secondary)
                        }
                    }
                }
                .formStyle(.grouped)

                Divider()

                Form {
                    Section("Rate per hour") {
                        switch draft.result {
                        case .success(let rate):
                            component("Depreciation", "(Price − salvage) ÷ life hours", rate.depreciation)
                            component("Cost of money", "Price × AVF × rate ÷ annual hours", rate.costOfMoney)
                            component("Insurance + storage", "Per year ÷ annual hours", rate.insurance)
                            component("Fuel + oil", "As entered", rate.fuelOil)
                            component("Repairs", "Price × repair factor ÷ life hours", rate.repairs)
                            LabeledContent {
                                Text(Money.format(rate.rateCents)).font(.title2)
                            } label: {
                                Text("Total").font(.headline)
                                Text("Stored on the row when you save").foregroundStyle(.secondary)
                            }
                        case .failure(let error):
                            Label(CalcMessage.text(for: error), systemImage: "exclamationmark.triangle")
                                .foregroundStyle(.red)
                        }
                    }
                }
                .formStyle(.grouped)
                .frame(width: 330)
            }
            .monospacedDigit()

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
        .frame(width: 940, height: 700)
    }

    private func component(_ title: String, _ formula: String, _ amount: Decimal) -> some View {
        LabeledContent {
            Text(EquipmentCalcDraft.dollars(amount))
        } label: {
            Text(title)
            Text(formula).foregroundStyle(.secondary)
        }
    }

    private func money(_ title: String, _ caption: String, cents: Binding<Int>, suffix: String) -> some View {
        LabeledContent {
            HStack {
                CentsField(label: title, cents: cents).labelsHidden().frame(width: 110)
                if !suffix.isEmpty { Text(suffix).foregroundStyle(.secondary) }
            }
        } label: {
            Text(title)
            Text(caption).foregroundStyle(.secondary)
        }
    }

    private func hours(_ title: String, _ caption: String, value: Binding<Decimal>, placeholder: String) -> some View {
        LabeledContent {
            HStack {
                DecimalField(label: title, value: value, placeholder: placeholder).labelsHidden().frame(width: 110)
                Text("hours").foregroundStyle(.secondary)
            }
        } label: {
            Text(title)
            Text(caption).foregroundStyle(.secondary)
        }
    }

    private var canSave: Bool {
        if case .success = draft.result { return true }
        return false
    }

    private func save() {
        guard case .success(let rate) = draft.result else { return }
        item.rateCents = rate.rateCents
        item.calcInputs = try? JSONEncoder().encode(draft.inputs)
        try? modelContext.save()
        dismiss()
    }
}
