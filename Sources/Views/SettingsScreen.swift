import SwiftUI
import SwiftData
import AppKit
import UniformTypeIdentifiers

/// The five settings plus Export JSON / Import JSON (BRIEF §1, §5.5 item 4; DECISIONS 10, 12, 23, 24, 43, 44).
/// Opened with ⌘, as the standard Settings scene. Every field writes UserDefaults as you type, through `@AppStorage`.
struct SettingsScreen: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @AppStorage(AppSettings.Key.billableHoursPerYear) private var billableHoursPerYear = AppSettings.defaults.billableHoursPerYear
    @AppStorage(AppSettings.Key.laborBurdenPct) private var laborBurdenPct = AppSettings.defaults.laborBurdenPct
    @AppStorage(AppSettings.Key.costOfMoneyPct) private var costOfMoneyPct = AppSettings.defaults.costOfMoneyPct
    @State private var pendingImport: PendingImport?
    @State private var confirmingImport = false
    @State private var failure: TransferFailure?
    @State private var showingFailure = false
    @State private var lastTransfer: String?

    var body: some View {
        Form {
            Section {
                field("Billable hours per year", SettingsText.billableHoursCaption) {
                    DecimalField(label: "Billable hours per year", value: SettingsField.billableHours($billableHoursPerYear),
                                 placeholder: "1500")
                        .labelsHidden()
                        .frame(width: 100)
                    Text("hours").foregroundStyle(.secondary)
                }
                field("Labor burden", SettingsText.laborBurdenCaption) {
                    DecimalField(label: "Labor burden", value: SettingsField.percent($laborBurdenPct), placeholder: "30")
                        .labelsHidden()
                        .frame(width: 100)
                    Text("%").foregroundStyle(.secondary)
                }
                field("Cost of money", SettingsText.costOfMoneyCaption) {
                    DecimalField(label: "Cost of money", value: SettingsField.percent($costOfMoneyPct), placeholder: "0")
                        .labelsHidden()
                        .frame(width: 100)
                    Text("%").foregroundStyle(.secondary)
                }
            } header: {
                Text("Rates")
            } footer: {
                Text("The target margin, the minimum job, the sales allowance and the payroll tax on commission are company defaults: set them in the Company profile.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section {
                LabeledContent {
                    Button("Export JSON…") { exportJSON() }
                } label: {
                    Text("Export")
                    Text("Every row, project and setting, in one file.").foregroundStyle(.secondary)
                }
                LabeledContent {
                    Button("Add or Update Rows…") { chooseMerge() }
                } label: {
                    Text("Add or update rows")
                    Text("Adds a file's rows to your buckets and updates rows with the same name. Rows not in the file are untouched. A file may remove a subcontractor it names; one whose services are on a project is archived instead.")
                        .foregroundStyle(.secondary)
                }
                LabeledContent {
                    Button("Import JSON…") { chooseImport() }
                } label: {
                    Text("Import")
                    Text("Replaces every row and project with a file's contents and applies its settings.")
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Data")
            } footer: {
                if let lastTransfer { Text(lastTransfer) }
            }
        }
        .formStyle(.grouped)
        .frame(width: 600, height: 560)
        .navigationTitle("Settings")
        .alert("Replace all rows and projects?", isPresented: $confirmingImport, presenting: pendingImport) { pending in
            Button("Replace", role: .destructive) { runImport(pending) }
            Button("Cancel", role: .cancel) {}
        } message: { pending in
            Text(SettingsText.importPrompt(fileName: pending.fileName, rows: pending.document.items.count,
                                           projects: pending.document.projects.count))
        }
        .alert(failure?.title ?? "", isPresented: $showingFailure, presenting: failure) { _ in
            Button("OK", role: .cancel) {}
        } message: { failure in
            Text(failure.message)
        }
    }

    /// Title and caption on the left, the field on the right.
    private func field<Content: View>(_ title: String, _ caption: String, @ViewBuilder content: () -> Content) -> some View {
        LabeledContent {
            HStack(spacing: 6, content: content)
        } label: {
            Text(title)
            Text(caption).foregroundStyle(.secondary)
        }
    }

    // MARK: Export / Import (DECISIONS 43)

    private func exportJSON() {
        let panel = NSSavePanel()
        panel.title = "Export Buckets JSON"
        panel.allowedContentTypes = [.json]
        panel.canCreateDirectories = true
        panel.nameFieldStringValue = SettingsText.exportFileName(for: .now)
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            let data = try Transfer.exportJSON(from: modelContext, settings: AppSettings.current(), exportedAt: .now)
            try data.write(to: url, options: .atomic)
            lastTransfer = "Exported to \(url.lastPathComponent)."
        } catch {
            fail("Couldn't export", error)
        }
    }

    /// Non-destructive: adds rows, fills in $0 rows, never deletes (DECISIONS 55), except an unreferenced subcontractor
    /// the file marks `remove` (DECISIONS 91).
    private func chooseMerge() {
        let panel = NSOpenPanel()
        panel.title = "Add Rows from Buckets JSON"
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            let result = try Transfer.mergeItems(try Data(contentsOf: url), into: modelContext)
            lastTransfer = "Added \(result.added) rows, updated \(result.updated), left \(result.unchanged) unchanged"
                + (result.company ? ", applied the company profile" : "")
                + (result.packages + result.packagesUpdated > 0
                    ? ", \(result.packages) packages added and \(result.packagesUpdated) updated" : "")
                + (result.packagesSkipped > 0
                    ? ", \(result.packagesSkipped) packages skipped (name matches several packages)" : "")
                + (result.packageLinesSkipped > 0 ? ", \(result.packageLinesSkipped) package lines skipped" : "")
                + (result.subcontractorsRemoved > 0 ? ", \(result.subcontractorsRemoved) subcontractors removed" : "")
                + (result.subcontractorsArchived > 0 ? ", \(result.subcontractorsArchived) subcontractors archived" : "")
                + " (\(url.lastPathComponent))."
        } catch {
            fail("Couldn't add rows", error)
        }
    }

    /// Picks the file and reads it; the replace happens only after the alert's destructive button.
    private func chooseImport() {
        let panel = NSOpenPanel()
        panel.title = "Import Buckets JSON"
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            let data = try Data(contentsOf: url)
            let document = try Transfer.decoder().decode(TransferDocument.self, from: data)
            pendingImport = PendingImport(fileName: url.lastPathComponent, data: data, document: document)
            confirmingImport = true
        } catch {
            fail("Couldn't read “\(url.lastPathComponent)”", error)
        }
    }

    private func runImport(_ pending: PendingImport) {
        // The selected row and project are about to be deleted; drop the selections first.
        appState.selectedItem = nil
        appState.selectedProject = nil
        do {
            let settings = try Transfer.importJSON(pending.data, into: modelContext)
            settings.save()
            lastTransfer = SettingsText.importSummary(fileName: pending.fileName, rows: pending.document.items.count,
                                                      projects: pending.document.projects.count)
        } catch {
            fail("Couldn't import “\(pending.fileName)”", error)
        }
        pendingImport = nil
    }

    private func fail(_ title: String, _ error: any Error) {
        failure = TransferFailure(title: title, message: error.localizedDescription)
        showingFailure = true
    }
}

/// A file that was chosen and parsed, waiting for the "Replace" confirmation.
private struct PendingImport {
    var fileName: String
    var data: Data
    var document: TransferDocument
}

private struct TransferFailure {
    var title: String
    var message: String
}

// MARK: - Non-view helpers (tested in ProjectsListTests)

/// Bindings between the `@AppStorage` values and the shared live fields (DECISIONS 10, 11, 12).
enum SettingsField {
    /// Billable hours are a whole number of at least 1; anything less is ignored so the last good value stays
    /// (DECISIONS 10: "Settings refuses billable < 1").
    static func billableHours(_ stored: Binding<Int>) -> Binding<Decimal> {
        Binding(get: { Decimal(stored.wrappedValue) },
                set: { if let hours = wholeHours($0) { stored.wrappedValue = hours } })
    }

    /// The typed value rounded to a whole number of hours, or nil when it is below 1.
    static func wholeHours(_ value: Decimal) -> Int? {
        guard value.isFinite, value > 0 else { return nil }
        var exact = value
        var rounded = Decimal()
        NSDecimalRound(&rounded, &exact, 0, .plain)
        guard rounded >= 1, rounded <= Decimal(Int.max) else { return nil }
        return NSDecimalNumber(decimal: rounded).intValue
    }

    /// A whole percent (30, 32.5), never negative. Stored as `Double`; read back exactly through
    /// `Money.decimal(from:)`, so 32.5 stays 32.5.
    static func percent(_ stored: Binding<Double>) -> Binding<Decimal> {
        Binding(get: { Money.decimal(from: stored.wrappedValue) },
                set: { stored.wrappedValue = double($0) })
    }

    /// The target margin: a whole percent from 0 up to `PriceRule.maximumMarginPct`; anything else is ignored so
    /// the last good value stays (a 100% margin has no price).
    static func margin(_ stored: Binding<Double>) -> Binding<Decimal> {
        Binding(get: { Money.decimal(from: stored.wrappedValue) },
                set: { if let pct = marginPercent($0) { stored.wrappedValue = double(pct) } })
    }

    static func marginPercent(_ value: Decimal) -> Decimal? {
        guard value.isFinite, value >= 0, value <= PriceRule.maximumMarginPct else { return nil }
        return value
    }

    /// Whether the margin, the sales allowance and its payroll tax leave a price: `100·M + A·(100 + B) ≤ 9,500`,
    /// i.e. `M + A(1 + B/100) ≤ 95` (DECISIONS 92). Each is a whole percent 0…100 (the margin 0…95).
    static func pricingShareFits(margin: Decimal, allowance: Decimal, burden: Decimal) -> Bool {
        guard [margin, allowance, burden].allSatisfy({ $0.isFinite && $0 >= 0 && $0 <= 100 }),
              margin <= PriceRule.maximumMarginPct else { return false }
        return 100 * margin + allowance * (100 + burden) <= 100 * PriceRule.maximumMarginPct
    }

    /// The target margin, also refused when the allowance leaves no room for it.
    static func margin(_ stored: Binding<Double>, allowance: Double, burden: Double) -> Binding<Decimal> {
        Binding(get: { Money.decimal(from: stored.wrappedValue) },
                set: { new in
                    if pricingShareFits(margin: new, allowance: Money.decimal(from: allowance), burden: Money.decimal(from: burden)) {
                        stored.wrappedValue = double(new)
                    }
                })
    }

    /// The sales allowance, 0…100 and within the 95% share (DECISIONS 92).
    static func allowance(_ stored: Binding<Double>, margin: Double, burden: Double) -> Binding<Decimal> {
        Binding(get: { Money.decimal(from: stored.wrappedValue) },
                set: { new in
                    if pricingShareFits(margin: Money.decimal(from: margin), allowance: new, burden: Money.decimal(from: burden)) {
                        stored.wrappedValue = double(new)
                    }
                })
    }

    /// The payroll tax on commission, 0…100 and within the 95% share (DECISIONS 92).
    static func commissionBurden(_ stored: Binding<Double>, margin: Double, allowance: Double) -> Binding<Decimal> {
        Binding(get: { Money.decimal(from: stored.wrappedValue) },
                set: { new in
                    if pricingShareFits(margin: Money.decimal(from: margin), allowance: Money.decimal(from: allowance), burden: new) {
                        stored.wrappedValue = double(new)
                    }
                })
    }

    static func double(_ value: Decimal) -> Double {
        guard value.isFinite, value > 0 else { return 0 }
        return NSDecimalNumber(decimal: value).doubleValue
    }
}

/// Captions (BRIEF §1) and the file name and messages of Export / Import.
enum SettingsText {
    static let billableHoursCaption = "Crew project-hours per year; divides labor and overhead. Changing it re-prices overhead on existing projects."
    static let laborBurdenCaption = "Payroll tax, workers comp and benefits, as a % of wage. The default for the labor calculator."
    static let marginCaption = "Profit as a share of the price. Price = Cost ÷ (1 − margin); 50% margin doubles the cost (a 100% markup). Copied onto new projects; Re-price refreshes it."
    static let minimumJobCaption = "Hard floor on every price. Copied onto new projects; Re-price refreshes it."
    static let costOfMoneyCaption = "Loan rate for financed equipment; 0 if paid cash. Used by the equipment calculator."

    /// "100%" markup for a 50% margin: markup = margin ÷ (100 − margin).
    static func markupString(marginPct: Decimal) -> String {
        percentString(PriceRule.targetMargin(marginPct).markupPercent)
    }

    /// The markup equivalent of the whole rule, allowance included: 50/7/7.65 → "135.5%" (DECISIONS 92).
    static func markupString(_ rule: PriceRule) -> String {
        percentString(rule.markupPercent)
    }

    static let salesAllowanceCaption = "Share of every price set aside for sales commission. Packages price with it, whoever closes the job."
    static let commissionBurdenCaption = "Employer cost on each commission dollar: FICA 7.65% plus workers' comp at the sales class rate and any PEO % fee. Read it off the PEO invoice."
    static let pricingShareFooter = "Margin is what is left after commission. The target margin plus the allowance and its payroll tax cannot pass 95%."

    /// "9 packages priced under an older allowance" (DECISIONS 92).
    static func stalePackages(_ count: Int) -> String {
        count == 1 ? "1 package priced under an older allowance" : "\(count) packages priced under an older allowance"
    }

    /// "Buckets-export-2026-09-14.json", the day in the local calendar.
    static func exportFileName(for date: Date, timeZone: TimeZone = .current) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        return "Buckets-export-\(formatter.string(from: date)).json"
    }

    static func importPrompt(fileName: String, rows: Int, projects: Int) -> String {
        "Every row and project in Buckets will be replaced by the \(rowsPhrase(rows)) and \(projectsPhrase(projects)) in “\(fileName)”, and its settings will be applied. Export first if the current data matters."
    }

    static func importSummary(fileName: String, rows: Int, projects: Int) -> String {
        "Imported \(rowsPhrase(rows)) and \(projectsPhrase(projects)) from \(fileName)."
    }

    static func rowsPhrase(_ count: Int) -> String {
        count == 1 ? "1 row" : "\(count) rows"
    }
}
