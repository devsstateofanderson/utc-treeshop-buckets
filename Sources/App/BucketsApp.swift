import SwiftUI
import SwiftData
import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationWillFinishLaunching(_ notification: Notification) {
        // Screenshot hook (DECISIONS 48): BUCKETS_APPEARANCE=light|dark forces the appearance.
        if let mode = ProcessInfo.processInfo.environment["BUCKETS_APPEARANCE"] {
            NSApp.appearance = NSAppearance(named: mode == "dark" ? .darkAqua : .aqua)
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}

@main
struct BucketsApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    private let container: ModelContainer
    @State private var appState: AppState

    init() {
        AppSettings.register()
        do {
            container = try Store.container()
        } catch {
            fatalError("Buckets could not open its store at \(Store.url.path): \(error)")
        }
        _appState = State(initialValue: AppState(container: container))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
                .frame(minWidth: 1000, minHeight: 640)
        }
        .modelContainer(container)
        .defaultSize(width: 1180, height: 760)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button(appState.sidebar == .projects ? "New Project" : "New Row") { appState.createNew() }
                    .keyboardShortcut("n", modifiers: .command)
                Button("Duplicate Project") { appState.duplicateSelectedProject() }
                    .keyboardShortcut("d", modifiers: .command)
                    .disabled(appState.sidebar != .projects || appState.selectedProject == nil)
            }
        }

        Settings {
            SettingsScreen()
                .environment(appState)
        }
        .modelContainer(container)
    }
}
