import SwiftUI
import SwiftData

/// Setup & readiness at the top of the Company screen (DECISIONS 73): the status, the required setup inputs,
/// catalog completion per bucket, and the unresolved rows grouped by reason with a jump to each group.
struct CompanyReadinessSection: View {
    @Environment(AppState.self) private var appState
    @Query private var items: [BucketItem]
    @Query private var companies: [Company]
    @AppStorage(AppSettings.Key.billableHoursPerYear) private var billableHoursPerYear = AppSettings.defaults.billableHoursPerYear
    @AppStorage(AppSettings.Key.targetMarginPct) private var targetMarginPct = AppSettings.defaults.targetMarginPct
    @AppStorage(AppSettings.Key.minimumJobCents) private var minimumJobCents = AppSettings.defaults.minimumJobCents
    @State private var showingInputs = true
    @State private var showingBuckets = false

    private var readiness: Readiness {
        // The three @AppStorage values keep the section live as they are edited below it.
        var settings = AppSettings.current()
        settings.billableHoursPerYear = billableHoursPerYear
        settings.targetMarginPct = targetMarginPct
        settings.minimumJobCents = minimumJobCents
        return Readiness(items: items, company: companies.first, settings: settings)
    }

    var body: some View {
        let r = readiness
        Section {
            LabeledContent {
                Text(r.status.detail).foregroundStyle(.secondary)
            } label: {
                Label(r.status.title, systemImage: r.status.symbol).foregroundStyle(r.status.style).font(.headline)
                if let date = r.lastVerified {
                    Text("Last verified \(BucketItem.shortDate(date))").foregroundStyle(.secondary)
                }
            }
            DisclosureGroup(isExpanded: $showingInputs) {
                ForEach(r.setupInputs) { input in
                    LabeledContent {
                        Text(input.detail).foregroundStyle(.secondary)
                    } label: {
                        Label(input.title, systemImage: input.isResolved ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(input.isResolved ? AnyShapeStyle(.green) : AnyShapeStyle(.orange))
                    }
                }
            } label: {
                Text("Setup inputs · \(r.setupInputs.count - r.missingInputs) of \(r.setupInputs.count)")
            }
            DisclosureGroup(isExpanded: $showingBuckets) {
                Grid(alignment: .trailing, horizontalSpacing: 16, verticalSpacing: 4) {
                    GridRow {
                        Text("Bucket").gridColumnAlignment(.leading)
                        Text("Resolved"); Text("Done"); Text("Last verified")
                    }
                    .font(.caption).foregroundStyle(.secondary)
                    ForEach(r.buckets) { b in
                        GridRow {
                            Text(b.bucket.title).gridColumnAlignment(.leading)
                            Text("\(b.resolved) of \(b.active)").monospacedDigit()
                            Text(b.active == 0 ? "—" : "\(b.completionPct)%").monospacedDigit()
                            Text(b.lastVerified.map(BucketItem.shortDate) ?? "—").foregroundStyle(.secondary)
                        }
                    }
                }
            } label: {
                Text("Catalog by bucket")
            }
            ForEach(UnresolvedReason.allCases, id: \.self) { reason in
                let n = r.unresolved[reason] ?? 0
                LabeledContent {
                    HStack(spacing: 10) {
                        Text("\(n)").monospacedDigit().foregroundStyle(n == 0 ? AnyShapeStyle(.secondary) : AnyShapeStyle(.primary))
                        Button("Show") { appState.showUnresolved(reason, in: r.firstBucket[reason]) }
                            .disabled(n == 0)
                            .help("Open the Buckets screen filtered to these rows")
                    }
                } label: {
                    Text(reason.title)
                }
            }
        } header: {
            Text("Setup & readiness")
        } footer: {
            Text("Ready is claimed only when every setup input is resolved and no active row is missing, estimated, overdue or waiting on the owner. Warnings on projects never change a price.")
                .font(.caption).foregroundStyle(.secondary)
        }
    }
}

extension Readiness.Status {
    var symbol: String {
        switch self {
        case .notReady: "xmark.octagon.fill"
        case .needsReview: "exclamationmark.triangle.fill"
        case .ready: "checkmark.seal.fill"
        }
    }

    /// System colors only: red not ready, orange needs review, green ready.
    var style: AnyShapeStyle {
        switch self {
        case .notReady: AnyShapeStyle(.red)
        case .needsReview: AnyShapeStyle(.orange)
        case .ready: AnyShapeStyle(.green)
        }
    }
}
