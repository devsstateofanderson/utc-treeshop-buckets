import XCTest
import SwiftData
@testable import Buckets

/// Row trust and review (DECISIONS 72; issue #3 §1, §3, §4): the confidence rules, the unresolved groups,
/// the filter, and the non-blocking project warning.
@MainActor
final class CatalogReviewTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext { container.mainContext }
    private let checked = Date(timeIntervalSince1970: 1_789_536_000)   // 2026-09-16
    private let now = Date(timeIntervalSince1970: 1_790_236_000)       // 2026-09-24
    private let past = Date(timeIntervalSince1970: 1_788_536_000)      // 2026-09-04

    override func setUp() async throws {
        container = try Store.inMemoryContainer()
        StoreFixture.insertRows(into: context)
    }

    private func item(_ name: String) throws -> BucketItem {
        try StoreFixture.items(in: context).first { $0.name == name }!
    }

    func testEveryRowStartsMissingAndTheSetterRoundTrips() throws {
        let marcus = try item("Marcus")
        XCTAssertEqual(marcus.confidence, .missing)
        XCTAssertNil(marcus.confidenceRaw)
        XCTAssertFalse(marcus.needsOwnerConfirmation)
        XCTAssertEqual(marcus.unresolvedReason(now: now), .missing)
        marcus.confidence = .estimated
        XCTAssertEqual(marcus.confidenceRaw, "estimated")
        marcus.confidence = .missing
        XCTAssertNil(marcus.confidenceRaw, "missing is stored as nil so old stores and never-reviewed rows read alike")
        marcus.confidenceRaw = "garbage"
        XCTAssertEqual(marcus.confidence, .missing)
    }

    func testVerifiedNeedsEvidenceAndACheckedDate() throws {
        let marcus = try item("Marcus")
        XCTAssertFalse(marcus.canMarkVerified)
        XCTAssertFalse(marcus.markVerified())
        XCTAssertEqual(marcus.confidence, .missing, "a refused verify changes nothing")
        marcus.evidence = "2026 payroll register"
        XCTAssertFalse(marcus.canMarkVerified, "evidence alone is not enough")
        marcus.checkedAt = checked
        XCTAssertTrue(marcus.canMarkVerified)
        XCTAssertTrue(marcus.markVerified())
        XCTAssertEqual(marcus.confidence, .verified)
        XCTAssertNil(marcus.unresolvedReason(now: now))
        XCTAssertEqual(marcus.reviewLabel(now: now), "Verified · Sep 16, 2026")
        // A source or a link counts as evidence too.
        let palm = try item("Queen palm, 10 gal")
        palm.source = "Cherry Lake"; palm.checkedAt = checked
        XCTAssertTrue(palm.canMarkVerified)
        let mulch = try item("Mulch")
        mulch.link = "https://example.com/mulch"; mulch.checkedAt = checked
        XCTAssertTrue(mulch.canMarkVerified)
        let stakes = try item("Stakes + ties kit")
        stakes.source = "   "; stakes.checkedAt = checked
        XCTAssertFalse(stakes.canMarkVerified, "whitespace is not evidence")
    }

    func testUnresolvedGroupsAreDisjointInPrecedenceOrder() throws {
        let marcus = try item("Marcus")
        // estimated
        marcus.confidence = .estimated
        XCTAssertEqual(marcus.unresolvedReason(now: now), .estimated)
        XCTAssertEqual(marcus.reviewLabel(now: now), "Estimated")
        // an estimate flagged for the owner waits in the owner's group, not the estimated one
        marcus.needsOwnerConfirmation = true
        XCTAssertEqual(marcus.unresolvedReason(now: now), .ownerConfirmation)
        XCTAssertEqual(marcus.reviewLabel(now: now), "Owner to confirm")
        // the owner's sign-off resolves it and clears the flag
        marcus.markOwnerConfirmed(now: now)
        XCTAssertEqual(marcus.confidence, .ownerConfirmed)
        XCTAssertFalse(marcus.needsOwnerConfirmation)
        XCTAssertEqual(marcus.checkedAt, now, "confirmation counts as a check when none was recorded")
        XCTAssertNil(marcus.unresolvedReason(now: now))
        XCTAssertEqual(marcus.reviewLabel(now: now), "Owner confirmed · Sep 24, 2026")
        // a trusted row goes overdue when its review date passes
        marcus.reviewDueAt = past
        XCTAssertTrue(marcus.isOverdue(now: now))
        XCTAssertEqual(marcus.unresolvedReason(now: now), .overdue)
        XCTAssertEqual(marcus.reviewSeverity(now: now), .overdue)
        XCTAssertEqual(marcus.reviewLabel(now: now), "Overdue · due Sep 4, 2026")
        XCTAssertFalse(marcus.isOverdue(now: past), "not overdue before the due date")
        // a flag outranks overdue; missing outranks everything
        marcus.needsOwnerConfirmation = true
        XCTAssertEqual(marcus.unresolvedReason(now: now), .ownerConfirmation)
        marcus.confidence = .missing
        XCTAssertEqual(marcus.unresolvedReason(now: now), .missing)
        XCTAssertEqual(marcus.reviewSeverity(now: now), .attention)
    }

    func testMarkCheckedSetsTodayAndAYearOut() throws {
        let marcus = try item("Marcus")
        marcus.markChecked(now: checked)
        XCTAssertEqual(marcus.checkedAt, checked)
        XCTAssertEqual(marcus.reviewDueAt, Calendar.current.date(byAdding: .year, value: 1, to: checked))
        marcus.reviewDueAt = past
        marcus.markChecked(now: now)
        XCTAssertEqual(marcus.reviewDueAt, past, "an existing due date is kept")
    }

    func testFilterAndSearchSeeTheReviewFields() throws {
        let marcus = try item("Marcus")
        marcus.evidence = "Southern Personnel Leasing invoice"
        marcus.approvedBy = "Alexander"
        marcus.assumption = "2,080 paid hours"
        XCTAssertTrue(marcus.matches("leasing"))
        XCTAssertTrue(marcus.matches("alexander"))
        XCTAssertTrue(marcus.matches("2,080"))
        XCTAssertTrue(ReviewFilter.all.includes(marcus, now: now))
        XCTAssertTrue(ReviewFilter.unresolved.includes(marcus, now: now))
        XCTAssertTrue(ReviewFilter.reason(.missing).includes(marcus, now: now))
        XCTAssertFalse(ReviewFilter.reason(.estimated).includes(marcus, now: now))
        marcus.checkedAt = checked
        marcus.markVerified()
        XCTAssertFalse(ReviewFilter.unresolved.includes(marcus, now: now))
        XCTAssertEqual(ReviewFilter.allCases.count, 2 + UnresolvedReason.allCases.count)
        XCTAssertEqual(ReviewFilter.allCases.map(\.title).prefix(3), ["All rows", "Unresolved", "Missing"])
    }

    func testProjectWarnsOnEnabledUnresolvedLinesButPricesExactlyAsBefore() throws {
        let project = try StoreFixture.baseProject(in: context)
        // Every fixture row is missing, so every enabled line warns: 3 labor + 4 equipment + 7 overhead + dump fee.
        XCTAssertEqual(project.unresolvedEnabledLines(now: now).count, 15)
        XCTAssertEqual(project.line("Marcus").reviewCaption(now: now), "no source yet")
        XCTAssertNil(project.line("Mini skid steer").reviewCaption(now: now), "off lines do not warn")
        XCTAssertNil(project.line("Queen palm, 10 gal").reviewCaption(now: now))
        XCTAssertEqual(project.priceCents, 250_150, "the warning never touches the price")
        // Resolving rows removes their warning; the price still does not move.
        for name in ["Marcus", "David", "Miguel"] {
            let row = try item(name); row.evidence = "payroll"; row.checkedAt = checked; row.markVerified()
        }
        XCTAssertEqual(project.unresolvedEnabledLines(now: now).count, 12)
        XCTAssertNil(project.line("Marcus").reviewCaption(now: now))
        XCTAssertEqual(project.priceCents, 250_150)
        let chipper = try item("Chipper (12\")")
        chipper.confidence = .estimated
        XCTAssertEqual(project.line("Chipper (12\")").reviewCaption(now: now), "estimated")
        chipper.needsOwnerConfirmation = true
        XCTAssertEqual(project.line("Chipper (12\")").reviewCaption(now: now), "needs owner confirmation")
        // A deleted row has no current figure to review; its own "row deleted" caption stands (DECISIONS 21).
        let dump = try item("Dump fee")
        context.delete(dump); try context.save()
        XCTAssertNil(project.line("Dump fee").reviewCaption(now: now))
        XCTAssertEqual(project.line("Dump fee").statusCaption, "row deleted")
        XCTAssertEqual(project.priceCents, 250_150)
    }

    func testWarningText() {
        XCTAssertEqual(ProjectText.unresolvedWarning(count: 1), "1 enabled row uses an unresolved catalog input — price unchanged")
        XCTAssertEqual(ProjectText.unresolvedWarning(count: 3), "3 enabled rows use unresolved catalog inputs — price unchanged")
        XCTAssertEqual(UnresolvedReason.allCases.map(\.title), ["Missing", "Estimated", "Review overdue", "Owner confirmation needed"])
        XCTAssertEqual(Confidence.allCases.map(\.title), ["Missing", "Estimated", "Owner confirmed", "Verified"])
        XCTAssertTrue(Confidence.verified.isTrusted && Confidence.ownerConfirmed.isTrusted)
        XCTAssertFalse(Confidence.estimated.isTrusted || Confidence.missing.isTrusted)
    }
}
