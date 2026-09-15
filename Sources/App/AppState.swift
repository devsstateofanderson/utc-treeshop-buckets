import Foundation
import SwiftData
import Observation

/// Which list the sidebar shows: one of the five buckets, or the projects.
enum SidebarItem: Hashable {
    case bucket(Bucket)
    case projects

    static let all: [SidebarItem] = Bucket.allCases.map { .bucket($0) } + [.projects]
}

/// Window-level navigation state plus the two menu actions (⌘N, ⌘D). One per window.
@MainActor
@Observable
final class AppState {
    var sidebar: SidebarItem? = .bucket(.labor)
    var selectedItem: PersistentIdentifier?
    var selectedProject: PersistentIdentifier?
    /// Screenshot hook: the detail Form opens its "Calculate…" sheet once, then clears this.
    var wantsCalcSheet = false
    let wantsSettingsWindow: Bool

    private let container: ModelContainer
    private var context: ModelContext { container.mainContext }

    /// `screen` is the BUCKETS_SCREEN screenshot hook (DECISIONS 48): buckets | labor | equipment | materials |
    /// consumables | overhead | laborcalc | equipmentcalc | projects | project | settings. It only selects; it never creates data.
    init(container: ModelContainer, screen: String? = ProcessInfo.processInfo.environment["BUCKETS_SCREEN"]) {
        self.container = container
        wantsSettingsWindow = screen == "settings"
        switch screen {
        case "projects": sidebar = .projects
        case "project", "actuals":
            // Opens the oldest project by date (the fixture's "Oak removal", the BRIEF §3.3 worked example).
            sidebar = .projects
            let projects = (try? context.fetch(FetchDescriptor<Project>(sortBy: [SortDescriptor(\.date, order: .forward)]))) ?? []
            selectedProject = projects.first?.persistentModelID
        case "buckets": selectFirstRow(in: .labor)
        case "laborcalc":
            selectFirstRow(in: .labor)
            wantsCalcSheet = selectedItem != nil
        case "equipmentcalc":
            selectFirstRow(in: .equipment)
            wantsCalcSheet = selectedItem != nil
        case let name?:
            if let bucket = Bucket(rawValue: name) { selectFirstRow(in: bucket) }
        default: break
        }
    }

    /// Shows `bucket` with its first row (by `sortOrder`, then name) selected so the Form is visible.
    func selectFirstRow(in bucket: Bucket) {
        sidebar = .bucket(bucket)
        let items = (try? context.fetch(FetchDescriptor<BucketItem>())) ?? []
        selectedItem = items.rows(in: bucket).first?.persistentModelID
    }

    var selectedBucket: Bucket? {
        if case .bucket(let b) = sidebar { return b }
        return nil
    }

    /// ⌘N: a new row in the selected bucket, or a new project (DECISIONS 42).
    func createNew() {
        switch sidebar {
        case .bucket(let bucket): newItem(in: bucket)
        case .projects: newProject()
        case nil: break
        }
    }

    func newItem(in bucket: Bucket) {
        let item = BucketItem(bucket: bucket, name: "", sortOrder: BucketItem.nextSortOrder(in: bucket, context: context))
        context.insert(item)
        save()
        selectedItem = item.persistentModelID
    }

    @discardableResult
    func newProject() -> Project {
        let items = (try? context.fetch(FetchDescriptor<BucketItem>())) ?? []
        let project = Project.make(date: .now, items: items, settings: AppSettings.current())
        context.insert(project)
        save()
        selectedProject = project.persistentModelID
        return project
    }

    /// Copies a bucket row (name + " copy", same rate, unit, calculator inputs, source) so another unit is one click.
    func duplicate(_ item: BucketItem) {
        let copy = BucketItem(bucket: item.bucket, name: item.name + " copy", rateCents: item.rateCents, unit: item.unit,
                              isActive: item.isActive, source: item.source, notes: item.notes, category: item.category,
                              link: item.link, calcInputs: item.calcInputs,
                              sortOrder: BucketItem.nextSortOrder(in: item.bucket, context: context))
        context.insert(copy)
        save()
        selectedItem = copy.persistentModelID
    }

    func duplicateSelectedProject() {
        guard let id = selectedProject, let project = context.model(for: id) as? Project else { return }
        let copy = project.duplicate(date: .now)
        context.insert(copy)
        save()
        selectedProject = copy.persistentModelID
    }

    func delete(_ project: Project) {
        if selectedProject == project.persistentModelID { selectedProject = nil }
        context.delete(project)
        save()
    }

    /// Delete only when no project references the row; otherwise the caller archives (DECISIONS 22).
    func delete(_ item: BucketItem) {
        guard item.referenceCount == 0 else { return }
        if selectedItem == item.persistentModelID { selectedItem = nil }
        context.delete(item)
        save()
    }

    func save() {
        do { try context.save() } catch { assertionFailure("save failed: \(error)") }
    }
}
