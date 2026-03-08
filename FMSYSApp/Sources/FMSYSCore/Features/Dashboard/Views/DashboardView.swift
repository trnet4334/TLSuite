import SwiftUI
import Charts

public struct DashboardView: View {
    @State private var viewModel: DashboardViewModel

    public init(trades: [Trade]) {
        self._viewModel = State(wrappedValue: DashboardViewModel(trades: trades))
    }

    public var body: some View {
        ZStack {
            Color.fmsBackground
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Dashboard")
                        .font(.title2.bold())
                        .foregroundStyle(Color.fmsOnSurface)
                        .padding(.top, 8)

                    statsGrid

                    equitySection
                }
                .padding(24)
            }
        }
    }

    // MARK: - Stat Cards

    private var statsGrid: some View {
        let pnl = viewModel.totalPnL
        let pnlText = String(format: "%+.2f", pnl)
        let pnlColor: Color = pnl >= 0 ? Color.fmsPrimary : Color.fmsLoss
        let winPct = String(format: "%.1f%%", viewModel.winRate * 100)
        let rr = String(format: "%.2f", viewModel.avgRR)
        let streak = viewModel.currentStreak
        let streakLabel = streak >= 0 ? "+\(streak)W" : "\(abs(streak))L"
        let streakColor: Color = streak >= 0 ? Color.fmsPrimary : Color.fmsLoss

        return LazyVGrid(
            columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],
            spacing: 12
        ) {
            StatCardView(title: "Total P&L", value: pnlText, valueColor: pnlColor)
            StatCardView(title: "Win Rate", value: winPct)
            StatCardView(title: "Avg R:R", value: rr)
            StatCardView(title: "Total Trades", value: "\(viewModel.totalTrades)")
            StatCardView(title: "Best Streak", value: "\(viewModel.bestStreak)W")
            StatCardView(title: "Current Streak", value: streakLabel, valueColor: streakColor)
        }
    }

    // MARK: - Equity Curve

    private var equitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Equity Curve")
                    .font(.headline)
                    .foregroundStyle(Color.fmsOnSurface)
                Spacer()
                Picker("Range", selection: $viewModel.selectedRange) {
                    ForEach(DashboardRange.allCases, id: \.self) { range in
                        Text(range.label).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
            }

            let curve = viewModel.equityCurve(range: viewModel.selectedRange)

            if curve.isEmpty {
                Text("No closed trades in this period.")
                    .font(.subheadline)
                    .foregroundStyle(Color.fmsMuted)
                    .frame(height: 160)
            } else {
                Chart(curve) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("P&L", point.value)
                    )
                    .foregroundStyle(Color.fmsPrimary)

                    AreaMark(
                        x: .value("Date", point.date),
                        y: .value("P&L", point.value)
                    )
                    .foregroundStyle(Color.fmsPrimary.opacity(0.15))
                }
                .frame(height: 160)
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                        AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                            .foregroundStyle(Color.fmsMuted)
                    }
                }
                .chartYAxis {
                    AxisMarks { _ in
                        AxisValueLabel()
                            .foregroundStyle(Color.fmsMuted)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.fmsSurface, in: RoundedRectangle(cornerRadius: 12))
    }
}
