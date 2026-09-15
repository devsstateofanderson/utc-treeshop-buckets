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

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Screenshot hook: come to the front so captures show the key-window appearance (selection, switches).
        if ProcessInfo.processInfo.environment["BUCKETS_APPEARANCE"] != nil { NSApp.activate() }
        // Screenshot hook: BUCKETS_SNAPSHOT_DIR=<dir> renders each window's content offscreen once the UI has
        // settled, then quits. Unlike screencapture it works while the screen is locked and it captures an open sheet.
        if let dir = ProcessInfo.processInfo.environment["BUCKETS_SNAPSHOT_DIR"], !dir.isEmpty {
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(3))
                Self.renderWindows(to: URL(fileURLWithPath: dir, isDirectory: true))
                NSApp.terminate(nil)
            }
        }
    }

    /// Writes `main.png` for the titled window and `sheet.png` for a sheet attached to it.
    @MainActor
    static func renderWindows(to dir: URL) {
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        for window in NSApp.windows where window.isVisible {
            let name: String
            if window.sheetParent != nil { name = "sheet" } else if !window.title.isEmpty { name = "main" } else { continue }
            guard let view = window.contentView, !view.bounds.isEmpty,
                  let rep = view.bitmapImageRepForCachingDisplay(in: view.bounds) else { continue }
            view.cacheDisplay(in: view.bounds, to: rep)
            // The window paints its own background behind the content view; composite it underneath.
            if let context = NSGraphicsContext(bitmapImageRep: rep) {
                NSGraphicsContext.saveGraphicsState()
                NSGraphicsContext.current = context
                window.effectiveAppearance.performAsCurrentDrawingAppearance {
                    window.backgroundColor.setFill()
                    NSRect(x: 0, y: 0, width: rep.pixelsWide, height: rep.pixelsHigh).fill(using: .destinationOver)
                }
                NSGraphicsContext.restoreGraphicsState()
            }
            guard let png = rep.representation(using: .png, properties: [:]) else { continue }
            try? png.write(to: dir.appending(path: "\(name).png"))
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
