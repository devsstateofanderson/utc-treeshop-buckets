import SwiftUI
import SwiftData
import AppKit

/// Company profile (DECISIONS 65): identity, licenses, insurance. Lives in the content column; documents sit in the detail column.
struct CompanyProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var companies: [Company]

    var body: some View {
        if let company = companies.first {
            CompanyForm(company: company)
        } else {
            Color.clear.task { _ = Company.current(in: modelContext) }
        }
    }
}

private struct CompanyForm: View {
    @Bindable var company: Company

    var body: some View {
        Form {
            CompanyIdentitySection(company: company)
            CompanyLicensesSection(company: company)
            Section("Insurance") {
                PolicyRow(title: "General liability", carrier: $company.glCarrier, number: $company.glPolicy, expires: $company.glExpires)
                PolicyRow(title: "Auto", carrier: $company.autoCarrier, number: $company.autoPolicy, expires: $company.autoExpires)
                PolicyRow(title: "Workers comp", carrier: $company.wcCarrier, number: $company.wcPolicy, expires: $company.wcExpires)
            }
            CompanyNotesSection(company: company)
        }
        .formStyle(.grouped)
        .navigationTitle("Company")
        .navigationSplitViewColumnWidth(min: 480, ideal: 560)
    }
}

private struct CompanyIdentitySection: View {
    @Bindable var company: Company
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        Section("Company") {
            TextField("Legal name", text: $company.name, prompt: Text("Sacred Tree Service LLC"))
            OptionalTextField(label: "DBA", value: $company.dba, prompt: "Doing business as")
            OptionalTextField(label: "Owner", value: $company.owner, prompt: "Owner / principal")
            OptionalTextField(label: "Address", value: $company.address, prompt: "Street, city, state, zip", axis: .vertical)
            OptionalTextField(label: "Phone", value: $company.phone, prompt: "Optional")
            OptionalTextField(label: "Email", value: $company.email, prompt: "Optional")
            OptionalTextField(label: "Website", value: $company.website, prompt: "Optional")
            OptionalTextField(label: "EIN", value: $company.ein, prompt: "Optional")
        }
        .onChange(of: company.name) { _, _ in try? modelContext.save() }
        .onChange(of: company.dba) { _, _ in try? modelContext.save() }
        .onChange(of: company.owner) { _, _ in try? modelContext.save() }
        .onChange(of: company.address) { _, _ in try? modelContext.save() }
        .onChange(of: company.phone) { _, _ in try? modelContext.save() }
        .onChange(of: company.email) { _, _ in try? modelContext.save() }
        .onChange(of: company.website) { _, _ in try? modelContext.save() }
        .onChange(of: company.ein) { _, _ in try? modelContext.save() }
    }
}

private struct CompanyLicensesSection: View {
    @Bindable var company: Company
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        Section {
            OptionalTextField(label: "Licenses & certifications", value: $company.licenses,
                              prompt: "Business tax receipt, ISA certifications, DOT number, pesticide license…", axis: .vertical)
        }
        .onChange(of: company.licenses) { _, _ in try? modelContext.save() }
    }
}

private struct CompanyNotesSection: View {
    @Bindable var company: Company
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        Section {
            OptionalTextField(label: "Notes", value: $company.notes, prompt: "Optional", axis: .vertical)
        }
        .onChange(of: company.notes) { _, _ in try? modelContext.save() }
    }
}

/// Carrier, policy number and expiration for one policy; the label shows the expiry state (DECISIONS 65).
private struct PolicyRow: View {
    let title: String
    @Binding var carrier: String?
    @Binding var number: String?
    @Binding var expires: Date?
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        LabeledContent {
            VStack(alignment: .trailing, spacing: 6) {
                OptionalTextField(label: "\(title) carrier", value: $carrier, prompt: "Carrier").labelsHidden()
                OptionalTextField(label: "\(title) policy", value: $number, prompt: "Policy number").labelsHidden()
                OptionalDatePicker(label: "\(title) expires", date: $expires)
            }
        } label: {
            Text(title)
            if let d = expires {
                Text(CompanyText.expiry(d)).foregroundStyle(CompanyText.expiryStyle(d))
            }
        }
        .onChange(of: carrier) { _, _ in try? modelContext.save() }
        .onChange(of: number) { _, _ in try? modelContext.save() }
        .onChange(of: expires) { _, _ in try? modelContext.save() }
    }
}

/// A date that can be unset ("none" until a date is chosen).
struct OptionalDatePicker: View {
    let label: String
    @Binding var date: Date?

    var body: some View {
        HStack(spacing: 6) {
            if let bound = Binding($date) {
                DatePicker(label, selection: bound, displayedComponents: .date).labelsHidden().fixedSize()
                Button { date = nil } label: { Image(systemName: "xmark.circle") }
                    .buttonStyle(.borderless).help("Clear the date")
            } else {
                Button("Set expiration…") { date = Calendar.current.date(byAdding: .year, value: 1, to: .now) }
                    .buttonStyle(.link)
            }
        }
    }
}

/// The company's documents (DECISIONS 65): copies kept in the app's Documents folder, opened with the Mac's default app.
struct CompanyDocumentsView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query private var companies: [Company]
    @State private var selection: PersistentIdentifier?
    @State private var confirmingRemove = false
    @State private var failure: String?

    private var company: Company? { companies.first }
    private var documents: [CompanyDocument] { company?.sortedDocuments ?? [] }
    private var selected: CompanyDocument? { documents.first { $0.persistentModelID == selection } }

    var body: some View {
        VStack(spacing: 0) {
            if documents.isEmpty {
                ContentUnavailableView {
                    Label("No documents yet", systemImage: "doc.badge.plus")
                } description: {
                    Text("Keep the certificate of insurance, policies, licenses and certifications here so they are one click away. Each gets an expiration date and a warning when it is due.")
                } actions: {
                    Button("Add Document…") { pickFile() }
                }
            } else {
                Table(documents, selection: $selection) {
                    TableColumn("Document") { doc in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(doc.title)
                            Text(doc.originalName).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .width(min: 160, ideal: 240)
                    TableColumn("Category") { doc in Text(doc.category).foregroundStyle(.secondary) }
                        .width(min: 90, ideal: 110)
                    TableColumn("Expires") { doc in ExpiryCell(date: doc.expiresAt) }
                    .width(min: 120, ideal: 150)
                    TableColumn("File") { doc in
                        if doc.fileExists {
                            Button("Open") { NSWorkspace.shared.open(doc.fileURL) }.buttonStyle(.link)
                        } else {
                            Text("file missing").foregroundStyle(.secondary)
                        }
                    }
                    .width(70)
                }
                .contextMenu(forSelectionType: PersistentIdentifier.self) { ids in
                    if let id = ids.first, let doc = documents.first(where: { $0.persistentModelID == id }) {
                        Button("Open") { NSWorkspace.shared.open(doc.fileURL) }
                        Button("Show in Finder") { NSWorkspace.shared.activateFileViewerSelecting([doc.fileURL]) }
                        Divider()
                        Button("Remove…", role: .destructive) { selection = id; confirmingRemove = true }
                    }
                }
                if let doc = selected {
                    Divider()
                    DocumentDetail(document: doc)
                }
            }
        }
        .navigationTitle("Documents")
        .toolbar {
            ToolbarItemGroup {
                Button { pickFile() } label: { Label("Add Document", systemImage: "plus") }
                    .help("Copy a file into the company's documents (⌘N)")
                Button { if let doc = selected { NSWorkspace.shared.activateFileViewerSelecting([doc.fileURL]) } } label: {
                    Label("Show in Finder", systemImage: "folder")
                }
                .disabled(selected == nil || selected?.fileExists == false)
                Button(role: .destructive) { confirmingRemove = true } label: { Label("Remove", systemImage: "trash") }
                    .disabled(selected == nil)
            }
        }
        .onChange(of: appState.wantsDocumentPicker) { _, wants in
            if wants { appState.wantsDocumentPicker = false; pickFile() }
        }
        .confirmationDialog("Remove “\(selected?.title ?? "")”?", isPresented: $confirmingRemove, titleVisibility: .visible) {
            Button("Remove", role: .destructive) {
                if let doc = selected {
                    doc.removeFile()
                    modelContext.delete(doc)
                    try? modelContext.save()
                    selection = nil
                }
            }
        } message: {
            Text("The copy kept by Buckets is deleted. The original file wherever you picked it from is not touched.")
        }
        .alert("Couldn't add document", isPresented: Binding(get: { failure != nil }, set: { if !$0 { failure = nil } })) {
            Button("OK", role: .cancel) {}
        } message: { Text(failure ?? "") }
    }

    private func pickFile() {
        let panel = NSOpenPanel()
        panel.title = "Add Company Document"
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        guard panel.runModal() == .OK else { return }
        let company = Company.current(in: modelContext)
        for url in panel.urls {
            do {
                let doc = try CompanyDocument.importing(url, category: CompanyText.guessCategory(url.lastPathComponent))
                modelContext.insert(doc)
                doc.company = company
                selection = doc.persistentModelID
            } catch {
                failure = "\(url.lastPathComponent): \(error.localizedDescription)"
            }
        }
        try? modelContext.save()
    }
}

private struct DocumentDetail: View {
    @Bindable var document: CompanyDocument
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        Form {
            TextField("Title", text: $document.title)
            Picker("Category", selection: $document.category) {
                ForEach(CompanyDocument.categories, id: \.self) { Text($0).tag($0) }
                if !CompanyDocument.categories.contains(document.category) { Text(document.category).tag(document.category) }
            }
            LabeledContent("Expires") { OptionalDatePicker(label: "Expires", date: $document.expiresAt) }
            OptionalTextField(label: "Notes", value: $document.notes, prompt: "Optional", axis: .vertical)
            LabeledContent("Added") { Text(document.addedAt.formatted(date: .abbreviated, time: .omitted)) }
        }
        .formStyle(.grouped)
        .frame(maxHeight: 260)
        .onChange(of: document.title) { _, _ in try? modelContext.save() }
        .onChange(of: document.category) { _, _ in try? modelContext.save() }
        .onChange(of: document.expiresAt) { _, _ in try? modelContext.save() }
        .onChange(of: document.notes) { _, _ in try? modelContext.save() }
    }
}

enum CompanyText {
    static func expiry(_ date: Date, now: Date = .now) -> String {
        let text = date.formatted(date: .abbreviated, time: .omitted)
        if date < now { return "Expired \(text)" }
        let days = Calendar.current.dateComponents([.day], from: now, to: date).day ?? 0
        return days <= 30 ? "Expires \(text) (\(days) days)" : "Expires \(text)"
    }

    /// Red when expired, orange within 30 days, secondary otherwise (system colors only).
    static func expiryStyle(_ date: Date, now: Date = .now) -> AnyShapeStyle {
        if date < now { return AnyShapeStyle(.red) }
        return date < now.addingTimeInterval(30 * 86_400) ? AnyShapeStyle(.orange) : AnyShapeStyle(.secondary)
    }

    static func guessCategory(_ fileName: String) -> String {
        let n = fileName.lowercased()
        if n.contains("coi") || n.contains("insurance") || n.contains("policy") || n.contains("certificate of") { return "Insurance" }
        if n.contains("license") || n.contains("licence") || n.contains("permit") || n.contains("tax receipt") { return "License" }
        if n.contains("isa") || n.contains("cert") { return "Certification" }
        if n.contains("contract") || n.contains("agreement") { return "Contract" }
        if n.contains("registration") || n.contains("title") || n.contains("vin") { return "Vehicle" }
        return "Other"
    }
}

private struct ExpiryCell: View {
    let date: Date?
    var body: some View {
        if let date {
            Text(CompanyText.expiry(date)).foregroundStyle(CompanyText.expiryStyle(date))
        } else {
            Text("—").foregroundStyle(.secondary)
        }
    }
}
