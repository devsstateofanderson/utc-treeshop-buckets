import SwiftUI
import SwiftData

/// Every priced job, newest first: Name · Date · Hours · Price · Actual variance (BRIEF §5.5 item 2; DECISIONS 19, 31, 42).
struct ProjectsListView: View {
    /// true = the Packages screen (DECISIONS 61): templates only, no dates or actuals.
    let templates: Bool
    @Environment(AppState.self) private var appState
    @Query private var allProjects: [Project]

    /// Filtered in memory rather than by predicate: a store migrated from before the flag existed can hold
    /// NULL for `isTemplate`, which a SQL predicate would not match (DECISIONS 61).
    private var projects: [Project] {
        let rows = allProjects.filter { $0.isTemplate == templates }
        return templates
            ? rows.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
            : rows.sorted { ($0.date, $0.name) > ($1.date, $1.name) }
    }

    init(templates: Bool) {
        self.templates = templates
    }
    @AppStorage(AppSettings.Key.billableHoursPerYear) private var billableHoursPerYear = AppSettings.defaults.billableHoursPerYear
    @State private var confirmingDelete = false

    private var billableHours: Decimal { Decimal(billableHoursPerYear) }

    private var selectedProject: Project? {
        guard let id = appState.selectedProject else { return nil }
        return projects.first { $0.persistentModelID == id }
    }

    var body: some View {
        @Bindable var appState = appState
        Group {
            if projects.isEmpty && templates {
                ContentUnavailableView {
                    Label("No packages yet", systemImage: "shippingbox.and.arrow.backward")
                } description: {
                    Text("A package is a pre-built project: a common job, a promotion, a standard crew day. Use Package makes a new project from it at today's rates.")
                } actions: {
                    Button("New Package") { appState.newPackage() }
                }
            } else if projects.isEmpty {
                ContentUnavailableView {
                    Label("No projects yet", systemImage: "list.clipboard")
                } description: {
                    Text("Name the job, type the hours, flip the rows it needs, read the price.")
                } actions: {
                    Button("New Project") { appState.newProject() }
                }
            } else {
                Table(projects, selection: $appState.selectedProject) {
                    TableColumn("Name") { project in
                        Text(project.displayName)
                            .foregroundStyle(project.name.isEmpty ? Color.secondary : Color.primary)
                    }
                    .width(min: 90, ideal: 110)
                    TableColumn(templates ? "Crew" : "Date") { project in
                        Text(templates ? (project.crewName ?? "") : ProjectText.dateString(project.date)).monospacedDigit()
                    }
                    .width(min: 86, ideal: 90)
                    TableColumn("Hours") { project in
                        Text(hoursString(project.hours)).monospacedDigit()
                    }
                    .width(min: 40, ideal: 44)
                    .alignment(.trailing)
                    TableColumn("Price") { project in
                        Text(Money.format(project.breakdown(billableHours: billableHours).price)).monospacedDigit()
                    }
                    .width(min: 80, ideal: 84)
                    .alignment(.trailing)
                    TableColumn(templates ? "Client" : "Actual variance") { project in
                        // Cost variance at the snapshot rates once actual hours are in; "—" until then (DECISIONS 31).
                        Text(templates ? (project.client ?? "") : ProjectsText.variance(project.actuals(billableHours: billableHours)?.totalVariance))
                            .monospacedDigit()
                            .foregroundStyle(project.actualHours == nil ? Color.secondary : Color.primary)
                    }
                    .width(min: 96, ideal: 100)
                    .alignment(.trailing)
                }
                .contextMenu(forSelectionType: PersistentIdentifier.self) { ids in
                    contextMenu(for: ids)
                }
                .onDeleteCommand { requestDelete() }
            }
        }
        .navigationTitle(templates ? "Packages" : "Projects")
        .navigationSplitViewColumnWidth(min: 470, ideal: 520)
        .toolbar {
            ToolbarItemGroup {
                Button { templates ? appState.newPackage() : appState.newProject() } label: { Label(templates ? "New Package" : "New Project", systemImage: "plus") }
                    .help(templates ? "New package (⌘N)" : "New project (⌘N)")
                if templates {
                    Button { if let p = selectedProject { appState.usePackage(p) } } label: { Label("Use Package", systemImage: "arrow.right.doc.on.clipboard") }
                        .labelStyle(.titleAndIcon)
                        .disabled(selectedProject == nil)
                        .help("Start a new project from this package at today's rates")
                }
                Button { appState.duplicateSelectedProject() } label: { Label("Duplicate", systemImage: "plus.square.on.square") }
                    .disabled(selectedProject == nil)
                    .help("Duplicate the selected project — everything copied, actuals cleared (⌘D)")
                Button(role: .destructive) { requestDelete() } label: { Label("Delete", systemImage: "trash") }
                    .disabled(selectedProject == nil)
                    .help("Delete the selected project")
            }
        }
        .alert("Delete “\(selectedProject?.displayName ?? "")”?", isPresented: $confirmingDelete) {
            Button("Delete", role: .destructive) {
                if let project = selectedProject { appState.delete(project) }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This can't be undone. The bucket rows it uses stay.")
        }
    }

    /// The same three actions as the toolbar, on the right-clicked row (DECISIONS 42).
    @ViewBuilder
    private func contextMenu(for ids: Set<PersistentIdentifier>) -> some View {
        Button(templates ? "New Package" : "New Project") { templates ? appState.newPackage() : appState.newProject() }
        if let id = ids.first, ids.count == 1 {
            if templates {
                Button("Use Package") {
                    if let p = projects.first(where: { $0.persistentModelID == id }) { appState.usePackage(p) }
                }
            }
            Button("Duplicate") {
                appState.selectedProject = id
                appState.duplicateSelectedProject()
            }
            Button("Delete…", role: .destructive) {
                appState.selectedProject = id
                requestDelete()
            }
        }
    }

    private func requestDelete() {
        guard selectedProject != nil else { return }
        confirmingDelete = true
    }
}

/// Non-view formats for the Projects list (tested in ProjectsListTests).
enum ProjectsText {
    /// Signed dollars: "+$500.74" when the job cost more than estimated, "-$12.00" when less, "$0.00" on the nose;
    /// an em dash until actual hours are entered (DECISIONS 31).
    static func variance(_ cents: Int?) -> String {
        guard let cents else { return "—" }
        return cents > 0 ? "+" + Money.format(cents) : Money.format(cents)
    }
}
