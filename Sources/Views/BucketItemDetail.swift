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
            }
            Section {
                Toggle("Active", isOn: $item.isActive)
                    .help("Archived rows stay on the projects that use them and are hidden from new projects.")
                if item.bucket.rowKind == .quantity {
                    OptionalTextField(label: "Source", value: $item.source, prompt: "Vendor, supplier or sub")
                }
                OptionalTextField(label: "Notes", value: $item.notes,
                                  prompt: item.bucket == .equipment ? "Unit number, serial number, plate, year…" : "Optional",
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
        case .materials, .consumables:
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

extension Bucket {
    var namePrompt: String {
        switch self {
        case .labor: "Employee name"
        case .equipment: "Unit name"
        case .materials: "Item name"
        case .consumables: "Item or subcontractor"
        case .overhead: "Cost name"
        }
    }
}
