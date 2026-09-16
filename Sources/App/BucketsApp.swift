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
                try? await Task.sleep(for: .seconds(1))
                // BUCKETS_WINDOW_SIZE=1180x1500 makes the main window that tall first, so a long screen
                // renders past the fold (the window may exceed the display; the render is offscreen).
                if let spec = ProcessInfo.processInfo.environment["BUCKETS_WINDOW_SIZE"] {
                    let size = spec.split(separator: "x").compactMap { Double($0) }
                    if size.count == 2, let window = NSApp.windows.first(where: { !$0.title.isEmpty }) {
                        window.setContentSize(NSSize(width: size[0], height: size[1]))
                    }
                }
                try? await Task.sleep(for: .seconds(2))
                Self.renderWindows(to: URL(fileURLWithPath: dir, isDirectory: true))
                NSApp.terminate(nil)
            }
        }
    }

    /// Screenshot hook: builds the Settings screen for `renderWindows` (set by `BucketsApp` in a snapshot run).
    @MainActor static var settingsSnapshot: (() -> AnyView)?

    /// Writes `main.png` for the titled window, `settings.png` when the Settings window (⌘,) is open, and
    /// `sheet.png` for a sheet attached to the main window. Windows are drawn from their frame view (title bar
    /// and toolbar included); a sheet from its content view. The Settings scene's window is hosted by SwiftUI's
    /// own container on macOS 26, which has no drawable layer contents while the app is in the background, so
    /// that screen is drawn through a classic `NSHostingView` in a stand-in window of the same size and appearance.
    @MainActor
    static func renderWindows(to dir: URL) {
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        for window in NSApp.windows where window.isVisible {
            if window.sheetParent != nil {
                render(window.contentView, background: window, to: dir.appending(path: "sheet.png"))
            } else if window.isSettingsWindow {
                guard let make = settingsSnapshot else { continue }
                let size = window.contentLayoutRect.size
                let standIn = NSWindow(contentRect: NSRect(origin: .zero, size: size),
                                       styleMask: [.titled, .closable, .miniaturizable], backing: .buffered, defer: false)
                standIn.title = window.title
                standIn.appearance = window.effectiveAppearance
                standIn.contentView = NSHostingView(rootView: make())
                standIn.setContentSize(size)
                standIn.layoutIfNeeded()
                render(standIn.contentView?.superview, background: standIn, to: dir.appending(path: "settings.png"))
            } else if !window.title.isEmpty {
                render(window.contentView?.superview, background: window, to: dir.appending(path: "main.png"))
            }
        }
    }

    @MainActor
    private static func render(_ view: NSView?, background window: NSWindow, to url: URL) {
        guard let view else { return }
        view.layoutSubtreeIfNeeded()
        guard !view.bounds.isEmpty, let rep = view.bitmapImageRepForCachingDisplay(in: view.bounds) else { return }
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
        guard let png = rep.representation(using: .png, properties: [:]) else { return }
        try? png.write(to: url)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}

extension NSWindow {
    /// The SwiftUI `Settings` scene's window (⌘,), by its identifier, or by title as a fallback.
    var isSettingsWindow: Bool {
        if let id = identifier?.rawValue, id.localizedCaseInsensitiveContains("settings") { return true }
        return title == "Settings" || title.hasSuffix(" Settings")
    }
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
        let state = AppState(container: container)
        // Maintenance hook (DECISIONS 58): BUCKETS_MERGE_FILE=<catalog.json> runs Settings → Add or Update Rows
        // on launch, in the app's own container, and logs the result. Used to load researched catalogs.
        if let path = ProcessInfo.processInfo.environment["BUCKETS_MERGE_FILE"], !path.isEmpty {
            do {
                let result = try Transfer.mergeItems(try Data(contentsOf: URL(fileURLWithPath: path)), into: container.mainContext)
                FileHandle.standardError.write(Data("BUCKETS_MERGE_FILE: added \(result.added), updated \(result.updated), unchanged \(result.unchanged)\n".utf8))
            } catch {
                FileHandle.standardError.write(Data("BUCKETS_MERGE_FILE failed: \(error)\n".utf8))
            }
        }
        // Maintenance hook (DECISIONS 59): BUCKETS_EXPORT_FILE=<path.json> writes Settings → Export JSON on launch.
        if let path = ProcessInfo.processInfo.environment["BUCKETS_EXPORT_FILE"], !path.isEmpty {
            do {
                let data = try Transfer.exportJSON(from: container.mainContext, settings: AppSettings.current(), exportedAt: .now)
                try data.write(to: URL(fileURLWithPath: path), options: .atomic)
                FileHandle.standardError.write(Data("BUCKETS_EXPORT_FILE: wrote \(data.count) bytes to \(path)\n".utf8))
            } catch {
                FileHandle.standardError.write(Data("BUCKETS_EXPORT_FILE failed: \(error)\n".utf8))
            }
        }
        _appState = State(initialValue: state)
        // Screenshot hook: the offscreen render draws the Settings screen itself (see AppDelegate.renderWindows).
        if ProcessInfo.processInfo.environment["BUCKETS_SNAPSHOT_DIR"] != nil {
            let container = container
            AppDelegate.settingsSnapshot = { AnyView(SettingsScreen().environment(state).modelContainer(container)) }
        }
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
                Button(appState.newItemTitle) { appState.createNew() }
                    .keyboardShortcut("n", modifiers: .command)
                Button("Duplicate") { appState.duplicateSelection() }
                    .keyboardShortcut("d", modifiers: .command)
                    .disabled(!appState.canDuplicate)
            }
        }

        Settings {
            SettingsScreen()
                .environment(appState)
        }
        .modelContainer(container)
    }
}
