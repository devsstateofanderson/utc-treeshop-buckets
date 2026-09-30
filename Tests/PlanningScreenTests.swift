import XCTest
import SwiftData
import SwiftUI
import AppKit
@testable import Buckets

/// The reserved Planning section (DECISIONS 90): a sidebar item and an under-construction screen, no data.
@MainActor
final class PlanningScreenTests: XCTestCase {
    func testTheScreenHookOpensPlanningAndCreatesNothing() throws {
        let container = try Store.inMemoryContainer()
        let state = AppState(container: container, screen: "planning")
        XCTAssertEqual(state.sidebar, .planning)
        XCTAssertFalse(state.canCreate, "⌘N has nothing to create on Planning")
        XCTAssertFalse(state.canDuplicate)
        state.createNew()
        state.duplicateSelection()
        let context = container.mainContext
        XCTAssertEqual(try context.fetch(FetchDescriptor<BucketItem>()).count, 0)
        XCTAssertEqual(try context.fetch(FetchDescriptor<Project>()).count, 0)
        XCTAssertEqual(try context.fetch(FetchDescriptor<Loadout>()).count, 0)
        XCTAssertEqual(try context.fetch(FetchDescriptor<Subcontractor>()).count, 0)
    }

    func testThePlannedToolsAreListed() {
        XCTAssertEqual(PlanningScreen.plannedTools, [
            "Revenue forecast",
            "Cash flow, 30/60/90 days",
            "Annual budget and break-even",
            "Crew capacity and utilization",
            "Business plan and operating documents",
        ])
    }

    func testTheScreenBuildsInLightAndDark() {
        for name in [NSAppearance.Name.aqua, .darkAqua] {
            let host = NSHostingView(rootView: PlanningScreen().frame(width: 560, height: 520))
            host.appearance = NSAppearance(named: name)
            host.frame = NSRect(x: 0, y: 0, width: 560, height: 520)
            host.layoutSubtreeIfNeeded()
            XCTAssertGreaterThan(host.fittingSize.height, 0)
        }
    }
}
