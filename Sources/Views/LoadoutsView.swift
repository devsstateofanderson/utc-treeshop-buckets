import SwiftUI
import SwiftData

/// Crew formations (DECISIONS 62): Name · Crew rate · Rows.
struct LoadoutsListView: View {
    @Environment(AppState.self) private var appState
    @Query(sort: [SortDescriptor(\Loadout.sortOrder), SortDescriptor(\Loadout.name)]) private var loadouts: [Loadout]
    @State private var confirmingDelete = false

    private var selected: Loadout? { appState.selectedLoadoutModel }

    var body: some View {
        @Bindable var appState = appState
        Group {
            if loadouts.isEmpty {
                ContentUnavailableView {
                    Label("No loadouts yet", systemImage: "person.3")
                } description: {
                    Text("A loadout is a crew: the people and the equipment that go out together. Apply one to a project from the Crew menu in its header.")
                } actions: {
                    Button("New Loadout") { appState.newLoadout() }
                }
            } else {
                Table(loadouts, selection: $appState.selectedLoadout) {
                    TableColumn("Name") { loadout in
                        Text(loadout.displayName).foregroundStyle(loadout.name.isEmpty ? Color.secondary : Color.primary)
                    }
                    .width(min: 140, ideal: 200)
                    TableColumn("Crew rate") { loadout in
                        Text(Money.format(loadout.hourlyRateCents) + "/hr").monospacedDigit()
                    }
                    .width(min: 100, ideal: 120)
                    .alignment(.trailing)
                    TableColumn("Rows") { loadout in
                        Text("\(loadout.members.count)").monospacedDigit()
                    }
                    .width(50)
                    .alignment(.trailing)
                }
                .onDeleteCommand { if selected != nil { confirmingDelete = true } }
            }
        }
        .navigationTitle("Loadouts")
        .navigationSplitViewColumnWidth(min: 400, ideal: 460)
        .toolbar {
            ToolbarItemGroup {
                Button { appState.newLoadout() } label: { Label("New Loadout", systemImage: "plus") }
                    .help("New loadout (⌘N)")
                Button { if let l = selected { appState.duplicate(l) } } label: { Label("Duplicate", systemImage: "plus.square.on.square") }
                    .disabled(selected == nil)
                    .help("Copy this crew (⌘D)")
                Button(role: .destructive) { confirmingDelete = true } label: { Label("Delete", systemImage: "trash") }
                    .disabled(selected == nil)
            }
        }
        .confirmationDialog("Delete “\(selected?.displayName ?? "")”?", isPresented: $confirmingDelete, titleVisibility: .visible) {
            Button("Delete", role: .destructive) { if let l = selected { appState.delete(l) } }
        } message: {
            Text("Projects that used this crew keep their toggles; only the saved formation goes away.")
        }
    }
}

struct LoadoutDetail: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        if let loadout = appState.selectedLoadoutModel {
            LoadoutForm(loadout: loadout).id(loadout.persistentModelID)
        } else {
            ContentUnavailableView("No loadout selected", systemImage: "square.dashed",
                                   description: Text("Pick a loadout, or press ⌘N to add one."))
        }
    }
}

/// Name, notes, then every active labor and equipment row with a membership toggle, grouped by category.
private struct LoadoutForm: View {
    @Bindable var loadout: Loadout
    @Environment(\.modelContext) private var modelContext
    @Query private var allItems: [BucketItem]
    @FocusState private var nameFocused: Bool

    var body: some View {
        Form {
            Section {
                TextField("Name", text: $loadout.name, prompt: Text("Crew A, Bucket truck crew, Two-man prune…"))
                    .focused($nameFocused)
                OptionalTextField(label: "Notes", value: $loadout.notes, prompt: "Optional", axis: .vertical)
                LabeledContent("Crew rate") {
                    Text(Money.format(loadout.hourlyRateCents) + " per project hour").monospacedDigit()
                }
            }
            LoadoutBucketSection(loadout: loadout, bucket: .labor, items: allItems.rows(in: .labor))
            LoadoutBucketSection(loadout: loadout, bucket: .equipment, items: allItems.rows(in: .equipment))
        }
        .formStyle(.grouped)
        .onAppear { if loadout.name.isEmpty { nameFocused = true } }
        .onChange(of: loadout.name) { _, _ in try? modelContext.save() }
        .onChange(of: loadout.notes) { _, _ in try? modelContext.save() }
    }
}

/// One bucket's rows with membership toggles, grouped by category.
private struct LoadoutBucketSection: View {
    @Bindable var loadout: Loadout
    let bucket: Bucket
    let items: [BucketItem]
    @Environment(\.modelContext) private var modelContext

    private var rows: [BucketItem] { items.filter { $0.isActive || loadout.contains($0) } }

    private var groups: [(title: String, rows: [BucketItem])] {
        let keyed = Dictionary(grouping: rows) { $0.categoryText }
        let keys = keyed.keys.sorted { a, b in
            if a.isEmpty != b.isEmpty { return b.isEmpty }
            return a.localizedStandardCompare(b) == .orderedAscending
        }
        return keys.map { (title: $0.isEmpty ? "Other" : $0, rows: keyed[$0] ?? []) }
    }

    var body: some View {
        Section(bucket.title) {
            if rows.isEmpty {
                Text("No \(bucket.title.lowercased()) rows yet. Add them on the \(bucket.title) screen.")
                    .foregroundStyle(.secondary)
            }
            ForEach(groups, id: \.title) { group in
                if groups.count > 1 {
                    Text(group.title).font(.caption).foregroundStyle(.secondary)
                }
                ForEach(group.rows) { item in
                    MemberToggle(loadout: loadout, item: item)
                }
            }
        }
    }
}

private struct MemberToggle: View {
    @Bindable var loadout: Loadout
    let item: BucketItem
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        Toggle(isOn: Binding(get: { loadout.contains(item) }, set: { on in loadout.setMember(item, on); try? modelContext.save() })) {
            HStack {
                Text(item.name.isEmpty ? "Untitled" : item.name)
                Spacer()
                Text(Money.format(item.rateCents) + "/hr").foregroundStyle(.secondary).monospacedDigit()
            }
        }
        .toggleStyle(.checkbox)
    }
}
