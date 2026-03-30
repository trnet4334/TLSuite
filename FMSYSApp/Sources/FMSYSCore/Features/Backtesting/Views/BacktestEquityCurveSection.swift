// Sources/FMSYSCore/Features/Backtesting/Views/BacktestEquityCurveSection.swift
import SwiftUI
import Charts

public struct BacktestEquityCurveSection: View {

    let result: BacktestResult

    @State private var viewMode: ViewMode = .tradeByTrade
    @Environment(LanguageManager.self) private var lang

    // Fix 5 (LOW): Named constant for daily stride
    private let dailySampleStride = 5

    public init(result: BacktestResult) {
        self.result = result
    }

    // MARK: View modes

    // Fix 4 (LOW): Mark ViewMode as private
    private enum ViewMode: CaseIterable {
        case daily
        case tradeByTrade
    }

    // MARK: Body

    public var body: some View {
        // Fix 1 (HIGH): Decode equityCurve once per render pass
        let allPoints = result.equityCurve
        let lastTradeNumber = allPoints.last?.tradeNumber ?? 0
        let points = displayedPoints(from: allPoints)

        return VStack(alignment: .leading, spacing: 0) {
            headerRow
                .padding(.bottom, 16)

            chartArea(points: points, lastTradeNumber: lastTradeNumber)
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
                Text("backtest.equity_curve.title", bundle: lang.bundle)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.fmsOnSurface)
                Text(
                    String(
                        format: String(localized: "backtest.equity_curve.subtitle", bundle: lang.bundle),
                        result.totalTrades
                    )
                )
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
                Button(modeLabel(mode)) {
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

    private func modeLabel(_ mode: ViewMode) -> String {
        switch mode {
        case .daily:        return String(localized: "backtest.equity_curve.mode.daily", bundle: lang.bundle)
        case .tradeByTrade: return String(localized: "backtest.equity_curve.mode.trade_by_trade", bundle: lang.bundle)
        }
    }

    @ViewBuilder
    private func chartArea(points: [BacktestEquityPoint], lastTradeNumber: Int) -> some View {
        if points.isEmpty {
            Color.fmsMuted.opacity(0.1)
                .frame(height: 200)
                .overlay(
                    Text("backtest.equity_curve.no_data", bundle: lang.bundle)
                        .font(.system(size: 12))
                        .foregroundStyle(Color.fmsMuted)
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))
        } else {
            Chart(points, id: \.tradeNumber) { pt in
                AreaMark(
                    x: .value(String(localized: "backtest.chart.axis.trade", bundle: lang.bundle), pt.tradeNumber),
                    y: .value(String(localized: "backtest.chart.axis.equity", bundle: lang.bundle), pt.equity)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.fmsPrimary.opacity(0.3), Color.fmsPrimary.opacity(0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                LineMark(
                    x: .value(String(localized: "backtest.chart.axis.trade", bundle: lang.bundle), pt.tradeNumber),
                    y: .value(String(localized: "backtest.chart.axis.equity", bundle: lang.bundle), pt.equity)
                )
                .foregroundStyle(Color.fmsPrimary)
                .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round))
            }
            .frame(height: 200)
            // Fix 2 (HIGH): Hide decorative chart from accessibility tree
            .accessibilityHidden(true)
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 6)) { value in
                    AxisValueLabel {
                        if let v = value.as(Int.self) {
                            // Fix 3 (MEDIUM): Pass lastTradeNumber; avoids re-decoding equityCurve
                            Text(xLabel(for: v, lastTradeNumber: lastTradeNumber))
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
                            Text("$\(Int((v / 1000).rounded()))k")
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

    // Fix 1 (HIGH): Private method receives already-decoded array; no re-decode
    private func displayedPoints(from all: [BacktestEquityPoint]) -> [BacktestEquityPoint] {
        switch viewMode {
        case .tradeByTrade:
            return all
        case .daily:
            // Stub: sample every dailySampleStride-th point as proxy for "daily"
            return all.enumerated().compactMap { idx, pt in
                idx % dailySampleStride == 0 ? pt : nil
            }
        }
    }

    // Fix 3 (MEDIUM): lastTradeNumber passed in; no re-decode of equityCurve
    private func xLabel(for tradeNumber: Int, lastTradeNumber: Int) -> String {
        if tradeNumber <= 1               { return String(localized: "backtest.chart.x_label.start", bundle: lang.bundle) }
        if tradeNumber >= lastTradeNumber { return String(localized: "backtest.chart.x_label.end", bundle: lang.bundle) }
        return String(
            format: String(localized: "backtest.chart.x_label.trade", bundle: lang.bundle),
            tradeNumber
        )
    }
}
