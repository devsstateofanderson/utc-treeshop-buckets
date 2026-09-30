import SwiftUI
import SwiftData

/// Every priced job, newest first: Name · Date · Hours · Price · Sold by · Profit after · Actual variance (BRIEF §5.5
/// item 2; DECISIONS 19, 31, 42, 94). Every column of the Projects list sorts; Packages keep their name order.
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
    /// The Projects list's column sort; newest first until a header is clicked.
    @State private var sortOrder = ProjectsListRow.defaultOrder

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
            } else if !templates {
                projectsTable
            } else {
                // Packages (DECISIONS 61): name order, no dates, sold-by or actuals.
                Table(projects, selection: $appState.selectedProject) {
                    TableColumn("Name") { project in
                        Text(project.displayName)
                            .foregroundStyle(project.name.isEmpty ? Color.secondary : Color.primary)
                    }
                    .width(min: 90, ideal: 110)
                    TableColumn("Crew") { project in
                        Text(project.crewName ?? "").monospacedDigit()
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
                    TableColumn("Client") { project in
                        Text(project.client ?? "")
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

    /// The Projects list: one row per project, each figure computed once from one breakdown, sortable on every column
    /// (DECISIONS 31, 92, 94).
    private var projectsTable: some View {
        @Bindable var appState = appState
        let rows = ProjectsListRow.sorted(projects.map { ProjectsListRow($0, billableHours: billableHours) }, by: sortOrder)
        return Table(rows, selection: $appState.selectedProject, sortOrder: $sortOrder) {
            TableColumn("Name", value: \.name) { row in
                Text(row.displayName)
                    .foregroundStyle(row.name.isEmpty ? Color.secondary : Color.primary)
            }
            .width(min: 60, ideal: 84)
            TableColumn("Date", value: \.date) { row in
                Text(ProjectText.dateString(row.date)).monospacedDigit()
            }
            .width(min: 94, ideal: 96)
            TableColumn("Hours", value: \.hours) { row in
                Text(hoursString(row.hours)).monospacedDigit()
            }
            .width(min: 36, ideal: 38)
            .alignment(.trailing)
            TableColumn("Price", value: \.priceCents) { row in
                Text(Money.format(row.priceCents)).monospacedDigit()
            }
            .width(min: 70, ideal: 72)
            .alignment(.trailing)
            TableColumn("Sold by", value: \.soldBy) { row in
                Text(row.soldBy)
            }
            .width(min: 56, ideal: 62)
            TableColumn("Profit after", value: \.profitAfterCents) { row in
                // After commission and its payroll tax (DECISIONS 92); a loss reads in orange, as in the header.
                Text(Money.format(row.profitAfterCents)).monospacedDigit()
                    .foregroundStyle(row.profitAfterCents < 0 ? Color.orange : Color.primary)
            }
            .width(min: 72, ideal: 74)
            .alignment(.trailing)
            TableColumn("Actual variance", value: \.varianceSortKey) { row in
                // Cost variance at the snapshot rates once actual hours are in; "—" until then (DECISIONS 31).
                Text(ProjectsText.variance(row.varianceCents))
                    .monospacedDigit()
                    .foregroundStyle(row.varianceCents == nil ? Color.secondary : Color.primary)
            }
            .width(min: 88, ideal: 88)
            .alignment(.trailing)
        }
        .contextMenu(forSelectionType: PersistentIdentifier.self) { ids in
            contextMenu(for: ids)
        }
        .onDeleteCommand { requestDelete() }
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

/// One row of the Projects list: every figure its columns show, computed once from one breakdown so the columns agree,
/// and sortable by key path (tested in ProjectsListTests).
struct ProjectsListRow: Identifiable {
    let id: PersistentIdentifier
    /// The stored name ("" when unnamed); `displayName` is what the cell shows.
    let name: String
    let date: Date
    let hours: Decimal
    let priceCents: Int
    /// The salesperson's name, "" when nobody sold it (DECISIONS 94).
    let soldBy: String
    /// Profit after commission and its payroll tax; the profit when no commission is paid (DECISIONS 92).
    let profitAfterCents: Int
    /// Cost variance once actual hours are entered, else nil (DECISIONS 31).
    let varianceCents: Int?

    init(_ project: Project, billableHours: Decimal) {
        let breakdown = project.breakdown(billableHours: billableHours)
        id = project.persistentModelID
        name = project.name
        date = project.date
        hours = project.hours
        priceCents = breakdown.price
        soldBy = ProjectsText.soldBy(project)
        profitAfterCents = breakdown.profitAfterCommission
        varianceCents = project.actuals(billableHours: billableHours)?.totalVariance
    }

    var displayName: String { name.isEmpty ? "Untitled" : name }

    /// Rows without actuals sort below every variance ascending, above them descending.
    var varianceSortKey: Int { varianceCents ?? Int.min }

    /// Newest first, as the list has always opened.
    static let defaultOrder = [KeyPathComparator(\ProjectsListRow.date, order: .reverse)]

    /// `rows` in the clicked column's order; ties (and an empty order) fall back to newest first, then name.
    static func sorted(_ rows: [ProjectsListRow], by order: [KeyPathComparator<ProjectsListRow>]) -> [ProjectsListRow] {
        rows.sorted(using: order + [KeyPathComparator(\.date, order: .reverse), KeyPathComparator(\.name, order: .reverse)])
    }
}

/// Non-view formats for the Projects list (tested in ProjectsListTests).
enum ProjectsText {
    /// The Sold by column: the name kept on the project (it survives the row's deletion), "Untitled" for a nameless
    /// row, "" when nobody sold it (DECISIONS 94).
    static func soldBy(_ project: Project) -> String {
        guard project.hasSalesperson else { return "" }
        let name = (project.salespersonName ?? "").trimmingCharacters(in: .whitespaces)
        if !name.isEmpty { return name }
        let rowName = (project.salesperson?.name ?? "").trimmingCharacters(in: .whitespaces)
        return rowName.isEmpty ? "Untitled" : rowName
    }

    /// Signed dollars: "+$500.74" when the job cost more than estimated, "-$12.00" when less, "$0.00" on the nose;
    /// an em dash until actual hours are entered (DECISIONS 31).
    static func variance(_ cents: Int?) -> String {
        guard let cents else { return "—" }
        return cents > 0 ? "+" + Money.format(cents) : Money.format(cents)
    }
}
