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

    private let container: ModelContainer
    private var context: ModelContext { container.mainContext }

    init(container: ModelContainer) {
        self.container = container
        // Screenshot hook (DECISIONS 48): BUCKETS_SCREEN=buckets|projects|project|settings.
        switch ProcessInfo.processInfo.environment["BUCKETS_SCREEN"] {
        case "projects": sidebar = .projects
        case "project":
            sidebar = .projects
            let projects = (try? context.fetch(FetchDescriptor<Project>(sortBy: [SortDescriptor(\.date, order: .reverse)]))) ?? []
            selectedProject = projects.first?.persistentModelID
        default: break
        }
    }

    var wantsSettingsWindow: Bool { ProcessInfo.processInfo.environment["BUCKETS_SCREEN"] == "settings" }

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
