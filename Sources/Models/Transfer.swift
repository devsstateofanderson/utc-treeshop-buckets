import Foundation
import SwiftData

/// Export JSON / Import JSON: a full round trip of the three models plus the five settings (DECISIONS 43).
/// Lines reference rows by their index in `items`, so the models need no id field.
struct TransferDocument: Codable, Equatable {
    static let currentFormatVersion = 1

    struct Item: Codable, Equatable {
        var bucket: Bucket
        var name: String
        var rateCents: Int
        var unit: String
        var isActive: Bool
        var source: String?
        var notes: String?
        var calcInputs: JSONValue?
        var sortOrder: Int
        var category: String?
        var link: String?
        /// Position in `subcontractors` for rows in the Subcontractors bucket.
        var subcontractorIndex: Int?
        var unitCode: String?
        var make: String?
        var model: String?
        var year: Int?
        var serial: String?
    }

    struct CompanyRecord: Codable, Equatable {
        var name: String
        var dba: String?
        var owner: String?
        var address: String?
        var phone: String?
        var email: String?
        var website: String?
        var ein: String?
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
        var documents: [DocumentRecord]
    }

    struct DocumentRecord: Codable, Equatable {
        var title: String
        var category: String
        var fileName: String
        var originalName: String
        var addedAt: Date
        var expiresAt: Date?
        var notes: String?
    }

    struct SubcontractorRecord: Codable, Equatable {
        var name: String
        var contact: String?
        var phone: String?
        var email: String?
        var notes: String?
        var isActive: Bool
        var sortOrder: Int
    }

    struct LoadoutRecord: Codable, Equatable {
        var name: String
        var notes: String?
        var sortOrder: Int
        /// Positions in `items`.
        var memberIndexes: [Int]
    }

    struct Line: Codable, Equatable {
        var itemIndex: Int?
        var bucket: Bucket
        var name: String
        var unit: String
        var rateCents: Int
        var isOn: Bool
        var qty: Decimal
        var actualQty: Decimal?
    }

    struct ProjectRecord: Codable, Equatable {
        var name: String
        var client: String?
        var date: Date
        var hours: Decimal
        var multiplier: Int
        var markupPct: Decimal
        var minimumJobCents: Int
        var actualHours: Decimal?
        var notes: String?
        var lines: [Line]
        var isTemplate: Bool?
        var crewName: String?
    }

    struct SettingsRecord: Codable, Equatable {
        var billableHoursPerYear: Int
        var laborBurdenPct: Double
        var markupPct: Double
        var minimumJobCents: Int
        var costOfMoneyPct: Double
    }

    var formatVersion: Int
    var exportedAt: Date
    var settings: SettingsRecord
    var items: [Item]
    var projects: [ProjectRecord]
    /// Optional so files from before DECISIONS 60/62/65 still read.
    var subcontractors: [SubcontractorRecord]?
    var loadouts: [LoadoutRecord]?
    var company: CompanyRecord?
}

/// A JSON fragment kept verbatim (the calculator inputs), so the export shows them as readable JSON, not base64.
enum JSONValue: Codable, Equatable {
    case object([String: JSONValue]), array([JSONValue]), string(String), number(Decimal), bool(Bool), null

    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if c.decodeNil() { self = .null }
        else if let b = try? c.decode(Bool.self) { self = .bool(b) }
        else if let n = try? c.decode(Decimal.self) { self = .number(n) }
        else if let s = try? c.decode(String.self) { self = .string(s) }
        else if let a = try? c.decode([JSONValue].self) { self = .array(a) }
        else { self = .object(try c.decode([String: JSONValue].self)) }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        switch self {
        case .null: try c.encodeNil()
        case .bool(let b): try c.encode(b)
        case .number(let n): try c.encode(n)
        case .string(let s): try c.encode(s)
        case .array(let a): try c.encode(a)
        case .object(let o): try c.encode(o)
        }
    }

    static func from(data: Data) -> JSONValue? { try? JSONDecoder().decode(JSONValue.self, from: data) }
    var data: Data? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try? encoder.encode(self)
    }
}

enum TransferError: Error, Equatable, LocalizedError {
    case unsupportedFormat(Int)
    case badItemIndex(Int)

    var errorDescription: String? {
        switch self {
        case .unsupportedFormat(let v): "This file is Buckets format \(v); this app reads format \(TransferDocument.currentFormatVersion)."
        case .badItemIndex(let i): "A project line points at row #\(i), which is not in the file."
        }
    }
}

enum Transfer {
    static func encoder() -> JSONEncoder {
        let e = JSONEncoder()
        e.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        e.dateEncodingStrategy = .iso8601
        return e
    }

    static func decoder() -> JSONDecoder {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }

    @MainActor
    static func document(from context: ModelContext, settings: AppSettings, exportedAt: Date) throws -> TransferDocument {
        let items = try context.fetch(FetchDescriptor<BucketItem>())
            .sorted { ($0.bucket.index, $0.sortOrder, $0.name) < ($1.bucket.index, $1.sortOrder, $1.name) }
        let index = Dictionary(uniqueKeysWithValues: items.enumerated().map { ($1.persistentModelID, $0) })
        let projects = try context.fetch(FetchDescriptor<Project>())
            .sorted { ($0.date, $0.name) < ($1.date, $1.name) }
        let subs = try context.fetch(FetchDescriptor<Subcontractor>()).sorted { ($0.sortOrder, $0.name) < ($1.sortOrder, $1.name) }
        let subIndex = Dictionary(uniqueKeysWithValues: subs.enumerated().map { ($1.persistentModelID, $0) })
        let loadouts = try context.fetch(FetchDescriptor<Loadout>()).sorted { ($0.sortOrder, $0.name) < ($1.sortOrder, $1.name) }
        let company = try context.fetch(FetchDescriptor<Company>()).first
        return TransferDocument(
            formatVersion: TransferDocument.currentFormatVersion,
            exportedAt: exportedAt,
            settings: .init(billableHoursPerYear: settings.billableHoursPerYear, laborBurdenPct: settings.laborBurdenPct,
                            markupPct: settings.markupPct, minimumJobCents: settings.minimumJobCents,
                            costOfMoneyPct: settings.costOfMoneyPct),
            items: items.map { i in
                .init(bucket: i.bucket, name: i.name, rateCents: i.rateCents, unit: i.unit, isActive: i.isActive,
                      source: i.source, notes: i.notes, calcInputs: i.calcInputs.flatMap(JSONValue.from), sortOrder: i.sortOrder,
                      category: i.category, link: i.link, subcontractorIndex: i.subcontractor.flatMap { subIndex[$0.persistentModelID] },
                      unitCode: i.unitCode, make: i.make, model: i.model, year: i.year, serial: i.serial)
            },
            projects: projects.map { p in
                .init(name: p.name, client: p.client, date: p.date, hours: p.hours, multiplier: p.multiplier,
                      markupPct: p.markupPct, minimumJobCents: p.minimumJobCents, actualHours: p.actualHours, notes: p.notes,
                      lines: p.sortedLines.map { l in
                          .init(itemIndex: l.item.flatMap { index[$0.persistentModelID] }, bucket: l.bucket, name: l.name,
                                unit: l.unit, rateCents: l.rateCents, isOn: l.isOn, qty: l.qty, actualQty: l.actualQty)
                      }, isTemplate: p.isTemplate, crewName: p.crewName)
            },
            subcontractors: subs.map { s in
                .init(name: s.name, contact: s.contact, phone: s.phone, email: s.email, notes: s.notes, isActive: s.isActive, sortOrder: s.sortOrder)
            },
            loadouts: loadouts.map { l in
                .init(name: l.name, notes: l.notes, sortOrder: l.sortOrder,
                      memberIndexes: l.sortedMembers.compactMap { index[$0.persistentModelID] })
            },
            company: company.map { c in
                .init(name: c.name, dba: c.dba, owner: c.owner, address: c.address, phone: c.phone, email: c.email, website: c.website,
                      ein: c.ein, licenses: c.licenses, glCarrier: c.glCarrier, glPolicy: c.glPolicy, glExpires: c.glExpires,
                      autoCarrier: c.autoCarrier, autoPolicy: c.autoPolicy, autoExpires: c.autoExpires,
                      wcCarrier: c.wcCarrier, wcPolicy: c.wcPolicy, wcExpires: c.wcExpires, notes: c.notes,
                      documents: c.sortedDocuments.map { d in
                          .init(title: d.title, category: d.category, fileName: d.fileName, originalName: d.originalName,
                                addedAt: d.addedAt, expiresAt: d.expiresAt, notes: d.notes)
                      })
            })
    }

    @MainActor
    static func exportJSON(from context: ModelContext, settings: AppSettings, exportedAt: Date) throws -> Data {
        try encoder().encode(try document(from: context, settings: settings, exportedAt: exportedAt))
    }

    /// Replaces every row and project in `context` with the file's contents and returns the file's settings.
    @MainActor
    @discardableResult
    static func importJSON(_ data: Data, into context: ModelContext) throws -> AppSettings {
        let doc = try decoder().decode(TransferDocument.self, from: data)
        guard doc.formatVersion == TransferDocument.currentFormatVersion else {
            throw TransferError.unsupportedFormat(doc.formatVersion)
        }
        for line in doc.projects.flatMap(\.lines) {
            if let i = line.itemIndex, !(0..<doc.items.count).contains(i) { throw TransferError.badItemIndex(i) }
        }
        let subRecords = doc.subcontractors ?? []
        for i in doc.items {
            if let s = i.subcontractorIndex, !(0..<subRecords.count).contains(s) { throw TransferError.badItemIndex(s) }
        }
        for l in doc.loadouts ?? [] {
            for m in l.memberIndexes where !(0..<doc.items.count).contains(m) { throw TransferError.badItemIndex(m) }
        }
        // Per-object deletes: a batch delete cannot honor the nullify inverse on ProjectLine.item.
        for loadout in try context.fetch(FetchDescriptor<Loadout>()) { context.delete(loadout) }
        for project in try context.fetch(FetchDescriptor<Project>()) { context.delete(project) }
        for line in try context.fetch(FetchDescriptor<ProjectLine>()) { context.delete(line) }
        for item in try context.fetch(FetchDescriptor<BucketItem>()) { context.delete(item) }
        for sub in try context.fetch(FetchDescriptor<Subcontractor>()) { context.delete(sub) }
        for company in try context.fetch(FetchDescriptor<Company>()) { context.delete(company) }
        try context.save()

        if let c = doc.company {
            let company = Company(name: c.name)
            company.dba = c.dba; company.owner = c.owner; company.address = c.address; company.phone = c.phone
            company.email = c.email; company.website = c.website; company.ein = c.ein; company.licenses = c.licenses
            company.glCarrier = c.glCarrier; company.glPolicy = c.glPolicy; company.glExpires = c.glExpires
            company.autoCarrier = c.autoCarrier; company.autoPolicy = c.autoPolicy; company.autoExpires = c.autoExpires
            company.wcCarrier = c.wcCarrier; company.wcPolicy = c.wcPolicy; company.wcExpires = c.wcExpires
            company.notes = c.notes
            context.insert(company)
            company.documents = c.documents.map { d in
                CompanyDocument(title: d.title, category: d.category, fileName: d.fileName, originalName: d.originalName,
                                addedAt: d.addedAt, expiresAt: d.expiresAt, notes: d.notes)
            }
        }

        let subs = subRecords.map { s in
            Subcontractor(name: s.name, contact: s.contact, phone: s.phone, email: s.email, notes: s.notes,
                          isActive: s.isActive, sortOrder: s.sortOrder)
        }
        subs.forEach(context.insert)
        let items = doc.items.map { i in
            BucketItem(bucket: i.bucket, name: i.name, rateCents: i.rateCents, unit: i.unit, isActive: i.isActive,
                       source: i.source, notes: i.notes, category: i.category, link: i.link,
                       calcInputs: i.calcInputs?.data, sortOrder: i.sortOrder)
        }
        items.forEach(context.insert)
        for (i, record) in doc.items.enumerated() {
            if let s = record.subcontractorIndex { items[i].subcontractor = subs[s] }
            items[i].unitCode = record.unitCode; items[i].make = record.make; items[i].model = record.model
            items[i].year = record.year; items[i].serial = record.serial
        }
        for l in doc.loadouts ?? [] {
            let loadout = Loadout(name: l.name, notes: l.notes, sortOrder: l.sortOrder)
            context.insert(loadout)
            loadout.members = l.memberIndexes.map { items[$0] }
        }
        for p in doc.projects {
            let project = Project(name: p.name, client: p.client, date: p.date, hours: p.hours, multiplier: p.multiplier,
                                  markupPct: p.markupPct, minimumJobCents: p.minimumJobCents, actualHours: p.actualHours,
                                  notes: p.notes)
            project.isTemplate = p.isTemplate ?? false
            project.crewName = p.crewName
            context.insert(project)
            project.lines = p.lines.map { l in
                ProjectLine(item: l.itemIndex.map { items[$0] }, bucket: l.bucket, name: l.name, unit: l.unit,
                            rateCents: l.rateCents, isOn: l.isOn, qty: l.qty, actualQty: l.actualQty)
            }
        }
        try context.save()
        return AppSettings(billableHoursPerYear: doc.settings.billableHoursPerYear, laborBurdenPct: doc.settings.laborBurdenPct,
                        markupPct: doc.settings.markupPct, minimumJobCents: doc.settings.minimumJobCents,
                        costOfMoneyPct: doc.settings.costOfMoneyPct)
    }

    // MARK: - Add rows (merge)

    struct MergeResult: Equatable, Sendable {
        var added = 0
        var updated = 0
        var unchanged = 0
        var subcontractors = 0
        var loadouts = 0
    }

    /// Adds or updates rows from a file without deleting anything (DECISIONS 55): a row whose bucket and
    /// name match an existing row (case- and whitespace-insensitive) has its rate, unit, source, notes and
    /// calculator inputs replaced by the file's, unless nothing differs; any other file row is added. Rows
    /// that are not in the file are untouched, and the file's projects and settings are ignored. This is how
    /// a researched catalog both joins and corrects rows the owner typed from memory.
    @MainActor
    static func mergeItems(_ data: Data, into context: ModelContext) throws -> MergeResult {
        let doc = try decoder().decode(TransferDocument.self, from: data)
        guard doc.formatVersion == TransferDocument.currentFormatVersion else {
            throw TransferError.unsupportedFormat(doc.formatVersion)
        }
        var existing = try context.fetch(FetchDescriptor<BucketItem>())
        var result = MergeResult()
        // Subcontractors by name: update contact details the file provides, add the rest (DECISIONS 60).
        var subs = try context.fetch(FetchDescriptor<Subcontractor>())
        var fileSubs: [Subcontractor] = []
        for s in doc.subcontractors ?? [] {
            if let match = subs.first(where: { normalized($0.name) == normalized(s.name) }) {
                if let v = s.contact { match.contact = v }
                if let v = s.phone { match.phone = v }
                if let v = s.email { match.email = v }
                if let v = s.notes { match.notes = v }
                fileSubs.append(match)
            } else {
                let sub = Subcontractor(name: s.name, contact: s.contact, phone: s.phone, email: s.email, notes: s.notes,
                                        isActive: s.isActive, sortOrder: Subcontractor.nextSortOrder(context: context) + subs.count)
                context.insert(sub)
                subs.append(sub)
                fileSubs.append(sub)
                result.subcontractors += 1
            }
        }
        var merged: [BucketItem] = []
        for i in doc.items {
            let key = normalized(i.name)
            let sub = i.subcontractorIndex.flatMap { $0 < fileSubs.count ? fileSubs[$0] : nil }
            // Identical units (two "Stihl 500i") are told apart by unit code (DECISIONS 66): a coded file row matches the
            // row with that code, else an uncoded row of that name (which then gets the code). An uncoded file row matches
            // an uncoded row of that name, else the one coded row of that name; with several coded units it is skipped.
            let code = i.unitCode.map(normalized).flatMap { $0.isEmpty ? nil : $0 }
            let sameName = existing.filter { $0.bucket == i.bucket && normalized($0.name) == key }
            let uncoded = sameName.first { ($0.unitCode ?? "").isEmpty }
            let coded = sameName.filter { !($0.unitCode ?? "").isEmpty }
            let match: BucketItem?
            if let code {
                match = existing.first { $0.bucket == i.bucket && $0.unitCode.map(normalized) == code } ?? uncoded
            } else if let uncoded {
                match = uncoded
            } else if coded.count > 1 {
                result.unchanged += 1
                continue
            } else {
                match = coded.first
            }
            if let match {
                merged.append(match)
                if let sub { match.subcontractor = sub }
                // A file may archive a row it names; it never un-archives one (DECISIONS 55).
                if !i.isActive && match.isActive { match.isActive = false; result.updated += 1; continue }
                let unit = i.bucket.fixedUnit ?? (i.unit.isEmpty ? match.unit : i.unit)
                let calc = i.calcInputs?.data
                let sameCalc = i.calcInputs == nil || match.calcInputs.flatMap(JSONValue.from) == i.calcInputs
                let same = match.rateCents == i.rateCents && match.unit == unit && match.source == (i.source ?? match.source)
                    && match.notes == (i.notes ?? match.notes) && match.category == (i.category ?? match.category)
                    && match.link == (i.link ?? match.link) && sameCalc
                    && match.unitCode == (i.unitCode ?? match.unitCode) && match.make == (i.make ?? match.make)
                    && match.model == (i.model ?? match.model) && match.year == (i.year ?? match.year) && match.serial == (i.serial ?? match.serial)
                if same { result.unchanged += 1; continue }
                match.rateCents = i.rateCents
                match.unit = unit
                if let source = i.source { match.source = source }
                if let notes = i.notes { match.notes = notes }
                if let category = i.category { match.category = category }
                if let link = i.link { match.link = link }
                if let calc { match.calcInputs = calc }
                if let v = i.unitCode { match.unitCode = v }
                if let v = i.make { match.make = v }
                if let v = i.model { match.model = v }
                if let v = i.year { match.year = v }
                if let v = i.serial { match.serial = v }
                result.updated += 1
                continue
            }
            let order = (existing.filter { $0.bucket == i.bucket }.map(\.sortOrder).max() ?? -1) + 1
            let item = BucketItem(bucket: i.bucket, name: i.name, rateCents: i.rateCents, unit: i.unit, isActive: i.isActive,
                                  source: i.source, notes: i.notes, category: i.category, link: i.link,
                                  calcInputs: i.calcInputs?.data, sortOrder: order)
            item.subcontractor = sub
            item.unitCode = i.unitCode; item.make = i.make; item.model = i.model; item.year = i.year; item.serial = i.serial
            context.insert(item)
            existing.append(item)
            merged.append(item)
            result.added += 1
        }
        // Loadouts by name: members resolved through the file's item positions (DECISIONS 62).
        var loadouts = try context.fetch(FetchDescriptor<Loadout>())
        for l in doc.loadouts ?? [] {
            let members = l.memberIndexes.compactMap { $0 < merged.count ? merged[$0] : nil }
            if let match = loadouts.first(where: { normalized($0.name) == normalized(l.name) }) {
                match.members = members
                if let v = l.notes { match.notes = v }
            } else {
                let loadout = Loadout(name: l.name, notes: l.notes, sortOrder: Loadout.nextSortOrder(context: context) + loadouts.count)
                context.insert(loadout)
                loadout.members = members
                loadouts.append(loadout)
                result.loadouts += 1
            }
        }
        try context.save()
        return result
    }

    static func normalized(_ name: String) -> String {
        name.lowercased().split(whereSeparator: { $0.isWhitespace || $0 == "-" || $0 == "_" }).joined(separator: " ")
    }
}
