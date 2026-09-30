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
    @Query private var allItems: [BucketItem]
    @AppStorage(AppSettings.Key.billableHoursPerYear) private var billableHoursPerYear = AppSettings.defaults.billableHoursPerYear
    /// Sections start open; collapsing is per project (the editor is re-created per selection).
    @State private var collapsed: Set<Bucket> = []
    @State private var expandedGroups: Set<String> = []
    @State private var actualsExpanded = ProcessInfo.processInfo.environment["BUCKETS_SCREEN"] == "actuals"

    private var billableHours: Decimal { Decimal(billableHoursPerYear) }

    var body: some View {
        // Recomputed from the line snapshots on every render — every keystroke, every toggle. Never cached.
        let breakdown = project.breakdown(billableHours: billableHours)
        let unresolved = project.unresolvedEnabledLines()
        VStack(spacing: 0) {
            ProjectHeader(project: project, breakdown: breakdown, loadouts: loadouts, laborRows: allItems.rows(in: .labor),
                          unresolvedCount: unresolved.count, applyLoadout: { loadout in
                project.apply(loadout)
                save()
            }, setSalesperson: { row in
                project.setSalesperson(row)
                save()
            })
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
                                    // Categories are collapsible and start collapsed (DECISIONS 69); the header says how many are on.
                                    DisclosureGroup(isExpanded: isGroupExpanded(bucket, group.title)) {
                                        ForEach(group.lines) { line in
                                            ProjectLineRow(line: line, billableHours: billableHours) {
                                                if line.bucket == .labor || line.bucket == .equipment { project.crewName = nil }
                                            }
                                        }
                                    } label: {
                                        HStack {
                                            Text(group.title)
                                            Spacer()
                                            Text(ProjectText.onCount(group.lines)).font(.caption).foregroundStyle(.secondary).monospacedDigit()
                                        }
                                    }
                                } else {
                                    ForEach(group.lines) { line in
                                        ProjectLineRow(line: line, billableHours: billableHours) {
                                            // A hand-flipped labor or equipment toggle means the crew is custom now (DECISIONS 62).
                                            if line.bucket == .labor || line.bucket == .equipment { project.crewName = nil }
                                        }
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
        .onChange(of: project.commissionPctOverride) { _, _ in save() }
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
            .help("Copy today's rates, target margin and minimum onto this project (toggles, quantities and hours stay)")
        Button { copy(ProjectText.price(name: project.displayName, priceCents: breakdown.price)) } label: {
            Label("Copy price", systemImage: "doc.on.doc")
        }
        .labelStyle(.titleAndIcon)
        .help("Copy the name and price — safe to paste for a customer")
        Button { copy(ProjectText.breakdown(project, breakdown: breakdown)) } label: {
            Label("Copy breakdown", systemImage: "list.bullet.clipboard")
        }
        .labelStyle(.titleAndIcon)
        .help("Copy the bucket subtotals, cost, margin, price, commission and profit — internal, no rows, no names")
    }

    /// Category groups inside a bucket section, collapsed until opened (DECISIONS 69).
    private func isGroupExpanded(_ bucket: Bucket, _ title: String) -> Binding<Bool> {
        let key = "\(bucket.rawValue)/\(title)"
        return Binding(get: { expandedGroups.contains(key) },
                       set: { open in if open { expandedGroups.insert(key) } else { expandedGroups.remove(key) } })
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
    /// Every Labor row in table order, for the Sold by menu (DECISIONS 94).
    let laborRows: [BucketItem]
    /// Enabled lines whose row is unresolved (DECISIONS 72): shown as a caption, never priced differently.
    let unresolvedCount: Int
    let applyLoadout: (Loadout) -> Void
    let setSalesperson: (BucketItem?) -> Void

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
                    soldBy
                    Spacer(minLength: 0)
                }
                VStack(alignment: .leading, spacing: 8) {
                    hoursField
                    multiplierPicker
                    crewMenu
                    soldBy
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
                figure(project.targetMarginPct == nil ? "Markup" : "Target margin", ProjectText.pricingFigure(project))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Price").font(.caption).foregroundStyle(.secondary)
                    Text(Money.format(breakdown.price)).font(.largeTitle).bold().monospacedDigit()
                        .accessibilityIdentifier("price")
                        .fixedSize()
                }
                .layoutPriority(1)
                .frame(maxWidth: .infinity, alignment: .leading)
                if ProjectText.showsCommissionFigures(project) {
                    // DECISIONS 92: margin in the header means after commission; the gross profit is the caption.
                    if let commission = ProjectText.commissionFigure(project, breakdown) {
                        figure("Commission", commission.value, caption: commission.caption)
                    }
                    let caption = ProjectText.profitCaption(project, breakdown)
                    figure("Profit", Money.format(breakdown.profitAfterCommission), caption: caption.text,
                           captionStyle: caption.isWarning ? AnyShapeStyle(.orange) : AnyShapeStyle(.secondary))
                } else {
                    figure("Profit", Money.format(breakdown.profit), caption: "\(percentString(breakdown.marginPct)) margin")
                }
            }

            if unresolvedCount > 0 {
                Label(ProjectText.unresolvedWarning(count: unresolvedCount), systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .help("These rows still need review on the Buckets screen. The price uses the snapshot rates as always.")
                    .accessibilityIdentifier("unresolvedWarning")
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

    /// Sold by (DECISIONS 94): who sold the job and the commission it pays. Shown once any Labor row carries a
    /// commission % or the project names someone; never on a package. The % field beside it is the negotiated
    /// override, disabled until a salesperson is picked.
    @ViewBuilder private var soldBy: some View {
        if ProjectText.showsSoldBy(project, laborRows: laborRows) {
            HStack(spacing: 6) {
                Menu {
                    Button("None") { setSalesperson(nil) }
                    Divider()
                    ForEach(laborRows.filter(\.isActive)) { row in
                        Button(ProjectText.salespersonTitle(row)) { setSalesperson(row) }
                    }
                } label: {
                    Label(ProjectText.soldByTitle(project), systemImage: "person.crop.circle.badge.checkmark")
                }
                .fixedSize()
                .help("Who sold this job; their commission % is copied onto the project")
                OptionalDecimalField(label: "Commission %", value: $project.commissionPctOverride,
                                     placeholder: project.commissionPct.map { DecimalField.string($0) } ?? "")
                    .labelsHidden()
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 52)
                    .disabled(!ProjectText.overrideIsEnabled(project))
                    .help("Commission % negotiated for this job; empty uses the person's rate")
                    .accessibilityIdentifier("commissionOverride")
                Text("%").foregroundStyle(.secondary)
                if let caption = ProjectText.personRateCaption(project) {
                    Text(caption).font(.caption).foregroundStyle(.secondary).fixedSize()
                }
            }
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

    private func figure(_ title: String, _ value: String, caption: String? = nil,
                        captionStyle: AnyShapeStyle = AnyShapeStyle(.secondary)) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value).monospacedDigit()
            if let caption { Text(caption).font(.caption).foregroundStyle(captionStyle) }
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
                        if let warning = line.reviewCaption() {
                            Label(warning, systemImage: "exclamationmark.triangle")
                                .font(.caption).foregroundStyle(.orange)
                                .help("This row's figure is unresolved on the Buckets screen; the line still prices from its snapshot")
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

    /// "2 of 6 on" for a category group's header.
    static func onCount(_ lines: [ProjectLine]) -> String {
        "\(lines.filter(\.isOn).count) of \(lines.count) on"
    }

    /// The header's non-blocking warning (DECISIONS 72): "3 enabled rows use unresolved catalog inputs — price unchanged".
    static func unresolvedWarning(count: Int) -> String {
        count == 1 ? "1 enabled row uses an unresolved catalog input — price unchanged"
                   : "\(count) enabled rows use unresolved catalog inputs — price unchanged"
    }

    static let hoursMaximum = Decimal(string: "99999.99")!
    static let qtyMaximum = Decimal(string: "999999.99")!

    /// Customer-safe: "Oak removal — $2,501.50", nothing else.
    static func price(name: String, priceCents: Int) -> String {
        "\(name) — \(Money.format(priceCents))"
    }

    /// Internal: one line each — name, date, hours, multiplier, the five subtotals, Cost, Markup %, Price,
    /// Profit (margin). Never a row name, a rate, or a subcontractor (DECISIONS 41). With an allowance or a commission
    /// (DECISIONS 92): after Price, the allowance, the commission and its payroll tax, and after Profit the profit
    /// after commission. Never a person's name (DECISIONS 41, 88, 94).
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
            "\(project.targetMarginPct == nil ? "Markup" : "Target margin"): \(pricingString(project))",
            "Price: \(Money.format(b.price))",
        ]
        let showsCommission = showsCommissionFigures(project)
        if let allowance = allowanceLine(project) { lines.append(allowance) }
        if b.commission > 0 {
            lines.append("Commission: \(Money.format(b.commission)) (\(markupString(project.effectiveCommissionPct)))")
            lines.append("Commission payroll tax: \(Money.format(b.commissionTax))")
        }
        lines.append("Profit: \(Money.format(b.profit)) (\(percentString(b.marginPct)) margin)")
        if showsCommission {
            lines.append("Profit after commission: \(Money.format(b.profitAfterCommission)) (\(percentString(b.marginAfterCommissionPct)) margin)")
        }
        return lines.joined(separator: "\n")
    }

    // MARK: Commission (DECISIONS 92, 94)

    /// The allowance the project prices with; 0 for a legacy markup project, which ignores it (DECISIONS 92).
    static func allowancePct(_ project: Project) -> Decimal {
        project.targetMarginPct == nil ? 0 : PriceRule.percent(project.salesAllowancePct ?? 0)
    }

    /// The header shows the commission figures when the project prices with an allowance or pays a commission;
    /// otherwise it is exactly the header from before the allowance existed.
    static func showsCommissionFigures(_ project: Project) -> Bool {
        allowancePct(project) > 0 || project.effectiveCommissionPct > 0
    }

    /// "50%", or "50% · 7% allowance".
    static func pricingFigure(_ project: Project) -> String {
        let a = allowancePct(project)
        return a > 0 ? "\(pricingString(project)) · \(markupString(a)) allowance" : pricingString(project)
    }

    /// "Sales allowance: 7% (+7.65% payroll tax)" for Copy breakdown; nil without an allowance.
    static func allowanceLine(_ project: Project) -> String? {
        let a = allowancePct(project)
        guard a > 0 else { return nil }
        return "Sales allowance: \(markupString(a)) (+\(markupString(PriceRule.percent(project.commissionBurdenPct ?? 0))) payroll tax)"
    }

    /// The Commission figure, "$366.04 · 7%" with "+ $28.00 payroll tax"; nil when no commission is paid.
    static func commissionFigure(_ project: Project, _ b: Breakdown) -> (value: String, caption: String?)? {
        guard b.commission > 0 else { return nil }
        return (value: "\(Money.format(b.commission)) · \(markupString(project.effectiveCommissionPct))",
                caption: b.commissionTax > 0 ? "+ \(Money.format(b.commissionTax)) payroll tax" : nil)
    }

    struct ProfitCaption: Equatable {
        var text: String
        /// Shown in `.orange`: below the target margin, or a loss after commission.
        var isWarning: Bool
    }

    /// The Profit figure's caption when the header shows commission (DECISIONS 92):
    /// "50.0% after commission · $3,008.65 before"; "42.5% after commission · below 50% target" (orange);
    /// "loses $59.27 after commission" (orange); "57.5% margin · no commission" when none is paid.
    static func profitCaption(_ project: Project, _ b: Breakdown) -> ProfitCaption {
        if b.profitAfterCommission < 0 {
            return ProfitCaption(text: "loses \(Money.format(-b.profitAfterCommission)) after commission", isWarning: true)
        }
        let margin = percentString(b.marginAfterCommissionPct)
        if let target = project.targetMarginPct, Project.rounded1(b.marginAfterCommissionPct) < target {
            return ProfitCaption(text: "\(margin) after commission · below \(markupString(target)) target", isWarning: true)
        }
        if b.commission + b.commissionTax == 0 {
            return ProfitCaption(text: "\(margin) margin · no commission", isWarning: false)
        }
        return ProfitCaption(text: "\(margin) after commission · \(Money.format(b.profit)) before", isWarning: false)
    }

    /// Sold by is offered once any Labor row carries a commission % or the project already names someone; never on a
    /// package (DECISIONS 94).
    static func showsSoldBy(_ project: Project, laborRows: [BucketItem]) -> Bool {
        !project.isTemplate && (project.hasSalesperson || laborRows.contains { $0.commissionPct != nil })
    }

    /// "Sold by" with nobody picked; "Sold by Sam Rivera"; "Sold by Sam Rivera (row deleted)" once the row is gone.
    static func soldByTitle(_ project: Project) -> String {
        guard project.hasSalesperson else { return "Sold by" }
        let name = (project.salespersonName ?? "").isEmpty ? "Untitled" : project.salespersonName!
        return project.salesperson == nil ? "Sold by \(name) (row deleted)" : "Sold by \(name)"
    }

    /// A Sold by menu entry: "Sam Rivera · 7%", or the name alone when the row has no %.
    static func salespersonTitle(_ row: BucketItem) -> String {
        let name = row.name.isEmpty ? "Untitled" : row.name
        return row.commissionText.map { "\(name) · \($0)" } ?? name
    }

    /// The override is typed only once Sold by is set (DECISIONS 94).
    static func overrideIsEnabled(_ project: Project) -> Bool { project.hasSalesperson }

    /// "person's rate: 7%" beside the override when the override differs from the person's %; nil otherwise.
    static func personRateCaption(_ project: Project) -> String? {
        guard project.hasSalesperson, let override = project.commissionPctOverride, override != project.commissionPct else { return nil }
        return "person's rate: \(project.commissionPct.map { markupString($0) } ?? "none")"
    }

    /// "50%" target margin, or the legacy "35%" markup (DECISIONS 70).
    static func pricingString(_ project: Project) -> String {
        markupString(project.targetMarginPct ?? project.markupPct)
    }

    /// "35%", "32.5%" — a whole-percent figure without trailing zeros.
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
    /// "TRK-02 · Ford F250" for equipment with a unit code (DECISIONS 66), else the snapshot name.
    var displayName: String {
        let base = name.isEmpty ? "Untitled" : name
        if bucket == .equipment, let code = item?.unitCode, !code.isEmpty { return "\(code) · \(base)" }
        return base
    }

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
