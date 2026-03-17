import SwiftUI
import Charts

public struct DashboardView: View {
    @Bindable var viewModel: DashboardViewModel
    @State private var checklistViewModel = ChecklistViewModel()

    public init(viewModel: DashboardViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 24) {
                // Section 1: Equity Curve
                EquityCurveSection(
                    selectedRange: $viewModel.selectedRange,
                    curve: viewModel.equityCurve(range: viewModel.selectedRange)
                )

                // Section 2: Market Overview + Daily Checklist
                HStack(alignment: .top, spacing: 24) {
                    MarketOverviewCard(quotes: viewModel.marketQuotes)
                    DailyChecklistCard(viewModel: checklistViewModel)
                }

                // Section 3: Psychological Analytics
                PsychAnalyticsSection(analytics: viewModel.psychAnalytics)

                // Section 4: Market News
                MarketNewsCard()
            }
            .padding(24)
        }
        .background(Color.fmsBackground)
    }
}
