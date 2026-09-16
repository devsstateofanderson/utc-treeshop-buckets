import SwiftUI
import SwiftData

/// One window, three columns (DECISIONS 33): sidebar → list → detail.
struct RootView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        @Bindable var appState = appState
        NavigationSplitView {
            List(selection: $appState.sidebar) {
                Section("Buckets") {
                    ForEach(Bucket.allCases, id: \.self) { bucket in
                        if bucket == .subcontractors {
                            Label(bucket.title, systemImage: bucket.symbol).tag(SidebarItem.subcontractors)
                        } else {
                            Label(bucket.title, systemImage: bucket.symbol).tag(SidebarItem.bucket(bucket))
                        }
                    }
                }
                Section("Projects") {
                    Label("Projects", systemImage: "list.clipboard").tag(SidebarItem.projects)
                    Label("Packages", systemImage: "shippingbox.and.arrow.backward").tag(SidebarItem.packages)
                    Label("Loadouts", systemImage: "person.3").tag(SidebarItem.loadouts)
                }
            }
            .navigationSplitViewColumnWidth(min: 170, ideal: 190, max: 240)
        } content: {
            switch appState.sidebar {
            case .bucket(let bucket): BucketTableView(bucket: bucket)
            case .subcontractors: SubcontractorsListView()
            case .projects: ProjectsListView(templates: false)
            case .packages: ProjectsListView(templates: true)
            case .loadouts: LoadoutsListView()
            case nil: ContentUnavailableView("Pick a bucket", systemImage: "sidebar.left")
            }
        } detail: {
            switch appState.sidebar {
            case .bucket: BucketItemDetail()
            case .subcontractors: SubcontractorDetail()
            case .projects, .packages: ProjectScreen()
            case .loadouts: LoadoutDetail()
            case nil: EmptyView()
            }
        }
        .task {
            if appState.wantsSettingsWindow { openSettings() }
        }
    }
}

extension Bucket {
    var symbol: String {
        switch self {
        case .labor: "person.2"
        case .equipment: "truck.box"
        case .materials: "leaf"
        case .consumables: "shippingbox"
        case .subcontractors: "person.crop.rectangle.stack"
        case .overhead: "building.2"
        }
    }
}
