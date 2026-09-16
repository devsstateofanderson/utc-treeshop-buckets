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
    @State private var search = ""
    @State private var sortOrder: [KeyPathComparator<BucketItem>] = []

    /// Filtered in memory (the enum column does not predicate well), searched, then sorted by the clicked
    /// column; with no column clicked, quantity buckets sort by category then name, the rest by `sortOrder`.
    private var rows: [BucketItem] {
        var result = allItems.rows(in: bucket)
        if !search.isEmpty { result = result.filter { $0.matches(search) } }
        if !sortOrder.isEmpty {
            result.sort(using: sortOrder)
        } else if bucket.rowKind == .quantity {
            result.sort { ($0.categoryText, $0.name) < ($1.categoryText, $1.name) }
        }
        return result
    }

    private var selectedRow: BucketItem? {
        guard let id = appState.selectedItem else { return nil }
        return rows.first { $0.persistentModelID == id }
    }

    var body: some View {
        @Bindable var appState = appState
        Group {
            if rows.isEmpty && !search.isEmpty {
                ContentUnavailableView.search(text: search)
            } else if rows.isEmpty {
                ContentUnavailableView {
                    Label("No \(bucket.title.lowercased()) rows yet", systemImage: bucket.symbol)
                } description: {
                    Text(bucket.rowHint)
                } actions: {
                    Button("New Row") { appState.newItem(in: bucket) }
                }
            } else {
                Table(rows, selection: $appState.selectedItem, sortOrder: $sortOrder) {
                    TableColumn("Category", value: \.categoryText) { item in
                        Text(item.categoryText).foregroundStyle(.secondary)
                    }
                    .width(min: 80, ideal: 120)
                    TableColumn("Name", value: \.name) { item in
                        Text(item.name.isEmpty ? "Untitled" : item.name)
                            .foregroundStyle(item.isActive && !item.name.isEmpty ? Color.primary : Color.secondary)
                    }
                    .width(min: 100, ideal: 170)
                    TableColumn("Rate", value: \.rateCents) { item in
                        RateCell(item: item, billableHours: Decimal(billableHoursPerYear))
                    }
                    .width(min: 120, ideal: 170)
                    TableColumn("Unit", value: \.unit) { item in
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
        .navigationSplitViewColumnWidth(min: 560, ideal: 640)
        .searchable(text: $search, placement: .toolbar, prompt: "Search \(bucket.title.lowercased())")
        .toolbar {
            ToolbarItemGroup {
                Button { appState.newItem(in: bucket) } label: { Label("New Row", systemImage: "plus") }
                    .help("New row (⌘N)")
                Button { if let row = selectedRow { appState.duplicate(row) } } label: { Label("Duplicate Row", systemImage: "plus.square.on.square") }
                    .help("Copy this row (same rate and calculator inputs) to add another unit")
                    .disabled(selectedRow == nil)
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
    var rateLabel: String { Buckets.rateLabel(cents: rateCents, unit: unit) }
}

extension Bucket {
    /// What belongs in this bucket (BRIEF §2), shown when it has no rows.
    var rowHint: String {
        switch self {
        case .labor: "One row per employee, with their rate per project hour."
        case .equipment: "Anything you own worth $1,000 or more that goes to a jobsite."
        case .materials: "Installed and left on the customer's property, priced per unit."
        case .consumables: "Used up on the job: disposal by the load, subs flat all-in, treatments, permits."
        case .subcontractors: "Each sub keeps its own priced services on the Subcontractors screen."
        case .overhead: "One annual cost per row: insurance, rent, phones, software, licenses."
        }
    }
}

/// "1 project" / "3 projects".
func projectsPhrase(_ count: Int) -> String {
    count == 1 ? "1 project" : "\(count) projects"
}

extension Bucket {
    /// Placeholder for the Category field.
    var categoryHint: String {
        switch self {
        case .labor: "Crew lead, climber, ground…"
        case .equipment: "Chainsaws, Pole saws, Trucks, Trailers, Machines, Rigging…"
        case .materials: "Palms, Trees, Mulch & pine straw, Soil & amendments, Sod, Irrigation…"
        case .consumables: "Chains & bars, Fuel & oil, Batteries & chargers, Disposal, Subcontractors…"
        case .subcontractors: "Stump grinding, Crane, Grapple truck, Hauling…"
        case .overhead: "Insurance, Facilities, Marketing, Software, Taxes & licenses…"
        }
    }
}
