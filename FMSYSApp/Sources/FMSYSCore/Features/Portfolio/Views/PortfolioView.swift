// Sources/FMSYSCore/Features/Portfolio/Views/PortfolioView.swift
import SwiftUI
import Charts

public struct PortfolioView: View {
    @Bindable var viewModel: PortfolioViewModel

    public init(viewModel: PortfolioViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        HSplitView {
            mainContent
            PortfolioInspectorPanel(viewModel: viewModel)
                .frame(width: 320)
                .background(Color.fmsSurface.opacity(0.3))
        }
    }

    // MARK: - Main Content

    private var mainContent: some View {
        ScrollView(.vertical) {
            VStack(spacing: 24) {
                kpiRow
                performanceCard
                positionsCard
            }
            .padding(24)
        }
        .frame(minWidth: 400)
        .background(Color.fmsBackground)
    }

    // MARK: - KPI Row

    private var kpiRow: some View {
        HStack(spacing: 16) {
            kpiCard(title: viewModel.selectedRange == .all ? "Total P&L" : "P&L · \(viewModel.selectedRange.rawValue)",
                    value: formatted(viewModel.totalPnL),
                    valueColor: viewModel.totalPnL >= 0 ? Color.fmsPrimary : Color.fmsLoss)
            kpiCard(title: "Daily P/L",
                    value: formatted(viewModel.dailyPnL),
                    valueColor: viewModel.dailyPnL >= 0 ? Color.fmsPrimary : Color.fmsLoss)
            kpiCard(title: "Win Rate · \(viewModel.selectedRange.rawValue)",
                    value: String(format: "%.0f%%", viewModel.winRate * 100),
                    subtitle: "\(viewModel.rangedClosedTrades.count) trades",
                    valueColor: viewModel.winRate >= 0.5 ? Color.fmsPrimary : Color.fmsLoss)
        }
    }

    @ViewBuilder
    private func kpiCard(
        title: String,
        value: String,
        subtitle: String? = nil,
        valueColor: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Color.fmsMuted)
                .textCase(.uppercase)
                .tracking(0.5)
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(value)
                    .font(.system(size: 22, weight: .heavy).monospacedDigit())
                    .foregroundStyle(valueColor)
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(valueColor)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color.fmsSurface, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.fmsMuted.opacity(0.1), lineWidth: 1))
    }

    // MARK: - Performance Chart

    private var performanceCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Portfolio Performance")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.fmsOnSurface)
                    Text("Cumulative P/L · \(viewModel.selectedRange.label)")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.fmsMuted)
                }
                Spacer()
                rangePicker
            }

            if viewModel.performanceCurve.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 32))
                        .foregroundStyle(Color.fmsMuted.opacity(0.3))
                    Text("No closed trades in this period")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.fmsMuted)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 220)
            } else {
                Chart(viewModel.performanceCurve) { point in
                    AreaMark(x: .value("Date", point.date), y: .value("Value", point.value))
                        .foregroundStyle(LinearGradient(
                            colors: [Color.fmsPrimary.opacity(0.15), Color.fmsPrimary.opacity(0)],
                            startPoint: .top, endPoint: .bottom
                        ))
                    LineMark(x: .value("Date", point.date), y: .value("Value", point.value))
                        .foregroundStyle(Color.fmsPrimary)
                        .lineStyle(StrokeStyle(lineWidth: 2))
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .month)) { _ in
                        AxisValueLabel(format: .dateTime.month(.abbreviated), centered: true)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Color.fmsMuted)
                    }
                }
                .chartYAxis(.hidden)
                .frame(height: 220)
            }
        }
        .padding(20)
        .background(Color.fmsSurface, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.fmsMuted.opacity(0.1), lineWidth: 1))
    }

    private var rangePicker: some View {
        HStack(spacing: 2) {
            ForEach(PortfolioRange.allCases, id: \.self) { range in
                Button {
                    viewModel.selectedRange = range
                } label: {
                    Text(range.rawValue)
                        .font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            viewModel.selectedRange == range
                                ? Color.fmsSurface
                                : Color.clear,
                            in: RoundedRectangle(cornerRadius: 6)
                        )
                        .foregroundStyle(Color.fmsOnSurface)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Color.fmsMuted.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Positions Table

    private var positionsCard: some View {
        VStack(spacing: 0) {
            positionsHeader
            columnHeaders
            VStack(spacing: 0) {
                ForEach(viewModel.positions) { position in
                    positionRow(position)
                    if position.id != viewModel.positions.last?.id {
                        Divider().overlay(Color.fmsMuted.opacity(0.08))
                    }
                }
            }
        }
        .background(Color.fmsSurface, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.fmsMuted.opacity(0.1), lineWidth: 1))
    }

    private var positionsHeader: some View {
        HStack {
            Text("Current Positions")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Color.fmsOnSurface)
                .textCase(.uppercase)
                .tracking(0.5)
            Spacer()
            Button("View All Positions") {}
                .buttonStyle(.plain)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(Color(red: 0.231, green: 0.510, blue: 0.965))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .overlay(alignment: .bottom) { Divider().overlay(Color.fmsMuted.opacity(0.1)) }
    }

    private var columnHeaders: some View {
        HStack {
            Text("Symbol").frame(maxWidth: .infinity, alignment: .leading)
            Text("Qty").frame(width: 80, alignment: .trailing)
            Text("Last Price").frame(width: 100, alignment: .trailing)
            Text("Market Value").frame(width: 110, alignment: .trailing)
            Text("Unrealized P/L").frame(width: 120, alignment: .trailing)
        }
        .font(.system(size: 10, weight: .bold))
        .foregroundStyle(Color.fmsMuted)
        .textCase(.uppercase)
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(Color.fmsMuted.opacity(0.05))
        .overlay(alignment: .bottom) { Divider().overlay(Color.fmsMuted.opacity(0.1)) }
    }

    @ViewBuilder
    private func positionRow(_ position: PortfolioPosition) -> some View {
        HStack {
            HStack(spacing: 8) {
                symbolBadge(for: position)
                Text(position.name)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.fmsOnSurface)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(String(format: position.qty < 1 ? "%.2f" : "%.0f", position.qty))
                .frame(width: 80, alignment: .trailing)
            Text(formatted(position.lastPrice))
                .frame(width: 100, alignment: .trailing)
            Text(formatted(position.marketValue))
                .frame(width: 110, alignment: .trailing)
            Text((position.unrealizedPnL >= 0 ? "+" : "") + formatted(abs(position.unrealizedPnL)))
                .foregroundStyle(position.unrealizedPnL >= 0 ? Color.fmsPrimary : Color.fmsLoss)
                .frame(width: 120, alignment: .trailing)
        }
        .font(.system(size: 12))
        .foregroundStyle(Color.fmsOnSurface)
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }

    @ViewBuilder
    private func symbolBadge(for position: PortfolioPosition) -> some View {
        let badgeColor: Color = switch position.id {
            case "AAPL": Color(red: 1.0,   green: 0.584, blue: 0.0)
            case "MSFT": Color(red: 0.231, green: 0.510, blue: 0.965)
            default:     Color.fmsMuted
        }
        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(badgeColor.opacity(0.2))
                .frame(width: 28, height: 28)
            Text(position.id)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(badgeColor)
        }
    }

    // MARK: - Helpers

    private static let currencyFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencySymbol = "$"
        f.maximumFractionDigits = 2
        f.minimumFractionDigits = 2
        return f
    }()

    private func formatted(_ value: Double) -> String {
        Self.currencyFormatter.string(from: NSNumber(value: value)) ?? "$\(value)"
    }
}
