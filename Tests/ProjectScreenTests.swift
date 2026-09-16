import XCTest
import SwiftData
@testable import Buckets

/// Non-view logic behind the Project screen: the pasteboard texts, the row labels, and the screenshot hook.
@MainActor
final class ProjectScreenTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext { container.mainContext }

    override func setUp() async throws {
        container = try Store.inMemoryContainer()
        StoreFixture.insertRows(into: context)
    }

    // MARK: Copy price / Copy breakdown (DECISIONS 41)

    func testCopyPriceIsNameAndPriceOnly() throws {
        let project = try StoreFixture.baseProject(in: context)
        project.name = "Oak removal"
        let text = ProjectText.price(name: project.displayName, priceCents: project.priceCents)
        XCTAssertEqual(text, "Oak removal — $2,501.50")
        XCTAssertEqual(ProjectText.price(name: Project(name: "", date: .now, markupPct: 35, minimumJobCents: 75000).displayName,
                                         priceCents: 75000), "Untitled project — $750.00")
    }

    func testCopyBreakdownIsTheHeaderFiguresOneLineEach() throws {
        let project = try StoreFixture.baseProject(in: context)
        project.name = "Oak removal"
        project.date = Date(timeIntervalSince1970: 1_757_800_000)
        let text = ProjectText.breakdown(project, breakdown: project.breakdown(billableHours: 1500))
        XCTAssertEqual(text, """
        Oak removal
        Date: \(ProjectText.dateString(project.date))
        Hours: 8
        Multiplier: 1× Normal
        Labor: $995.12
        Equipment: $563.84
        Materials: $0.00
        Consumables: $150.00
        Subcontractors: $0.00
        Overhead: $144.00
        Cost: $1,852.96
        Markup: 35%
        Price: $2,501.50
        Profit: $648.54 (25.9% margin)
        """)
        // Never a row name, a rate, or a subcontractor's name or service (only the bucket subtotal, DECISIONS 41/60).
        for line in project.lines {
            XCTAssertFalse(text.contains(line.name), line.name)
            XCTAssertFalse(text.contains(Money.format(line.rateCents)), Money.format(line.rateCents))
        }
        XCTAssertFalse(text.contains("(sub)"))
        XCTAssertTrue(ProjectText.dateString(project.date).hasPrefix("Sep 1"), "Sep 13 or 14, 2025 by time zone")
        XCTAssertTrue(ProjectText.dateString(project.date).hasSuffix(", 2025"))
    }

    func testCopyBreakdownReflectsMultiplierHoursAndMarkup() throws {
        let project = try StoreFixture.baseProject(in: context)
        project.multiplier = 2
        project.hours = Decimal(string: "6.5")!
        project.markupPct = Decimal(string: "32.5")!
        let text = ProjectText.breakdown(project, breakdown: project.breakdown(billableHours: 1500))
        XCTAssertTrue(text.contains("\nHours: 6.5\n"))
        XCTAssertTrue(text.contains("\nMultiplier: 2× After-hours\n"))
        XCTAssertTrue(text.contains("\nMarkup: 32.5%\n"))
        XCTAssertEqual(text.components(separatedBy: "\n").count, 14)
        project.targetMarginPct = 50
        let margin = ProjectText.breakdown(project, breakdown: project.breakdown(billableHours: 1500))
        XCTAssertTrue(margin.contains("\nTarget margin: 50%\n"), margin)
        XCTAssertFalse(margin.contains("Markup"))
        XCTAssertEqual(ProjectText.pricingString(project), "50%")
        project.targetMarginPct = nil
        XCTAssertEqual(ProjectText.pricingString(project), "32.5%")
    }

    func testMultiplierTitlesAndMarkupString() {
        XCTAssertEqual(ProjectMultiplier.allCases.map(\.rawValue), [1, 2, 3])
        XCTAssertEqual(ProjectMultiplier.allCases.map(\.title), ["1× Normal", "2× After-hours", "3× Emergency"])
        XCTAssertEqual(ProjectMultiplier.title(3), "3× Emergency")
        XCTAssertEqual(ProjectMultiplier.title(7), "7×")
        XCTAssertEqual(ProjectText.markupString(35), "35%")
        XCTAssertEqual(ProjectText.markupString(Decimal(string: "32.5")!), "32.5%")
        XCTAssertEqual(ProjectText.markupString(0), "0%")
        XCTAssertEqual(ProjectText.hoursMaximum, Decimal(string: "99999.99")!)
        XCTAssertEqual(ProjectText.qtyMaximum, Decimal(string: "999999.99")!)
    }

    // MARK: Row labels (DECISIONS 21, 29)

    func testLineLabelsTotalsAndStatus() throws {
        let project = try StoreFixture.baseProject(in: context)
        XCTAssertEqual(project.line("Marcus").rateLabel(billableHours: 1500), "$54.08/hr")
        XCTAssertEqual(project.line("Shop rent").rateLabel(billableHours: 1500), "$9,600.00/yr = $6.40/hr")
        XCTAssertEqual(project.line("Shop rent").rateLabel(billableHours: 0), "$9,600.00/yr = $0.00/hr")
        XCTAssertEqual(project.line("Dump fee").rateLabel(billableHours: 1500), "$75.00/load")
        XCTAssertEqual(project.line("Queen palm, 10 gal").rateLabel(billableHours: 1500), "$85.00 each")
        XCTAssertEqual(rateLabel(cents: 100, unit: ""), "$1.00")
        XCTAssertEqual(project.line("Dump fee").totalCents, 15_000)
        XCTAssertEqual(project.line("Marcus").totalCents, 0, "hourly rows have no per-line total")
        let stumps = project.line("Stump grinding (sub)")
        stumps.qty = Decimal(string: "2.5")!
        XCTAssertEqual(stumps.totalCents, 22_500)
        stumps.qty = 0
        XCTAssertEqual(stumps.totalCents, 0)
        XCTAssertEqual(ProjectLine(item: nil, bucket: .labor, name: "", unit: "hr", rateCents: 0, isOn: true).displayName, "Untitled")

        XCTAssertNil(project.line("Marcus").statusCaption)
        try StoreFixture.items(in: context).first { $0.name == "Miguel" }!.isActive = false
        XCTAssertEqual(project.line("Miguel").statusCaption, "archived")
        context.delete(try StoreFixture.items(in: context).first { $0.name == "Dump fee" }!)
        try context.save()
        XCTAssertEqual(project.line("Dump fee").statusCaption, "row deleted")
        XCTAssertEqual(project.priceCents, 250_150, "archived and deleted rows still price from their snapshots")
    }

    // MARK: Screenshot hook (DECISIONS 48) — opens the oldest project, never creates one

    func testScreenHookOpensTheOldestProject() throws {
        let older = try StoreFixture.baseProject(in: context)
        older.name = "Oak removal"
        older.date = Date(timeIntervalSince1970: 1_757_800_000)
        let newer = Project.make(name: "Palm install", date: Date(timeIntervalSince1970: 1_757_900_000),
                                 items: try StoreFixture.items(in: context), settings: AppSettings())
        context.insert(newer)
        try context.save()

        let state = AppState(container: container, screen: "project")
        XCTAssertEqual(state.sidebar, .projects)
        XCTAssertEqual(state.selectedProject, older.persistentModelID)
        XCTAssertEqual(try context.fetch(FetchDescriptor<Project>()).count, 2, "the hook never creates a project")

        let list = AppState(container: container, screen: "projects")
        XCTAssertEqual(list.sidebar, .projects)
        XCTAssertNil(list.selectedProject)
    }

    func testScreenHookOnAnEmptyStoreSelectsNoProject() throws {
        let state = AppState(container: container, screen: "project")
        XCTAssertEqual(state.sidebar, .projects)
        XCTAssertNil(state.selectedProject)
        XCTAssertEqual(try context.fetch(FetchDescriptor<Project>()).count, 0)
    }
}
