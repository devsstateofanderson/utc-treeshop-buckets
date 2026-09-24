import Foundation
import SwiftData

/// The company's own record (DECISIONS 65): who it is, its licenses and insurance, and the documents it needs
/// often (COIs, policies, certifications). One row; created on first use.
@Model final class Company {
    var name: String
    var dba: String?
    var owner: String?
    var address: String?
    var phone: String?
    var email: String?
    var website: String?
    var ein: String?
    /// Free text: business tax receipt, ISA certifications, DOT number, pesticide license…
    var licenses: String?
    var glCarrier: String?
    var glPolicy: String?
    var glExpires: Date?
    var autoCarrier: String?
    var autoPolicy: String?
    var autoExpires: Date?
    var wcCarrier: String?
    var wcPolicy: String?
    var wcExpires: Date?
    var notes: String?
    /// Where the company works ("Orange, Seminole and Lake counties"); a required setup input (DECISIONS 73).
    var serviceArea: String?
    @Relationship(deleteRule: .cascade, inverse: \CompanyDocument.company) var documents: [CompanyDocument] = []

    init(name: String = "") {
        self.name = name
    }
}

extension Company {
    /// The single company row, created empty on first use.
    @MainActor
    static func current(in context: ModelContext) -> Company {
        if let existing = (try? context.fetch(FetchDescriptor<Company>()))?.first { return existing }
        let company = Company()
        context.insert(company)
        try? context.save()
        return company
    }

    var sortedDocuments: [CompanyDocument] {
        documents.sorted { ($0.category, $0.title) < ($1.category, $1.title) }
    }
}

/// A file the company keeps on hand (DECISIONS 65). The bytes live in Store.documentsURL; this is the record.
@Model final class CompanyDocument {
    var title: String
    /// Insurance, License, Certification, Contract, Other…
    var category: String
    /// Name of the copy inside the app's Documents folder.
    var fileName: String
    var originalName: String
    var addedAt: Date
    var expiresAt: Date?
    var notes: String?
    var company: Company?

    init(title: String, category: String, fileName: String, originalName: String, addedAt: Date, expiresAt: Date? = nil, notes: String? = nil) {
        self.title = title
        self.category = category
        self.fileName = fileName
        self.originalName = originalName
        self.addedAt = addedAt
        self.expiresAt = expiresAt
        self.notes = notes
    }
}

extension CompanyDocument {
    static let categories = ["Insurance", "License", "Certification", "Contract", "Vehicle", "Other"]

    var fileURL: URL { Store.documentsURL.appending(path: fileName) }
    var fileExists: Bool { FileManager.default.fileExists(atPath: fileURL.path) }

    enum Status { case current, expiringSoon, expired, undated }

    /// Expired, expiring within 30 days, or fine (DECISIONS 65).
    func status(on date: Date = .now) -> Status {
        guard let expiresAt else { return .undated }
        if expiresAt < date { return .expired }
        return expiresAt < date.addingTimeInterval(30 * 86_400) ? .expiringSoon : .current
    }

    /// Copies `source` into the Documents folder and returns the record (not yet inserted).
    static func importing(_ source: URL, title: String? = nil, category: String, addedAt: Date = .now) throws -> CompanyDocument {
        try FileManager.default.createDirectory(at: Store.documentsURL, withIntermediateDirectories: true)
        let original = source.lastPathComponent
        let stored = "\(UUID().uuidString.prefix(8))-\(original)"
        try FileManager.default.copyItem(at: source, to: Store.documentsURL.appending(path: stored))
        return CompanyDocument(title: title ?? source.deletingPathExtension().lastPathComponent, category: category,
                               fileName: stored, originalName: original, addedAt: addedAt)
    }

    /// Removes the stored copy (the record is deleted by the caller).
    func removeFile() {
        try? FileManager.default.removeItem(at: fileURL)
    }
}
