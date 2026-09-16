import XCTest
import SwiftUI
import SwiftData
@testable import Buckets

/// Non-view logic behind the Projects list and the Settings screen: the variance column, the settings
/// field bindings, and the Export / Import texts.
@MainActor
final class ProjectsListTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext { container.mainContext }

    override func setUp() async throws {
        container = try Store.inMemoryContainer()
        StoreFixture.insertRows(into: context)
    }

    // MARK: Actual variance column (DECISIONS 31)

    func testVarianceIsSignedDollarsOrADash() {
        XCTAssertEqual(ProjectsText.variance(nil), "—")
        XCTAssertEqual(ProjectsText.variance(50_074), "+$500.74")
        XCTAssertEqual(ProjectsText.variance(-1200), "-$12.00")
        XCTAssertEqual(ProjectsText.variance(0), "$0.00")
        XCTAssertEqual(ProjectsText.variance(123_456_789), "+$1,234,567.89")
    }

    func testVarianceColumnFollowsActualHours() throws {
        let project = try StoreFixture.baseProject(in: context)
        XCTAssertEqual(ProjectsText.variance(project.actuals(billableHours: 1500)?.totalVariance), "—")
        project.actualHours = 10
        XCTAssertEqual(ProjectsText.variance(project.actuals(billableHours: 1500)?.totalVariance), "+$425.74")
        project.actualHours = 6
        project.line("Dump fee").actualQty = 3
        XCTAssertEqual(ProjectsText.variance(project.actuals(billableHours: 1500)?.totalVariance), "-$350.74")
    }

    // MARK: Settings fields (DECISIONS 10, 11, 12)

    func testBillableHoursBindingRefusesLessThanOneAndRoundsToWhole() {
        var stored = 1500
        let binding = SettingsField.billableHours(Binding(get: { stored }, set: { stored = $0 }))
        XCTAssertEqual(binding.wrappedValue, 1500)
        binding.wrappedValue = 0
        XCTAssertEqual(stored, 1500, "0 is refused; the last good value stays")
        binding.wrappedValue = Decimal(string: "0.4")!
        XCTAssertEqual(stored, 1500)
        binding.wrappedValue = 3000
        XCTAssertEqual(stored, 3000)
        binding.wrappedValue = Decimal(string: "1800.5")!
        XCTAssertEqual(stored, 1801, "rounded half away from zero to whole hours")
        binding.wrappedValue = 1
        XCTAssertEqual(stored, 1)
        XCTAssertNil(SettingsField.wholeHours(0))
        XCTAssertNil(SettingsField.wholeHours(-5))
        XCTAssertNil(SettingsField.wholeHours(.nan))
        XCTAssertEqual(SettingsField.wholeHours(Decimal(string: "0.5")!), 1)
        XCTAssertEqual(SettingsField.wholeHours(2080), 2080)
    }

    func testPercentBindingRoundTripsExactly() {
        var stored = 30.0
        let binding = SettingsField.percent(Binding(get: { stored }, set: { stored = $0 }))
        XCTAssertEqual(binding.wrappedValue, 30)
        binding.wrappedValue = Decimal(string: "32.5")!
        XCTAssertEqual(stored, 32.5)
        XCTAssertEqual(binding.wrappedValue, Decimal(string: "32.5")!, "lifted back through the shortest round-trip text")
        binding.wrappedValue = Decimal(string: "0.1")!
        XCTAssertEqual(binding.wrappedValue, Decimal(string: "0.1")!)
        binding.wrappedValue = 0
        XCTAssertEqual(stored, 0)
        XCTAssertEqual(SettingsField.double(-3), 0, "never negative")
        XCTAssertEqual(SettingsField.double(.nan), 0)
        // The value the Models layer reads is the same exact Decimal.
        let defaults = UserDefaults(suiteName: "BucketsTests.settingsScreen")!
        defaults.removePersistentDomain(forName: "BucketsTests.settingsScreen")
        var settings = AppSettings()
        settings.laborBurdenPct = SettingsField.double(Decimal(string: "27.5")!)
        settings.save(to: defaults)
        XCTAssertEqual(AppSettings.current(from: defaults).laborBurden, Decimal(string: "0.275")!)
    }

    func testMarkupNextToMargin() {
        XCTAssertEqual(SettingsText.markupString(marginPct: 50), "100.0%")
        XCTAssertEqual(SettingsText.markupString(marginPct: 40), "66.7%")
        XCTAssertEqual(SettingsText.markupString(marginPct: 0), "0.0%")
        XCTAssertEqual(SettingsText.markupString(marginPct: Decimal(string: "32.5")!), "48.1%")
        XCTAssertEqual(SettingsText.markupString(marginPct: 200), "1,900.0%", "held at the 95% ceiling")
    }

    func testMarginFieldRefusesImpossibleMargins() {
        XCTAssertEqual(SettingsField.marginPercent(50), 50)
        XCTAssertEqual(SettingsField.marginPercent(0), 0)
        XCTAssertEqual(SettingsField.marginPercent(95), 95)
        XCTAssertNil(SettingsField.marginPercent(100), "a 100% margin has no price")
        XCTAssertNil(SettingsField.marginPercent(-1))
        XCTAssertNil(SettingsField.marginPercent(.nan))
    }

    // MARK: Export / Import texts (DECISIONS 43)

    func testExportFileNameIsTheLocalDay() {
        let stamp = Date(timeIntervalSince1970: 1_757_800_000)   // 2025-09-13 22:26:40 UTC
        XCTAssertEqual(SettingsText.exportFileName(for: stamp, timeZone: TimeZone(identifier: "UTC")!), "Buckets-export-2025-09-13.json")
        XCTAssertEqual(SettingsText.exportFileName(for: stamp, timeZone: TimeZone(identifier: "Asia/Tokyo")!), "Buckets-export-2025-09-14.json")
        XCTAssertTrue(SettingsText.exportFileName(for: .now).hasPrefix("Buckets-export-"))
        XCTAssertTrue(SettingsText.exportFileName(for: .now).hasSuffix(".json"))
    }

    func testImportTextsCountRowsAndProjects() {
        XCTAssertEqual(SettingsText.rowsPhrase(1), "1 row")
        XCTAssertEqual(SettingsText.rowsPhrase(25), "25 rows")
        XCTAssertEqual(SettingsText.importSummary(fileName: "x.json", rows: 25, projects: 2), "Imported 25 rows and 2 projects from x.json.")
        let prompt = SettingsText.importPrompt(fileName: "x.json", rows: 0, projects: 1)
        XCTAssertTrue(prompt.contains("0 rows and 1 project in “x.json”"))
        XCTAssertTrue(prompt.contains("Export first"))
    }

    func testExportedFileParsesBeforeTheReplacePrompt() throws {
        _ = try StoreFixture.baseProject(in: context)
        let data = try Transfer.exportJSON(from: context, settings: AppSettings(), exportedAt: .now)
        let document = try Transfer.decoder().decode(TransferDocument.self, from: data)
        XCTAssertEqual(document.items.count, 25)
        XCTAssertEqual(document.projects.count, 1)
        XCTAssertThrowsError(try Transfer.decoder().decode(TransferDocument.self, from: Data("not json".utf8)))
    }
}
