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
    var data: Data? { try? JSONEncoder().encode(self) }
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
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        e.dateEncodingStrategy = .iso8601
        return e
    }

    static func decoder() -> JSONDecoder {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }

    @MainActor
    static func document(from context: ModelContext, settings: Settings, exportedAt: Date) throws -> TransferDocument {
        let items = try context.fetch(FetchDescriptor<BucketItem>())
            .sorted { ($0.bucket.index, $0.sortOrder, $0.name) < ($1.bucket.index, $1.sortOrder, $1.name) }
        let index = Dictionary(uniqueKeysWithValues: items.enumerated().map { ($1.persistentModelID, $0) })
        let projects = try context.fetch(FetchDescriptor<Project>())
            .sorted { ($0.date, $0.name) < ($1.date, $1.name) }
        return TransferDocument(
            formatVersion: TransferDocument.currentFormatVersion,
            exportedAt: exportedAt,
            settings: .init(billableHoursPerYear: settings.billableHoursPerYear, laborBurdenPct: settings.laborBurdenPct,
                            markupPct: settings.markupPct, minimumJobCents: settings.minimumJobCents,
                            costOfMoneyPct: settings.costOfMoneyPct),
            items: items.map { i in
                .init(bucket: i.bucket, name: i.name, rateCents: i.rateCents, unit: i.unit, isActive: i.isActive,
                      source: i.source, notes: i.notes, calcInputs: i.calcInputs.flatMap(JSONValue.from), sortOrder: i.sortOrder)
            },
            projects: projects.map { p in
                .init(name: p.name, client: p.client, date: p.date, hours: p.hours, multiplier: p.multiplier,
                      markupPct: p.markupPct, minimumJobCents: p.minimumJobCents, actualHours: p.actualHours, notes: p.notes,
                      lines: p.sortedLines.map { l in
                          .init(itemIndex: l.item.flatMap { index[$0.persistentModelID] }, bucket: l.bucket, name: l.name,
                                unit: l.unit, rateCents: l.rateCents, isOn: l.isOn, qty: l.qty, actualQty: l.actualQty)
                      })
            })
    }

    @MainActor
    static func exportJSON(from context: ModelContext, settings: Settings, exportedAt: Date) throws -> Data {
        try encoder().encode(try document(from: context, settings: settings, exportedAt: exportedAt))
    }

    /// Replaces every row and project in `context` with the file's contents and returns the file's settings.
    @MainActor
    @discardableResult
    static func importJSON(_ data: Data, into context: ModelContext) throws -> Settings {
        let doc = try decoder().decode(TransferDocument.self, from: data)
        guard doc.formatVersion == TransferDocument.currentFormatVersion else {
            throw TransferError.unsupportedFormat(doc.formatVersion)
        }
        for line in doc.projects.flatMap(\.lines) {
            if let i = line.itemIndex, !(0..<doc.items.count).contains(i) { throw TransferError.badItemIndex(i) }
        }
        // Per-object deletes: a batch delete cannot honor the nullify inverse on ProjectLine.item.
        for project in try context.fetch(FetchDescriptor<Project>()) { context.delete(project) }
        for line in try context.fetch(FetchDescriptor<ProjectLine>()) { context.delete(line) }
        for item in try context.fetch(FetchDescriptor<BucketItem>()) { context.delete(item) }
        try context.save()

        let items = doc.items.map { i in
            BucketItem(bucket: i.bucket, name: i.name, rateCents: i.rateCents, unit: i.unit, isActive: i.isActive,
                       source: i.source, notes: i.notes, calcInputs: i.calcInputs?.data, sortOrder: i.sortOrder)
        }
        items.forEach(context.insert)
        for p in doc.projects {
            let project = Project(name: p.name, client: p.client, date: p.date, hours: p.hours, multiplier: p.multiplier,
                                  markupPct: p.markupPct, minimumJobCents: p.minimumJobCents, actualHours: p.actualHours,
                                  notes: p.notes)
            context.insert(project)
            project.lines = p.lines.map { l in
                ProjectLine(item: l.itemIndex.map { items[$0] }, bucket: l.bucket, name: l.name, unit: l.unit,
                            rateCents: l.rateCents, isOn: l.isOn, qty: l.qty, actualQty: l.actualQty)
            }
        }
        try context.save()
        return Settings(billableHoursPerYear: doc.settings.billableHoursPerYear, laborBurdenPct: doc.settings.laborBurdenPct,
                        markupPct: doc.settings.markupPct, minimumJobCents: doc.settings.minimumJobCents,
                        costOfMoneyPct: doc.settings.costOfMoneyPct)
    }
}
