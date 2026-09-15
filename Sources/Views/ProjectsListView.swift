import SwiftUI
import SwiftData

/// Every priced job, newest first: Name · Date · Hours · Price · Actual variance (BRIEF §5.5 item 2; DECISIONS 19, 31, 42).
struct ProjectsListView: View {
    @Environment(AppState.self) private var appState
    @Query(sort: [SortDescriptor(\Project.date, order: .reverse), SortDescriptor(\Project.name)]) private var projects: [Project]
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
            if projects.isEmpty {
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
                    TableColumn("Date") { project in
                        Text(ProjectText.dateString(project.date)).monospacedDigit()
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
                    TableColumn("Actual variance") { project in
                        // Cost variance at the snapshot rates once actual hours are in; "—" until then (DECISIONS 31).
                        Text(ProjectsText.variance(project.actuals(billableHours: billableHours)?.totalVariance))
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
        .navigationTitle("Projects")
        .navigationSplitViewColumnWidth(min: 470, ideal: 520)
        .toolbar {
            ToolbarItemGroup {
                Button { appState.newProject() } label: { Label("New Project", systemImage: "plus") }
                    .help("New project (⌘N)")
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
        Button("New Project") { appState.newProject() }
        if let id = ids.first, ids.count == 1 {
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
