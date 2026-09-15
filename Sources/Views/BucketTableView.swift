import SwiftUI
import SwiftData

/// The rows of one bucket: Name · Rate · Unit · Active (BRIEF §5.5 item 1; DECISIONS 22, 28, 37, 42).
struct BucketTableView: View {
    let bucket: Bucket
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query private var allItems: [BucketItem]
    @AppStorage(AppSettings.Key.billableHoursPerYear) private var billableHoursPerYear = AppSettings.defaults.billableHoursPerYear
    @State private var confirmingDelete = false
    @State private var confirmingArchive = false

    /// Filtered in memory (the enum column does not predicate well) and sorted by `sortOrder`, then name.
    private var rows: [BucketItem] { allItems.rows(in: bucket) }

    private var selectedRow: BucketItem? {
        guard let id = appState.selectedItem else { return nil }
        return rows.first { $0.persistentModelID == id }
    }

    var body: some View {
        @Bindable var appState = appState
        Group {
            if rows.isEmpty {
                ContentUnavailableView {
                    Label("No \(bucket.title.lowercased()) rows yet", systemImage: bucket.symbol)
                } description: {
                    Text(bucket.rowHint)
                } actions: {
                    Button("New Row") { appState.newItem(in: bucket) }
                }
            } else {
                Table(rows, selection: $appState.selectedItem) {
                    TableColumn("Name") { item in
                        Text(item.name.isEmpty ? "Untitled" : item.name)
                            .foregroundStyle(item.isActive && !item.name.isEmpty ? Color.primary : Color.secondary)
                    }
                    .width(min: 100, ideal: 150)
                    TableColumn("Rate") { item in
                        RateCell(item: item, billableHours: Decimal(billableHoursPerYear))
                    }
                    .width(min: 120, ideal: 170)
                    TableColumn("Unit") { item in
                        Text(item.unit).foregroundStyle(item.isActive ? Color.primary : Color.secondary)
                    }
                    .width(min: 50, ideal: 84)
                    TableColumn("Active") { item in
                        ActiveToggle(item: item)
                    }
                    .width(44)
                }
                .onDeleteCommand { requestRemoval() }
            }
        }
        .navigationTitle(bucket.title)
        .navigationSplitViewColumnWidth(min: 500, ideal: 560)
        .toolbar {
            ToolbarItemGroup {
                Button { appState.newItem(in: bucket) } label: { Label("New Row", systemImage: "plus") }
                    .help("New row (⌘N)")
                removalButton
            }
        }
        .confirmationDialog("Delete “\(selectedRow?.displayName ?? "")”?", isPresented: $confirmingDelete, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                if let row = selectedRow { appState.delete(row) }
            }
        } message: {
            Text("No project uses this row. This can't be undone.")
        }
        .alert("Archive “\(selectedRow?.displayName ?? "")”?", isPresented: $confirmingArchive) {
            Button("Archive") {
                selectedRow?.isActive = false
                try? modelContext.save()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("It is used in \(projectsPhrase(selectedRow?.referenceCount ?? 0)), so it can't be deleted. Archiving hides it from new projects; the projects that already use it keep it.")
        }
        .onChange(of: bucket) { _, _ in appState.selectedItem = nil }
    }

    // MARK: Delete / Archive (DECISIONS 22, 42)

    private enum Removal {
        case delete, archive
        case disabled(String)
    }

    private var removal: Removal {
        guard let row = selectedRow else { return .disabled("Select a row to delete it.") }
        if row.referenceCount == 0 { return .delete }
        if row.isActive { return .archive }
        return .disabled("Used in \(projectsPhrase(row.referenceCount)), so it can't be deleted. It is already archived.")
    }

    @ViewBuilder private var removalButton: some View {
        switch removal {
        case .delete:
            Button(role: .destructive) { requestRemoval() } label: { Label("Delete", systemImage: "trash") }
                .help("Delete this row (no project uses it)")
        case .archive:
            Button { requestRemoval() } label: { Label("Archive", systemImage: "archivebox") }
                .help("Archive this row (a project uses it, so it can't be deleted)")
        case .disabled(let why):
            Button { } label: { Label("Delete", systemImage: "trash") }
                .disabled(true)
                .help(why)
        }
    }

    private func requestRemoval() {
        switch removal {
        case .delete: confirmingDelete = true
        case .archive: confirmingArchive = true
        case .disabled: break
        }
    }
}

/// "$54.08/hr", "$85.00 each"; overhead adds the derived $/hr as secondary text (DECISIONS 37).
private struct RateCell: View {
    let item: BucketItem
    let billableHours: Decimal

    var body: some View {
        HStack(spacing: 6) {
            Text(item.rateLabel)
                .foregroundStyle(item.isActive ? Color.primary : Color.secondary)
            if item.bucket.isAnnual, let hourly = item.hourlyRateCents(billableHours: billableHours) {
                Text("= \(Money.format(hourly))/hr")
                    .foregroundStyle(.secondary)
            }
        }
        .monospacedDigit()
    }
}

/// The `isActive` checkbox; archived rows stay listed so they can be restored (DECISIONS 37).
private struct ActiveToggle: View {
    @Bindable var item: BucketItem
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        Toggle("Active", isOn: $item.isActive)
            .labelsHidden()
            .help("Archived rows stay on the projects that use them and are hidden from new projects.")
            .onChange(of: item.isActive) { _, _ in try? modelContext.save() }
    }
}

extension Array where Element == BucketItem {
    /// The rows of `bucket` in table order: `sortOrder`, then name (DECISIONS 28).
    func rows(in bucket: Bucket) -> [BucketItem] {
        filter { $0.bucket == bucket }.sorted { a, b in
            if a.sortOrder != b.sortOrder { return a.sortOrder < b.sortOrder }
            return a.name.localizedStandardCompare(b.name) == .orderedAscending
        }
    }
}

extension BucketItem {
    var displayName: String { name.isEmpty ? "Untitled" : name }

    /// The stored figure as currency with its unit: "$54.08/hr", "$6,000.00/yr", "$85.00 each", "$75.00/load".
    var rateLabel: String {
        let money = Money.format(rateCents)
        if unit.isEmpty { return money }
        return unit == "each" ? "\(money) each" : "\(money)/\(unit)"
    }
}

extension Bucket {
    /// What belongs in this bucket (BRIEF §2), shown when it has no rows.
    var rowHint: String {
        switch self {
        case .labor: "One row per employee, with their rate per project hour."
        case .equipment: "Anything you own worth $1,000 or more that goes to a jobsite."
        case .materials: "Installed and left on the customer's property, priced per unit."
        case .consumables: "Used up on the job: disposal by the load, subs flat all-in, treatments, permits."
        case .overhead: "One annual cost per row: insurance, rent, phones, software, licenses."
        }
    }
}

/// "1 project" / "3 projects".
func projectsPhrase(_ count: Int) -> String {
    count == 1 ? "1 project" : "\(count) projects"
}
