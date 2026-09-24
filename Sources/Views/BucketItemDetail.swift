import SwiftUI
import SwiftData

/// The Form for the selected row (BRIEF §5.5 item 1; DECISIONS 25, 26, 27, 34).
struct BucketItemDetail: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        if let item = selectedItem {
            ItemForm(item: item)
                .id(item.persistentModelID)
        } else {
            ContentUnavailableView("No row selected", systemImage: "square.dashed",
                                   description: Text("Pick a row, or press ⌘N to add one."))
        }
    }

    /// The selected row, only while it belongs to the bucket the sidebar shows.
    private var selectedItem: BucketItem? {
        guard let id = appState.selectedItem, let item = modelContext.model(for: id) as? BucketItem,
              !item.isDeleted, item.bucket == appState.selectedBucket else { return nil }
        return item
    }
}

private struct ItemForm: View {
    @Bindable var item: BucketItem
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @AppStorage(AppSettings.Key.billableHoursPerYear) private var billableHoursPerYear = AppSettings.defaults.billableHoursPerYear
    @State private var showingCalc = false
    @FocusState private var nameFocused: Bool

    private var hasCalcSheet: Bool { item.bucket == .labor || item.bucket == .equipment }

    var body: some View {
        Form {
            Section {
                TextField("Name", text: $item.name, prompt: Text(item.bucket.namePrompt))
                    .focused($nameFocused)
                rateRow
                unitRow
                TextField("Category", text: Binding(get: { item.category ?? "" }, set: { item.category = $0.isEmpty ? nil : $0 }),
                          prompt: Text(item.bucket.categoryHint))
                LabeledContent {
                    HStack {
                        OptionalTextField(label: "Link", value: $item.link, prompt: "https://…").labelsHidden()
                        if let url = item.productURL {
                            Link(destination: url) { Label("Open", systemImage: "arrow.up.right.square") }
                                .help("Open the product page")
                        }
                    }
                } label: {
                    Text("Link")
                    Text("Product or supplier page").foregroundStyle(.secondary)
                }
            }
            if item.bucket == .equipment {
                Section {
                    LabeledContent {
                        HStack {
                            OptionalTextField(label: "Unit code", value: $item.unitCode, prompt: suggestedCode).labelsHidden().frame(width: 110)
                            if item.unitCode?.isEmpty ?? true {
                                Button("Use \(suggestedCode)") { item.unitCode = suggestedCode }
                            }
                        }
                    } label: {
                        Text("Unit code")
                        Text("The short name the crew uses; shown before the name everywhere").foregroundStyle(.secondary)
                    }
                    OptionalTextField(label: "Make", value: $item.make, prompt: "STIHL, Ford, Toro…")
                    OptionalTextField(label: "Model", value: $item.model, prompt: "MS 500i, F-250, TX 427…")
                    LabeledContent("Year") {
                        TextField("Year", value: $item.year, format: .number.grouping(.never), prompt: Text("2019"))
                            .labelsHidden().frame(width: 80).multilineTextAlignment(.trailing)
                    }
                    OptionalTextField(label: "Serial / VIN", value: $item.serial, prompt: "Tells two identical units apart")
                } header: {
                    Text("Identification")
                }
            }
            ReviewFields(item: item)
            Section {
                Toggle("Active", isOn: $item.isActive)
                    .help("Archived rows stay on the projects that use them and are hidden from new projects.")
                if item.bucket.rowKind == .quantity {
                    OptionalTextField(label: "Source", value: $item.source, prompt: "Vendor, supplier or sub")
                }
                OptionalTextField(label: "Notes", value: $item.notes,
                                  prompt: item.bucket == .equipment ? "Plate, hour meter, attachments, where it lives…" : "Optional",
                                  axis: .vertical)
            } footer: {
                Text(usage)
            }
        }
        .formStyle(.grouped)
        .sheet(isPresented: $showingCalc) { calcSheet }
        .onAppear { if item.name.isEmpty { nameFocused = true } }
        .task {
            // Screenshot hook: BUCKETS_SCREEN=laborcalc|equipmentcalc opens the sheet for the selected row.
            guard appState.wantsCalcSheet, hasCalcSheet else { return }
            appState.wantsCalcSheet = false
            try? await Task.sleep(for: .milliseconds(400))
            showingCalc = true
        }
        .onChange(of: item.name) { _, _ in save() }
        .onChange(of: item.rateCents) { _, _ in save() }
        .onChange(of: item.unit) { _, _ in save() }
        .onChange(of: item.isActive) { _, _ in save() }
        .onChange(of: item.source) { _, _ in save() }
        .onChange(of: item.notes) { _, _ in save() }
        .onChange(of: item.category) { _, _ in save() }
        .onChange(of: item.link) { _, _ in save() }
        .onChange(of: item.unitCode) { _, _ in save() }
        .onChange(of: item.make) { _, _ in save() }
        .onChange(of: item.model) { _, _ in save() }
        .onChange(of: item.year) { _, _ in save() }
        .onChange(of: item.serial) { _, _ in save() }
    }

    /// "SAW-03": the next free code for this row's category (DECISIONS 66).
    private var suggestedCode: String {
        let all = (try? modelContext.fetch(FetchDescriptor<BucketItem>())) ?? []
        return BucketItem.nextUnitCode(prefix: BucketItem.unitCodePrefix(for: item.category), among: all)
    }

    // MARK: Rows

    @ViewBuilder private var rateRow: some View {
        switch item.bucket {
        case .labor, .equipment:
            LabeledContent("Rate per hour") {
                HStack {
                    CentsField(label: "Rate per hour", cents: $item.rateCents)
                        .labelsHidden()
                        .frame(width: 100)
                    Text("/hr").foregroundStyle(.secondary)
                    Button("Calculate…") { showingCalc = true }
                        .help(item.bucket == .labor ? "Work the rate out from wage, paid hours and burden"
                                                    : "Work the rate out from the seven equipment inputs")
                }
            }
        case .overhead:
            LabeledContent {
                HStack {
                    CentsField(label: "Cost per year", cents: $item.rateCents)
                        .labelsHidden()
                        .frame(width: 120)
                    Text("/yr").foregroundStyle(.secondary)
                }
            } label: {
                Text("Cost per year")
                Text(overheadCaption).foregroundStyle(.secondary)
            }
        case .materials, .consumables, .subcontractors:
            LabeledContent("Unit cost") {
                HStack {
                    CentsField(label: "Unit cost", cents: $item.rateCents)
                        .labelsHidden()
                        .frame(width: 120)
                    if !item.unit.isEmpty {
                        Text(item.unit == "each" ? "each" : "per \(item.unit)").foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    @ViewBuilder private var unitRow: some View {
        if item.bucket.fixedUnit != nil {
            LabeledContent {
                Text(item.unit)
            } label: {
                Text("Unit")
                Text(item.bucket.isAnnual ? "Per year; priced per project hour" : "Per project hour").foregroundStyle(.secondary)
            }
        } else {
            TextField("Unit", text: $item.unit, prompt: Text("each, load, day, stump, application, roll, yard"))
        }
    }

    /// DECISIONS 34: "= $4.00 per hour at 1,500 billable hours".
    private var overheadCaption: String {
        let hourly = item.hourlyRateCents(billableHours: Decimal(billableHoursPerYear)) ?? 0
        return "= \(Money.format(hourly)) per hour at \(hoursString(Decimal(billableHoursPerYear))) billable hours"
    }

    private var usage: String {
        switch item.referenceCount {
        case 0: "Not used in any project yet, so it can be deleted."
        default: "Used in \(projectsPhrase(item.referenceCount)). It can be archived, not deleted."
        }
    }

    @ViewBuilder private var calcSheet: some View {
        switch item.bucket {
        case .labor: LaborCalcSheet(item: item)
        case .equipment: EquipmentCalcSheet(item: item)
        default: EmptyView()
        }
    }

    private func save() {
        try? modelContext.save()
    }
}

/// The review section of a row's Form (DECISIONS 72): confidence, evidence, the two dates, who approved, the
/// owner-confirmation flag and the assumption note. Shared by the bucket detail and the subcontractor service sheet.
/// "Verified" is offered only once the row has evidence and a checked date; picking it goes through `markVerified`.
struct ReviewFields: View {
    @Bindable var item: BucketItem
    @Environment(\.modelContext) private var modelContext

    private var choices: [Confidence] {
        Confidence.allCases.filter { $0 != .verified || item.canMarkVerified || item.confidence == .verified }
    }

    private var confidence: Binding<Confidence> {
        Binding(get: { item.confidence }, set: { new in
            switch new {
            case .verified: item.markVerified()
            case .ownerConfirmed: item.markOwnerConfirmed()
            default: item.confidence = new
            }
        })
    }

    var body: some View {
        Section {
            LabeledContent {
                Picker("Confidence", selection: confidence) {
                    ForEach(choices, id: \.self) { Text($0.title).tag($0) }
                }
                .labelsHidden().fixedSize()
            } label: {
                Text("Confidence")
                if item.confidence != .verified && !item.canMarkVerified {
                    Text("Verified needs a source, evidence or link, and a checked date").foregroundStyle(.secondary)
                }
            }
            OptionalTextField(label: "Evidence", value: $item.evidence,
                              prompt: "Quote, invoice, price list, web page, who said so…", axis: .vertical)
            LabeledContent("Checked") {
                HStack {
                    OptionalDatePicker(label: "Checked", date: $item.checkedAt, setTitle: "Set date…", makeDefault: { .now })
                    Button("Today") { item.markChecked() }
                        .help("Checked today; the review comes due in a year unless a date is already set")
                }
            }
            LabeledContent {
                OptionalDatePicker(label: "Review due", date: $item.reviewDueAt, setTitle: "Set date…")
            } label: {
                Text("Review due")
                if item.isOverdue() { Text("Overdue").foregroundStyle(.red) }
            }
            OptionalTextField(label: "Approved by", value: $item.approvedBy, prompt: "Who signed off")
            Toggle("Needs owner confirmation", isOn: $item.needsOwnerConfirmation)
                .help("Ask the owner to look at this figure before it is trusted; clears when they mark it owner confirmed")
            OptionalTextField(label: "Assumption", value: $item.assumption,
                              prompt: "What this figure assumes: crew size, supplier, season…", axis: .vertical)
        } header: {
            Text("Review")
        } footer: {
            Text(item.reviewLabel())
        }
        .onChange(of: item.confidenceRaw) { _, _ in save() }
        .onChange(of: item.evidence) { _, _ in save() }
        .onChange(of: item.checkedAt) { _, _ in save() }
        .onChange(of: item.reviewDueAt) { _, _ in save() }
        .onChange(of: item.approvedBy) { _, _ in save() }
        .onChange(of: item.needsOwnerConfirmation) { _, _ in save() }
        .onChange(of: item.assumption) { _, _ in save() }
    }

    private func save() {
        try? modelContext.save()
    }
}

extension Bucket {
    var namePrompt: String {
        switch self {
        case .labor: "Employee name"
        case .equipment: "Unit name"
        case .materials: "Item name"
        case .consumables: "Item name"
        case .subcontractors: "Service name"
        case .overhead: "Cost name"
        }
    }
}
