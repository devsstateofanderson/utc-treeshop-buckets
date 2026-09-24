import SwiftUI
import SwiftData

/// The subs (DECISIONS 60): Name · Contact · Services · Active.
struct SubcontractorsListView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\Subcontractor.sortOrder), SortDescriptor(\Subcontractor.name)]) private var subs: [Subcontractor]
    @State private var search = ""
    @State private var confirmingDelete = false
    @State private var confirmingArchive = false

    private var rows: [Subcontractor] {
        search.isEmpty ? subs : subs.filter { s in
            [s.name, s.contact ?? "", s.notes ?? ""].contains { $0.localizedStandardContains(search) }
                || s.services.contains { $0.matches(search) }
        }
    }

    private var selected: Subcontractor? { appState.selectedSubcontractorModel }

    var body: some View {
        @Bindable var appState = appState
        Group {
            if rows.isEmpty && !search.isEmpty {
                ContentUnavailableView.search(text: search)
            } else if rows.isEmpty {
                ContentUnavailableView {
                    Label("No subcontractors yet", systemImage: Bucket.subcontractors.symbol)
                } description: {
                    Text("Each sub gets its own list of priced services: stump grinding per stump, crane per day, grapple truck per load. Flat and all-in, never shown to a customer.")
                } actions: {
                    Button("New Subcontractor") { appState.newSubcontractor() }
                }
            } else {
                Table(rows, selection: $appState.selectedSubcontractor) {
                    TableColumn("Name") { sub in
                        Text(sub.displayName).foregroundStyle(sub.isActive && !sub.name.isEmpty ? Color.primary : Color.secondary)
                    }
                    .width(min: 120, ideal: 180)
                    TableColumn("Contact") { sub in
                        Text([sub.contact, sub.phone].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " · "))
                            .foregroundStyle(.secondary)
                    }
                    .width(min: 120, ideal: 200)
                    TableColumn("Services") { sub in
                        Text("\(sub.services.filter(\.isActive).count)").monospacedDigit()
                    }
                    .width(60)
                    .alignment(.trailing)
                    TableColumn("Active") { sub in
                        Toggle("Active", isOn: Binding(get: { sub.isActive }, set: { sub.setActive($0); try? modelContext.save() }))
                            .labelsHidden()
                    }
                    .width(44)
                }
                .onDeleteCommand { requestRemoval() }
            }
        }
        .navigationTitle("Subcontractors")
        .navigationSplitViewColumnWidth(min: 480, ideal: 560)
        .searchable(text: $search, placement: .toolbar, prompt: "Search subcontractors and services")
        .toolbar {
            ToolbarItemGroup {
                Button { appState.newSubcontractor() } label: { Label("New Subcontractor", systemImage: "plus") }
                    .help("New subcontractor (⌘N)")
                Button(role: .destructive) { requestRemoval() } label: { Label("Delete", systemImage: "trash") }
                    .disabled(selected == nil)
                    .help("Delete the sub and its services when no project uses them; otherwise archive")
            }
        }
        .confirmationDialog("Delete “\(selected?.displayName ?? "")” and its services?", isPresented: $confirmingDelete, titleVisibility: .visible) {
            Button("Delete", role: .destructive) { if let sub = selected { appState.delete(sub) } }
        } message: {
            Text("No project uses this sub's services. This can't be undone.")
        }
        .alert("Archive “\(selected?.displayName ?? "")”?", isPresented: $confirmingArchive) {
            Button("Archive") { selected?.setActive(false); try? modelContext.save() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Projects already use this sub's services, so it can't be deleted. Archiving hides the sub and its services from new projects.")
        }
    }

    private func requestRemoval() {
        guard let sub = selected else { return }
        if sub.referenceCount == 0 { confirmingDelete = true } else { confirmingArchive = true }
    }
}

/// One sub: contact details and its priced services, edited in place.
struct SubcontractorDetail: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        if let sub = appState.selectedSubcontractorModel {
            // No .id(): combined with the name field's auto-focus it left the Form blank on macOS 26 (found by render bisect);
            // the focus is re-evaluated on selection change below instead.
            SubcontractorForm(sub: sub)
        } else {
            ContentUnavailableView("No subcontractor selected", systemImage: "square.dashed",
                                   description: Text("Pick a sub, or press ⌘N to add one."))
        }
    }
}

private struct SubcontractorForm: View {
    @Bindable var sub: Subcontractor
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @FocusState private var nameFocused: Bool

    var body: some View {
        Form {
            Section {
                TextField("Name", text: $sub.name, prompt: Text("Company or person"))
                    .focused($nameFocused)
                OptionalTextField(label: "Contact", value: $sub.contact, prompt: "Who to call")
                OptionalTextField(label: "Phone", value: $sub.phone, prompt: "Optional")
                OptionalTextField(label: "Email", value: $sub.email, prompt: "Optional")
                Toggle("Active", isOn: Binding(get: { sub.isActive }, set: { sub.setActive($0) }))
                    .help("Archived subs keep their services on old projects and are hidden from new ones.")
                OptionalTextField(label: "Notes", value: $sub.notes, prompt: "Insurance on file, lead time, minimums…", axis: .vertical)
            }
            Section {
                let services = sub.sortedServices
                if services.isEmpty {
                    Text("No services yet. Add one per thing this sub charges for, at the price they charge you.")
                        .foregroundStyle(.secondary)
                }
                ForEach(services) { service in
                    ServiceRow(service: service, sub: sub)
                }
                Button { appState.newService(for: sub) } label: { Label("Add Service", systemImage: "plus") }
            } header: {
                Text("Services")
            } footer: {
                Text("Each service prices like a consumable: flat, all-in, per unit, and never appears on customer-facing output (BRIEF §2.5).")
            }
        }
        .formStyle(.grouped)
        .onAppear { if sub.name.isEmpty { nameFocused = true } }
        .onChange(of: sub.persistentModelID) { _, _ in if sub.name.isEmpty { nameFocused = true } }
        .onChange(of: sub.name) { _, _ in save() }
        .onChange(of: sub.contact) { _, _ in save() }
        .onChange(of: sub.phone) { _, _ in save() }
        .onChange(of: sub.email) { _, _ in save() }
        .onChange(of: sub.isActive) { _, _ in save() }
        .onChange(of: sub.notes) { _, _ in save() }
    }

    private func save() { try? modelContext.save() }
}

/// Name · unit cost · per unit · review · delete (or archived marker) — one line per service.
private struct ServiceRow: View {
    @Bindable var service: BucketItem
    let sub: Subcontractor
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @State private var showingReview = false

    var body: some View {
        HStack(spacing: 10) {
            TextField("Service", text: $service.name, prompt: Text("Stump grinding, Crane day, Haul load…"))
                .frame(minWidth: 160)
            CentsField(label: "Unit cost", cents: $service.rateCents)
                .labelsHidden()
                .frame(width: 96)
            Text("per").foregroundStyle(.secondary)
            TextField("Unit", text: $service.unit, prompt: Text("stump, day, load"))
                .frame(width: 96)
            // The review fields live in a sheet here because a service has no detail Form of its own (DECISIONS 72).
            Button { showingReview = true } label: {
                Label(service.reviewLabel(), systemImage: service.reviewSeverity() == .ok ? "checkmark.seal" : "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(service.reviewSeverity().style)
            }
            .buttonStyle(.borderless)
            .help("Review this service's price: evidence, confidence, checked and due dates")
            .sheet(isPresented: $showingReview) {
                NavigationStack {
                    Form { ReviewFields(item: service) }
                        .formStyle(.grouped)
                        .navigationTitle(service.displayName)
                        .toolbar { Button("Done") { showingReview = false } }
                }
                .frame(minWidth: 560, minHeight: 440)
            }
            if service.referenceCount > 0 {
                Toggle("Active", isOn: $service.isActive).labelsHidden()
                    .help("Used in \(service.referenceCount) project(s); archive instead of deleting")
            } else {
                Button(role: .destructive) { appState.delete(service) } label: { Image(systemName: "trash") }
                    .buttonStyle(.borderless)
                    .help("Delete this service")
            }
        }
        .foregroundStyle(service.isActive ? Color.primary : Color.secondary)
        .onChange(of: service.name) { _, _ in save() }
        .onChange(of: service.rateCents) { _, _ in save() }
        .onChange(of: service.unit) { _, _ in save() }
        .onChange(of: service.isActive) { _, _ in save() }
    }

    private func save() { try? modelContext.save() }
}

