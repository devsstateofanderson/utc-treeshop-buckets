import XCTest

/// PROMPT Layer 6 Phase D: enter the BRIEF §3.3 rows through the real UI (never seed code) and read the
/// header. Runs against a throwaway store in the temp directory, so the delivered app stays empty.
final class BucketsUITests: XCTestCase {
    private var app: XCUIApplication!
    private let store = NSTemporaryDirectory() + "BucketsUITests/Buckets.store"

    @MainActor
    override func setUp() async throws {
        continueAfterFailure = false
        for suffix in ["", "-wal", "-shm"] { try? FileManager.default.removeItem(atPath: store + suffix) }
        try FileManager.default.createDirectory(atPath: (store as NSString).deletingLastPathComponent, withIntermediateDirectories: true)
        app = XCUIApplication()
        app.launchEnvironment["BUCKETS_STORE"] = store
        app.launch()
    }

    @MainActor
    override func tearDown() async throws {
        app?.terminate()
    }

    // MARK: helpers

    private func sidebar(_ title: String) {
        let item = app.staticTexts[title].firstMatch
        XCTAssertTrue(item.waitForExistence(timeout: 5), "sidebar item \(title)")
        item.click()
    }

    private func type(into field: XCUIElement, _ text: String, replace: Bool = false) {
        XCTAssertTrue(field.waitForExistence(timeout: 5), "field \(field)")
        field.click()
        if replace { field.typeKey("a", modifierFlags: .command) }
        field.typeText(text)
    }

    private func addRow(bucket: String, name: String, rate: String, rateLabel: String, unit: String? = nil) {
        sidebar(bucket)
        app.buttons["New Row"].firstMatch.click()
        type(into: app.textFields["Name"].firstMatch, name)
        type(into: app.textFields[rateLabel].firstMatch, rate)
        if let unit { type(into: app.textFields["Unit"].firstMatch, unit, replace: true) }
    }

    private func toggle(_ name: String) {
        let box = app.checkBoxes["line.\(name)"].firstMatch
        XCTAssertTrue(box.waitForExistence(timeout: 5), "toggle \(name)")
        box.click()
    }

    private func qty(_ name: String, _ value: String) {
        type(into: app.textFields["qty.\(name)"].firstMatch, value, replace: true)
    }

    private func price() -> String {
        let label = app.staticTexts["price"].firstMatch
        XCTAssertTrue(label.waitForExistence(timeout: 5))
        return label.label
    }

    private func expectPrice(_ expected: String) {
        let deadline = Date().addingTimeInterval(5)
        while price() != expected && Date() < deadline { usleep(200_000) }
        XCTAssertEqual(price(), expected)
    }

    // MARK: the §3.3 walk-through

    @MainActor
    func testWorkedExampleThroughTheUI() throws {
        // Onboarding: the 25 rows, typed in (BRIEF §4).
        for (name, rate) in [("Marcus", "54.08"), ("David", "39.66"), ("Miguel", "30.65")] {
            addRow(bucket: "Labor", name: name, rate: rate, rateLabel: "Rate per hour")
        }
        for (name, rate) in [("Bucket truck (50 ft)", "23.72"), ("Chip truck (F-550)", "22.15"), ("Chipper (12\")", "17.11"),
                             ("Chainsaws (3)", "7.50"), ("Mini skid steer", "16.03")] {
            addRow(bucket: "Equipment", name: name, rate: rate, rateLabel: "Rate per hour")
        }
        for (name, rate) in [("General liability", "6000"), ("Shop rent", "9600"), ("Website + marketing", "3600"),
                             ("Phones + internet", "2400"), ("Accounting + legal", "2400"), ("Software", "1800"), ("Licenses + misc", "1200")] {
            addRow(bucket: "Overhead", name: name, rate: rate, rateLabel: "Cost per year")
        }
        for (name, rate, unit) in [("Queen palm, 10 gal", "85", "each"), ("Root barrier", "45", "20 ft roll"), ("Mulch", "32", "yard"), ("Stakes + ties kit", "12", "each")] {
            addRow(bucket: "Materials", name: name, rate: rate, rateLabel: "Unit cost", unit: unit)
        }
        for (name, rate, unit) in [("Dump fee", "75", "load"), ("Grapple truck (sub)", "650", "day"), ("Stump grinding (sub)", "90", "stump"),
                                   ("Crane (sub)", "1800", "day"), ("Cambistat", "120", "application"), ("Permit", "50", "each")] {
            addRow(bucket: "Consumables", name: name, rate: rate, rateLabel: "Unit cost", unit: unit)
        }

        // Daily: new project, hours, flip toggles, read Price (BRIEF §3.3).
        sidebar("Projects")
        app.buttons["New Project"].firstMatch.click()
        type(into: app.textFields["Hours"].firstMatch, "8")
        toggle("Mini skid steer")                 // §3.3: no skid steer
        toggle("Dump fee"); qty("Dump fee", "2")  // 2 dump loads
        expectPrice("$3,705.92")                  // 50% target margin: twice the $1,852.96 cost (DECISIONS 70)

        toggle("Miguel")
        expectPrice("$3,215.52")

        toggle("Miguel"); toggle("Mini skid steer")
        expectPrice("$3,962.40")

        toggle("Stump grinding (sub)"); qty("Stump grinding (sub)", "3")
        expectPrice("$4,502.40")

        // After the job: actual hours → variance appears (BRIEF §3.5).
        type(into: app.textFields["Actual hours"].firstMatch, "10")
        XCTAssertTrue(app.staticTexts["8 estimated / 10 actual hours"].waitForExistence(timeout: 5))

        // Customer-safe copy: name + price only.
        app.buttons["Copy price"].firstMatch.click()
        let pasted = NSPasteboard.general.string(forType: .string) ?? ""
        XCTAssertTrue(pasted.hasSuffix("$4,502.40"), pasted)
        XCTAssertFalse(pasted.contains("Stump"), "line items must never be copied")

        // The list shows the project and its variance.
        XCTAssertTrue(app.staticTexts["$4,502.40"].firstMatch.exists)
    }
}
