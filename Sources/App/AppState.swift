import Foundation
import SwiftData
import Observation

/// Which list the sidebar shows (DECISIONS 33, 60–62).
enum SidebarItem: Hashable {
    case company
    case bucket(Bucket)
    case subcontractors
    case projects
    case packages
    case loadouts

    /// The five row buckets in the sidebar's Buckets section; Subcontractors has its own screen.
    static let rowBuckets: [Bucket] = Bucket.allCases.filter { $0 != .subcontractors }
}

/// Window-level navigation state plus the menu actions (⌘N, ⌘D). One per window.
@MainActor
@Observable
final class AppState {
    var sidebar: SidebarItem? = .bucket(.labor)
    var selectedItem: PersistentIdentifier?
    var selectedProject: PersistentIdentifier?
    var selectedSubcontractor: PersistentIdentifier?
    var selectedLoadout: PersistentIdentifier?
    /// Screenshot hook: the detail Form opens its "Calculate…" sheet once, then clears this.
    var wantsCalcSheet = false
    let wantsSettingsWindow: Bool
    /// The Buckets table's "Show" menu (DECISIONS 72); window-level so the readiness view can set it.
    var reviewFilter: ReviewFilter = .all

    private let container: ModelContainer
    private var context: ModelContext { container.mainContext }

    /// `screen` is the BUCKETS_SCREEN screenshot hook (DECISIONS 48): buckets | labor | equipment | materials |
    /// consumables | overhead | subcontractors | laborcalc | equipmentcalc | projects | project | actuals | packages |
    /// loadouts | settings. It only selects; it never creates data.
    init(container: ModelContainer, screen: String? = ProcessInfo.processInfo.environment["BUCKETS_SCREEN"]) {
        self.container = container
        wantsSettingsWindow = screen == "settings"
        switch screen {
        case "projects": sidebar = .projects
        case "project", "actuals":
            // Opens the oldest project by date (the fixture's "Oak removal", the BRIEF §3.3 worked example).
            sidebar = .projects
            let projects = ((try? context.fetch(FetchDescriptor<Project>(sortBy: [SortDescriptor(\.date, order: .forward)]))) ?? [])
                .filter { !$0.isTemplate }
            selectedProject = projects.first?.persistentModelID
        case "packages":
            sidebar = .packages
            let packages = ((try? context.fetch(FetchDescriptor<Project>(sortBy: [SortDescriptor(\.name)]))) ?? []).filter(\.isTemplate)
            selectedProject = packages.first?.persistentModelID
        case "loadouts":
            sidebar = .loadouts
            selectedLoadout = ((try? context.fetch(FetchDescriptor<Loadout>(sortBy: [SortDescriptor(\.sortOrder)]))) ?? []).first?.persistentModelID
        case "company": sidebar = .company
        case "subcontractors":
            sidebar = .subcontractors
            selectedSubcontractor = ((try? context.fetch(FetchDescriptor<Subcontractor>(sortBy: [SortDescriptor(\.sortOrder)]))) ?? []).first?.persistentModelID
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
        guard bucket != .subcontractors else { sidebar = .subcontractors; return }
        sidebar = .bucket(bucket)
        let items = (try? context.fetch(FetchDescriptor<BucketItem>())) ?? []
        selectedItem = items.rows(in: bucket).first?.persistentModelID
    }

    var selectedBucket: Bucket? {
        if case .bucket(let b) = sidebar { return b }
        return nil
    }

    /// Readiness → "Show": the Buckets screen filtered to one unresolved group, opened on the first bucket
    /// that has such a row (DECISIONS 73).
    func showUnresolved(_ reason: UnresolvedReason, in bucket: Bucket?) {
        reviewFilter = .reason(reason)
        selectedItem = nil
        switch bucket {
        case .subcontractors?: sidebar = .subcontractors
        case let b?: sidebar = .bucket(b)
        case nil: sidebar = .bucket(.labor)
        }
    }

    /// What ⌘N creates on the current screen (DECISIONS 42).
    var newItemTitle: String {
        switch sidebar {
        case .bucket: "New Row"
        case .subcontractors: "New Subcontractor"
        case .projects: "New Project"
        case .packages: "New Package"
        case .loadouts: "New Loadout"
        case .company: "Add Document…"
        case nil: "New"
        }
    }

    var canDuplicate: Bool {
        switch sidebar {
        case .projects, .packages: selectedProject != nil
        case .loadouts: selectedLoadout != nil
        case .bucket: selectedItem != nil
        default: false
        }
    }

    func createNew() {
        switch sidebar {
        case .bucket(let bucket): newItem(in: bucket)
        case .subcontractors: newSubcontractor()
        case .projects: newProject()
        case .packages: newPackage()
        case .loadouts: newLoadout()
        case .company: wantsDocumentPicker = true
        case nil: break
        }
    }

    /// ⌘N on the Company screen asks the documents view to open its file picker.
    var wantsDocumentPicker = false

    /// ⌘D on whatever the current screen selects.
    func duplicateSelection() {
        switch sidebar {
        case .projects, .packages: duplicateSelectedProject()
        case .loadouts: if let l = selectedLoadoutModel { duplicate(l) }
        case .bucket: if let id = selectedItem, let item = context.model(for: id) as? BucketItem { duplicate(item) }
        default: break
        }
    }

    // MARK: Rows

    func newItem(in bucket: Bucket) {
        let item = BucketItem(bucket: bucket, name: "", sortOrder: BucketItem.nextSortOrder(in: bucket, context: context))
        context.insert(item)
        save()
        selectedItem = item.persistentModelID
    }

    /// Copies a bucket row (name + " copy", same rate, unit, calculator inputs, source) so another unit is one click.
    func duplicate(_ item: BucketItem) {
        let copy = BucketItem(bucket: item.bucket, name: item.name + " copy", rateCents: item.rateCents, unit: item.unit,
                              isActive: item.isActive, source: item.source, notes: item.notes, category: item.category,
                              link: item.link, calcInputs: item.calcInputs,
                              sortOrder: BucketItem.nextSortOrder(in: item.bucket, context: context))
        copy.subcontractor = item.subcontractor
        // Another unit of the same thing: same make/model/year, its own code, no serial yet (DECISIONS 66).
        copy.make = item.make; copy.model = item.model; copy.year = item.year; copy.serial = nil
        if item.bucket == .equipment {
            let prefix = item.unitCode.flatMap { code -> String? in
                let parts = code.split(separator: "-"); return parts.count == 2 ? String(parts[0]) : nil
            } ?? BucketItem.nextUnitCodePrefixFallback(item)
            copy.unitCode = BucketItem.nextUnitCode(prefix: prefix, among: allItems)
        }
        context.insert(copy)
        save()
        selectedItem = copy.persistentModelID
    }

    /// Delete only when no project references the row; otherwise the caller archives (DECISIONS 22).
    func delete(_ item: BucketItem) {
        guard item.referenceCount == 0 else { return }
        if selectedItem == item.persistentModelID { selectedItem = nil }
        context.delete(item)
        save()
    }

    // MARK: Subcontractors (DECISIONS 60)

    var selectedSubcontractorModel: Subcontractor? {
        guard let id = selectedSubcontractor, let sub = context.model(for: id) as? Subcontractor, !sub.isDeleted else { return nil }
        return sub
    }

    func newSubcontractor() {
        let sub = Subcontractor(name: "", sortOrder: Subcontractor.nextSortOrder(context: context))
        context.insert(sub)
        save()
        selectedSubcontractor = sub.persistentModelID
    }

    /// A new priced service under `sub`.
    @discardableResult
    func newService(for sub: Subcontractor) -> BucketItem {
        let service = BucketItem(bucket: .subcontractors, name: "", unit: "each",
                                 sortOrder: (sub.services.map(\.sortOrder).max() ?? -1) + 1)
        service.subcontractor = sub
        context.insert(service)
        save()
        return service
    }

    /// Delete only when none of the sub's services is on a project; otherwise the caller archives.
    func delete(_ sub: Subcontractor) {
        guard sub.referenceCount == 0 else { return }
        if selectedSubcontractor == sub.persistentModelID { selectedSubcontractor = nil }
        context.delete(sub)
        save()
    }

    // MARK: Projects and packages (DECISIONS 61)

    @discardableResult
    func newProject() -> Project {
        let project = Project.make(date: .now, items: allItems, settings: AppSettings.current())
        context.insert(project)
        save()
        selectedProject = project.persistentModelID
        return project
    }

    @discardableResult
    func newPackage() -> Project {
        let package = Project.make(name: "New package", date: .now, items: allItems, settings: AppSettings.current())
        package.isTemplate = true
        context.insert(package)
        save()
        selectedProject = package.persistentModelID
        return package
    }

    /// Use Package: a new project from the package at today's date and rates; shows it under Projects.
    func usePackage(_ package: Project) {
        let project = package.instantiate(date: .now, items: allItems, settings: AppSettings.current())
        context.insert(project)
        save()
        sidebar = .projects
        selectedProject = project.persistentModelID
    }

    /// Save as Package: the project copied as a template; shows it under Packages.
    func saveAsPackage(_ project: Project) {
        let package = project.asPackage(date: .now)
        context.insert(package)
        save()
        sidebar = .packages
        selectedProject = package.persistentModelID
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

    // MARK: Loadouts (DECISIONS 62)

    var selectedLoadoutModel: Loadout? {
        guard let id = selectedLoadout, let loadout = context.model(for: id) as? Loadout, !loadout.isDeleted else { return nil }
        return loadout
    }

    func newLoadout() {
        let loadout = Loadout(name: "", sortOrder: Loadout.nextSortOrder(context: context))
        context.insert(loadout)
        save()
        selectedLoadout = loadout.persistentModelID
    }

    func duplicate(_ loadout: Loadout) {
        let copy = loadout.copy(named: loadout.name + " copy", sortOrder: Loadout.nextSortOrder(context: context))
        context.insert(copy)
        save()
        selectedLoadout = copy.persistentModelID
    }

    func delete(_ loadout: Loadout) {
        if selectedLoadout == loadout.persistentModelID { selectedLoadout = nil }
        context.delete(loadout)
        save()
    }

    // MARK: Shared

    private var allItems: [BucketItem] { (try? context.fetch(FetchDescriptor<BucketItem>())) ?? [] }

    func save() {
        do { try context.save() } catch { assertionFailure("save failed: \(error)") }
    }
}
