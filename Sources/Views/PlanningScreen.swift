import SwiftUI

/// Planning (DECISIONS 90): the reserved seam for the business planning section, under construction.
///
/// This screen is meant to hold the owner's planning and operating documents, built on the numbers Buckets
/// already keeps (bucket rates, overhead per billable hour, projects and packages): a revenue forecast, a
/// 30/60/90-day cash-flow forecast, the annual budget and break-even, crew capacity and utilization, and the
/// business plan and operating documents. Until that section is built it shows only what is coming: it has no
/// model, reads no data and shows no figures, so nothing here can be mistaken for a forecast.
struct PlanningScreen: View {
    /// The planned tools, in the order the section is expected to grow. Plain text only; none is built yet.
    static let plannedTools: [String] = [
        "Revenue forecast",
        "Cash flow, 30/60/90 days",
        "Annual budget and break-even",
        "Crew capacity and utilization",
        "Business plan and operating documents",
    ]

    var body: some View {
        Form {
            Section {
                VStack(spacing: 10) {
                    Image(systemName: "hammer")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary)
                    Text("Under construction")
                        .font(.title2.bold())
                    Text("Business planning and operating documents will live here, built on the rates and overhead in your buckets.")
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            }
            Section("Planned") {
                ForEach(Self.plannedTools, id: \.self) { tool in
                    LabeledContent {
                        Text("Coming soon").foregroundStyle(.secondary)
                    } label: {
                        Label(tool, systemImage: "circle.dashed")
                    }
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Planning")
        .navigationSplitViewColumnWidth(min: 480, ideal: 560)
    }
}
