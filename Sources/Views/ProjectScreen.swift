import SwiftUI
import SwiftData
import AppKit

/// The product (BRIEF §5.5 item 3): a sticky header that prices the job on every keystroke, five collapsible
/// bucket sections of toggles below it, notes at the bottom. DECISIONS 3, 17, 18, 21, 24, 29, 30, 38–41.
struct ProjectScreen: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        if let project = selectedProject {
            ProjectEditor(project: project)
                .id(project.persistentModelID)
        } else {
            ContentUnavailableView("No project selected", systemImage: "square.dashed",
                                   description: Text("Pick a project, or press ⌘N to start one."))
        }
    }

    /// The selection, only while it belongs to the screen the sidebar shows (a package under Packages, a project under Projects).
    private var selectedProject: Project? {
        guard let id = appState.selectedProject, let project = modelContext.model(for: id) as? Project,
              !project.isDeleted, project.isTemplate == (appState.sidebar == .packages) else { return nil }
        return project
    }
}

private struct ProjectEditor: View {
    @Bindable var project: Project
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\Loadout.sortOrder), SortDescriptor(\Loadout.name)]) private var loadouts: [Loadout]
    @AppStorage(AppSettings.Key.billableHoursPerYear) private var billableHoursPerYear = AppSettings.defaults.billableHoursPerYear
    /// Sections start open; collapsing is per project (the editor is re-created per selection).
    @State private var collapsed: Set<Bucket> = []
    @State private var actualsExpanded = ProcessInfo.processInfo.environment["BUCKETS_SCREEN"] == "actuals"

    private var billableHours: Decimal { Decimal(billableHoursPerYear) }

    var body: some View {
        // Recomputed from the line snapshots on every render — every keystroke, every toggle. Never cached.
        let breakdown = project.breakdown(billableHours: billableHours)
        VStack(spacing: 0) {
            ProjectHeader(project: project, breakdown: breakdown, loadouts: loadouts) { loadout in
                project.apply(loadout)
                save()
            }
            Divider()
            Form {
                ForEach(Bucket.allCases, id: \.self) { bucket in
                    Section {
                        DisclosureGroup(isExpanded: isExpanded(bucket)) {
                            let lines = project.lines(in: bucket)
                            if lines.isEmpty {
                                Text("No \(bucket.title.lowercased()) rows on this project.")
                                    .foregroundStyle(.secondary)
                            }
                            let groups = ProjectText.grouped(lines)
                            ForEach(groups, id: \.title) { group in
                                if groups.count > 1 {
                                    Text(group.title).font(.caption).foregroundStyle(.secondary)
                                }
                                ForEach(group.lines) { line in
                                    ProjectLineRow(line: line, billableHours: billableHours) {
                                        // A hand-flipped labor or equipment toggle means the crew is custom now (DECISIONS 62).
                                        if line.bucket == .labor || line.bucket == .equipment { project.crewName = nil }
                                    }
                                }
                            }
                        } label: {
                            HStack {
                                Text(bucket.title).font(.headline)
                                Spacer()
                                Text(Money.format(breakdown[bucket])).monospacedDigit()
                            }
                        }
                    }
                }
                if !project.isTemplate {
                Section {
                    DisclosureGroup(isExpanded: $actualsExpanded) {
                        ActualsSection(project: project, billableHours: billableHours, save: save)
                    } label: {
                        HStack {
                            Text("Actuals").font(.headline)
                            Spacer()
                            if let a = project.actuals(billableHours: billableHours) {
                                Text(ProjectText.signed(a.totalVariance)).monospacedDigit()
                            }
                        }
                    }
                }
                }
                Section {
                    OptionalTextField(label: "Notes", value: $project.notes, prompt: "Optional", axis: .vertical)
                }
            }
            .formStyle(.grouped)
        }
        .toolbar {
            ToolbarItemGroup { toolbarButtons(breakdown) }
        }
        .onChange(of: project.name) { _, _ in save() }
        .onChange(of: project.client) { _, _ in save() }
        .onChange(of: project.date) { _, _ in save() }
        .onChange(of: project.hours) { _, _ in save() }
        .onChange(of: project.multiplier) { _, _ in save() }
        .onChange(of: project.notes) { _, _ in save() }
    }

    /// Re-price · Copy price · Copy breakdown (BRIEF §5.5; DECISIONS 18, 41).
    @ViewBuilder
    private func toolbarButtons(_ breakdown: Breakdown) -> some View {
        if project.isTemplate {
            Button { appState.usePackage(project) } label: { Label("Use Package", systemImage: "arrow.right.doc.on.clipboard") }
                .labelStyle(.titleAndIcon)
                .help("Start a new project from this package at today's rates")
        } else {
            Button { appState.saveAsPackage(project) } label: { Label("Save as Package", systemImage: "shippingbox.and.arrow.backward") }
                .labelStyle(.titleAndIcon)
                .help("Keep this project as a package to start future jobs from")
        }
        Button { reprice() } label: { Label("Re-price", systemImage: "arrow.clockwise") }
            .labelStyle(.titleAndIcon)
            .help("Copy today's rates, markup and minimum onto this project (toggles, quantities and hours stay)")
        Button { copy(ProjectText.price(name: project.displayName, priceCents: breakdown.price)) } label: {
            Label("Copy price", systemImage: "doc.on.doc")
        }
        .labelStyle(.titleAndIcon)
        .help("Copy the name and price — safe to paste for a customer")
        Button { copy(ProjectText.breakdown(project, breakdown: breakdown)) } label: {
            Label("Copy breakdown", systemImage: "list.bullet.clipboard")
        }
        .labelStyle(.titleAndIcon)
        .help("Copy the bucket subtotals, cost, markup, price and profit — internal, no rows")
    }

    private func isExpanded(_ bucket: Bucket) -> Binding<Bool> {
        Binding(get: { !collapsed.contains(bucket) && !(actualsExpanded && ProcessInfo.processInfo.environment["BUCKETS_SCREEN"] == "actuals") },
                set: { open in if open { collapsed.remove(bucket) } else { collapsed.insert(bucket) } })
    }

    /// DECISIONS 18: one button, no confirmation.
    private func reprice() {
        let items = (try? modelContext.fetch(FetchDescriptor<BucketItem>())) ?? []
        project.reprice(items: items, settings: AppSettings.current())
        save()
    }

    private func copy(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }

    private func save() {
        try? modelContext.save()
    }
}

/// Name · client · date, hours · multiplier, then the nine figures. Sits above the scrolling sections (BRIEF §5.5).
private struct ProjectHeader: View {
    @Bindable var project: Project
    let breakdown: Breakdown
    let loadouts: [Loadout]
    let applyLoadout: (Loadout) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                TextField("Name", text: $project.name, prompt: Text("Project name"))
                OptionalTextField(label: "Client", value: $project.client, prompt: "Client")
                DatePicker("Date", selection: $project.date, displayedComponents: .date)
                    .labelsHidden()
                    .fixedSize()
            }
            .textFieldStyle(.roundedBorder)

            // Hours and the multiplier share a row when the column is wide enough, else stack.
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 16) {
                    hoursField
                    multiplierPicker
                    crewMenu
                    Spacer(minLength: 0)
                }
                VStack(alignment: .leading, spacing: 8) {
                    hoursField
                    multiplierPicker
                    crewMenu
                }
            }

            HStack(alignment: .top, spacing: 8) {
                ForEach(Bucket.allCases, id: \.self) { bucket in
                    figure(bucket == .subcontractors ? "Subs" : bucket.title, Money.format(breakdown[bucket]))
                }
            }

            Divider()

            HStack(alignment: .top, spacing: 8) {
                figure("Cost", Money.format(breakdown.cost))
                figure("Markup", ProjectText.markupString(project.markupPct))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Price").font(.caption).foregroundStyle(.secondary)
                    Text(Money.format(breakdown.price)).font(.largeTitle).bold().monospacedDigit()
                        .accessibilityIdentifier("price")
                        .fixedSize()
                }
                .layoutPriority(1)
                .frame(maxWidth: .infinity, alignment: .leading)
                figure("Profit", Money.format(breakdown.profit), caption: "\(percentString(breakdown.marginPct)) margin")
            }
        }
        .padding()
    }

    /// Crew: apply a loadout to the labor and equipment toggles (DECISIONS 62). Hidden until a loadout exists.
    @ViewBuilder private var crewMenu: some View {
        if !loadouts.isEmpty {
            Menu {
                ForEach(loadouts) { loadout in
                    Button(loadout.displayName) { applyLoadout(loadout) }
                }
            } label: {
                Label(project.crewName ?? "Crew", systemImage: "person.3")
            }
            .fixedSize()
            .help("Apply a loadout: turns on its people and equipment, turns the rest off")
        }
    }

    private var hoursField: some View {
        HStack(spacing: 6) {
            Text("Hours").fixedSize()
            DecimalField(label: "Hours", value: $project.hours, maximum: ProjectText.hoursMaximum)
                .labelsHidden()
                .textFieldStyle(.roundedBorder)
                .frame(width: 72)
                .help("Crew clock time, door to door: drive out, work, cleanup, drive back, dump run")
        }
    }

    private var multiplierPicker: some View {
        Picker("Multiplier", selection: $project.multiplier) {
            ForEach(ProjectMultiplier.allCases) { Text($0.title).tag($0.rawValue) }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .fixedSize()
    }

    private func figure(_ title: String, _ value: String, caption: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value).monospacedDigit()
            if let caption { Text(caption).font(.caption).foregroundStyle(.secondary) }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// One line of a bucket section: the toggle (row name), its snapshot rate, and for quantity rows the qty and total.
private struct ProjectLineRow: View {
    @Bindable var line: ProjectLine
    let billableHours: Decimal
    var onToggle: () -> Void = {}
    @Environment(\.modelContext) private var modelContext

    private var isQuantity: Bool { line.bucket.rowKind == .quantity }

    var body: some View {
        HStack(spacing: 12) {
            // Flips isOn only; the snapshot is never touched (DECISIONS 17).
            Toggle(isOn: Binding(get: { line.isOn }, set: { line.isOn = $0; onToggle() })) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(line.displayName)
                        if let status = line.statusCaption {
                            Text(status).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    // Quantity rows carry the rate under the name so the qty and total have the trailing edge.
                    if isQuantity {
                        Text(line.rateLabel(billableHours: billableHours))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                }
            }
            .toggleStyle(.checkbox)
            .accessibilityIdentifier("line.\(line.name)")
            Spacer(minLength: 8)
            if isQuantity {
                DecimalField(label: "Quantity", value: $line.qty, placeholder: "0", maximum: ProjectText.qtyMaximum)
                    .labelsHidden()
                    .accessibilityIdentifier("qty.\(line.name)")
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 64)
                    .help("How many \(line.unit.isEmpty ? "units" : line.unit)")
                Text(line.isOn ? Money.format(line.totalCents) : "")
                    .monospacedDigit()
                    .frame(width: 84, alignment: .trailing)
            } else {
                Text(line.rateLabel(billableHours: billableHours))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        }
        .padding(.vertical, isQuantity ? 3 : 0)
        .foregroundStyle(line.isOn ? .primary : .secondary)
        .onChange(of: line.isOn) { _, _ in try? modelContext.save() }
        .onChange(of: line.qty) { _, _ in try? modelContext.save() }
    }
}

// MARK: - Display helpers (non-view; tested in ProjectScreenTests)

/// 1× normal · 2× after-hours · 3× emergency (BRIEF §1; DECISIONS 40).
enum ProjectMultiplier: Int, CaseIterable, Identifiable {
    case normal = 1, afterHours = 2, emergency = 3

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .normal: "1× Normal"
        case .afterHours: "2× After-hours"
        case .emergency: "3× Emergency"
        }
    }

    static func title(_ value: Int) -> String {
        ProjectMultiplier(rawValue: value)?.title ?? "\(value)×"
    }
}

/// The two pasteboard texts (DECISIONS 41) and the header's read-only formats.
enum ProjectText {
    struct LineGroup { var title: String; var lines: [ProjectLine] }

    /// Lines grouped by their row's category (DECISIONS 57), or by the sub's name for subcontractor services
    /// (DECISIONS 60); uncategorised rows last under "Other".
    static func grouped(_ lines: [ProjectLine]) -> [LineGroup] {
        let keyed = Dictionary(grouping: lines) { line -> String in
            if line.bucket == .subcontractors { return line.item?.subcontractor?.name.trimmingCharacters(in: .whitespaces) ?? "" }
            return line.item?.category?.trimmingCharacters(in: .whitespaces) ?? ""
        }
        let titles = keyed.keys.sorted { a, b in
            if a.isEmpty != b.isEmpty { return b.isEmpty }
            return a.localizedStandardCompare(b) == .orderedAscending
        }
        return titles.map { LineGroup(title: $0.isEmpty ? "Other" : $0, lines: keyed[$0] ?? []) }
    }

    static let hoursMaximum = Decimal(string: "99999.99")!
    static let qtyMaximum = Decimal(string: "999999.99")!

    /// Customer-safe: "Oak removal — $2,501.50", nothing else.
    static func price(name: String, priceCents: Int) -> String {
        "\(name) — \(Money.format(priceCents))"
    }

    /// Internal: one line each — name, date, hours, multiplier, the five subtotals, Cost, Markup %, Price,
    /// Profit (margin). Never a row name, a rate, or a subcontractor (DECISIONS 41).
    static func breakdown(_ project: Project, breakdown b: Breakdown) -> String {
        var lines = [
            project.displayName,
            "Date: \(dateString(project.date))",
            "Hours: \(hoursString(project.hours))",
            "Multiplier: \(ProjectMultiplier.title(project.multiplier))",
        ]
        lines += Bucket.allCases.map { "\($0.title): \(Money.format(b[$0]))" }
        lines += [
            "Cost: \(Money.format(b.cost))",
            "Markup: \(markupString(project.markupPct))",
            "Price: \(Money.format(b.price))",
            "Profit: \(Money.format(b.profit)) (\(percentString(b.marginPct)) margin)",
        ]
        return lines.joined(separator: "\n")
    }

    /// "35%", "32.5%" — the snapshot markup, read-only in the header (DECISIONS 24).
    static func markupString(_ pct: Decimal) -> String {
        pct.formatted(.number.precision(.fractionLength(0...2)).locale(Locale(identifier: "en_US"))) + "%"
    }

    /// "Sep 13, 2026", pinned to en_US like every other figure the app formats.
    static func dateString(_ date: Date) -> String {
        date.formatted(Date.FormatStyle(date: .abbreviated, time: .omitted).locale(Locale(identifier: "en_US")))
    }
}

extension Project {
    var displayName: String { name.isEmpty ? "Untitled project" : name }
}

extension ProjectLine {
    var displayName: String { name.isEmpty ? "Untitled" : name }

    /// "$54.08/hr"; overhead "$6,000.00/yr = $4.00/hr"; quantity rows "$75.00/load", "$85.00 each".
    func rateLabel(billableHours: Decimal) -> String {
        let label = Buckets.rateLabel(cents: rateCents, unit: unit)
        guard bucket.isAnnual else { return label }
        let hourly = billableHours > 0 ? Money.cents(Decimal(rateCents) / billableHours) : 0
        return "\(label) = \(Money.format(hourly))/hr"
    }

    /// rate × qty for quantity rows, rounded once for display; hourly rows have no per-line total (DECISIONS 3).
    var totalCents: Int {
        guard bucket.rowKind == .quantity else { return 0 }
        return Money.cents(Decimal(rateCents) * (qty.isFinite && qty > 0 ? qty : 0))
    }

    /// DECISIONS 21: the row behind this line is gone, or archived. nil when it is a live row.
    var statusCaption: String? {
        guard let item else { return "row deleted" }
        return item.isActive ? nil : "archived"
    }
}

/// "$54.08/hr", "$6,000.00/yr", "$85.00 each", "$75.00/load" (shared by the Buckets table and the Project sections).
func rateLabel(cents: Int, unit: String) -> String {
    let money = Money.format(cents)
    if unit.isEmpty { return money }
    return unit == "each" ? "\(money) each" : "\(money)/\(unit)"
}


// MARK: - Actuals (BRIEF §3.5; DECISIONS 31)

/// Actual hours and actual quantities, then estimate vs actual per bucket on cost at this project's rates.
private struct ActualsSection: View {
    @Bindable var project: Project
    let billableHours: Decimal
    let save: () -> Void

    private var actualHours: Binding<Decimal> {
        Binding(get: { project.actualHours ?? 0 },
                set: { project.actualHours = $0 > 0 ? $0 : nil; save() })
    }

    var body: some View {
        LabeledContent("Actual hours") {
            DecimalField(label: "Actual hours", value: actualHours, placeholder: "0", maximum: Decimal(string: "99999.99")!)
                .labelsHidden()
                .frame(width: 120)
        }
        let quantityLines = project.sortedLines.filter { $0.bucket.rowKind == .quantity && $0.isOn }
        ForEach(quantityLines) { line in
            ActualQtyRow(line: line, save: save)
        }
        if let a = project.actuals(billableHours: billableHours) {
            Text("\(DecimalField.string(project.hours).isEmpty ? "0" : DecimalField.string(project.hours)) estimated / \(DecimalField.string(project.actualHours ?? 0)) actual hours")
                .foregroundStyle(.secondary)
            Grid(alignment: .trailing, horizontalSpacing: 24, verticalSpacing: 6) {
                GridRow {
                    Text("Bucket").gridColumnAlignment(.leading)
                    Text("Estimate"); Text("Actual"); Text("Variance")
                }
                .font(.caption).foregroundStyle(.secondary)
                ForEach(Bucket.allCases, id: \.self) { bucket in
                    GridRow {
                        Text(bucket.title).gridColumnAlignment(.leading)
                        Text(Money.format(a.estimate[bucket]))
                        Text(Money.format(a.actual[bucket]))
                        Text(ProjectText.signed(a.variance(bucket)))
                    }
                    .monospacedDigit()
                }
                Divider()
                GridRow {
                    Text("Total").bold().gridColumnAlignment(.leading)
                    Text(Money.format(a.estimate.cost)).bold()
                    Text(Money.format(a.actual.cost)).bold()
                    Text(ProjectText.signed(a.totalVariance) + (a.totalVariancePct.map { " (" + ProjectText.signedPercent($0) + ")" } ?? "")).bold()
                }
                .monospacedDigit()
            }
            Text("Variance is on cost at this project's rates; positive means the job cost more than estimated.")
                .font(.caption).foregroundStyle(.secondary)
        } else {
            Text("Enter actual hours after the job to see estimate vs actual per bucket.")
                .foregroundStyle(.secondary)
        }
    }
}

private struct ActualQtyRow: View {
    @Bindable var line: ProjectLine
    let save: () -> Void

    private var actualQty: Binding<Decimal> {
        Binding(get: { line.actualQty ?? 0 },
                set: { line.actualQty = $0 > 0 ? $0 : nil; save() })
    }

    var body: some View {
        LabeledContent {
            DecimalField(label: "Actual qty", value: actualQty, placeholder: DecimalField.string(line.qty).isEmpty ? "0" : DecimalField.string(line.qty))
                .labelsHidden()
                .frame(width: 120)
        } label: {
            Text(line.name)
            Text("estimated \(DecimalField.string(line.qty).isEmpty ? "0" : DecimalField.string(line.qty)) \(line.unit)")
                .font(.caption).foregroundStyle(.secondary)
        }
    }
}

extension ProjectText {
    static func signed(_ cents: Int) -> String {
        cents > 0 ? "+" + Money.format(cents) : Money.format(cents)
    }

    static func signedPercent(_ pct: Decimal) -> String {
        (pct > 0 ? "+" : "") + percentString(pct)
    }
}
