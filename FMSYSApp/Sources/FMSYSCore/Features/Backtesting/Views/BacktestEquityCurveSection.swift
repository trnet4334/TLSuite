// Sources/FMSYSCore/Features/Backtesting/Views/BacktestEquityCurveSection.swift
import SwiftUI
import Charts

public struct BacktestEquityCurveSection: View {

    let result: BacktestResult

    @State private var viewMode: ViewMode = .tradeByTrade

    public init(result: BacktestResult) {
        self.result = result
    }

    // MARK: View modes

    enum ViewMode: String, CaseIterable {
        case daily       = "Daily"
        case tradeByTrade = "Trade-by-Trade"
    }

    // MARK: Data

    private var displayedPoints: [BacktestEquityPoint] {
        let all = result.equityCurve
        switch viewMode {
        case .tradeByTrade:
            return all
        case .daily:
            // Stub: sample every 5th point as proxy for "daily"
            return all.enumerated().compactMap { idx, pt in idx % 5 == 0 ? pt : nil }
        }
    }

    // MARK: Body

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerRow
                .padding(.bottom, 16)

            chartArea
        }
        .padding(20)
        .background(Color.fmsSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.fmsMuted.opacity(0.15), lineWidth: 1)
        )
    }

    // MARK: Subviews

    private var headerRow: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Equity Curve")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.fmsOnSurface)
                Text("Cumulative Net Profit over \(result.totalTrades) trades")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.fmsMuted)
            }
            Spacer()
            modePicker
        }
    }

    private var modePicker: some View {
        HStack(spacing: 2) {
            ForEach(ViewMode.allCases, id: \.self) { mode in
                Button(mode.rawValue) {
                    viewMode = mode
                }
                .font(.system(size: 10, weight: .bold))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    viewMode == mode
                        ? Color.fmsOnSurface.opacity(0.12)
                        : Color.clear,
                    in: RoundedRectangle(cornerRadius: 6)
                )
                .foregroundStyle(
                    viewMode == mode ? Color.fmsOnSurface : Color.fmsMuted
                )
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Color.fmsMuted.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
    }

    @ViewBuilder
    private var chartArea: some View {
        if displayedPoints.isEmpty {
            Color.fmsMuted.opacity(0.1)
                .frame(height: 200)
                .overlay(
                    Text("No equity data")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.fmsMuted)
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))
        } else {
            Chart(displayedPoints, id: \.tradeNumber) { pt in
                AreaMark(
                    x: .value("Trade", pt.tradeNumber),
                    y: .value("Equity", pt.equity)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.fmsPrimary.opacity(0.3), Color.fmsPrimary.opacity(0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                LineMark(
                    x: .value("Trade", pt.tradeNumber),
                    y: .value("Equity", pt.equity)
                )
                .foregroundStyle(Color.fmsPrimary)
                .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round))
            }
            .frame(height: 200)
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 6)) { value in
                    AxisValueLabel {
                        if let v = value.as(Int.self) {
                            Text(xLabel(for: v))
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(Color.fmsMuted)
                                .textCase(.uppercase)
                        }
                    }
                    AxisGridLine().foregroundStyle(Color.fmsMuted.opacity(0.1))
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let v = value.as(Double.self) {
                            Text("$\(Int(v / 1000))k")
                                .font(.system(size: 9))
                                .foregroundStyle(Color.fmsMuted)
                        }
                    }
                    AxisGridLine().foregroundStyle(Color.fmsMuted.opacity(0.1))
                }
            }
        }
    }

    // MARK: Helpers

    private func xLabel(for tradeNumber: Int) -> String {
        guard let last = result.equityCurve.last else { return "" }
        if tradeNumber <= 1         { return "Start" }
        if tradeNumber >= last.tradeNumber { return "End" }
        return "Trade \(tradeNumber)"
    }
}
