// Sources/FMSYSCore/Features/Backtesting/Views/BacktestTradeLogTable.swift
import SwiftUI

public struct BacktestTradeLogTable: View {

    private enum ColumnWidth {
        static let date:     CGFloat = 140
        static let symbol:   CGFloat = 100
        static let strategy: CGFloat = 160
        static let type:     CGFloat = 80
        static let profit:   CGFloat = 120
    }

    let result: BacktestResult

    public init(result: BacktestResult) {
        self.result = result
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d, HH:mm"
        return f
    }()

    public var body: some View {
        let trades = result.tradeLog     // decode once

        return VStack(spacing: 0) {
            tableHeader
            Divider().opacity(0.3)
            columnHeaderRow
            Divider().opacity(0.3)
            tableBody(trades: trades)
        }
        .background(Color.fmsSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.fmsMuted.opacity(0.15), lineWidth: 1)
        )
    }

    // MARK: Header

    private var tableHeader: some View {
        HStack {
            Text("Detailed Test Results")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(Color.fmsMuted)
                .tracking(0.8)
                .textCase(.uppercase)
            Spacer()
            HStack(spacing: 4) {
                toolbarBtn(systemName: "line.3.horizontal.decrease")
                toolbarBtn(systemName: "arrow.down.circle")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.fmsSurface.opacity(0.5))
    }

    private var columnHeaderRow: some View {
        HStack(spacing: 0) {
            colHeader("Date",       width: ColumnWidth.date)
            colHeader("Symbol",     width: ColumnWidth.symbol)
            colHeader("Strategy",   width: ColumnWidth.strategy)
            colHeader("Type",       width: ColumnWidth.type)
            colHeader("Net Profit", width: ColumnWidth.profit)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.fmsMuted.opacity(0.05))
    }

    // MARK: Table body

    @ViewBuilder
    private func tableBody(trades: [BacktestTradeEntry]) -> some View {
        if trades.isEmpty {
            Text("No trades in log")
                .font(.system(size: 12))
                .foregroundStyle(Color.fmsMuted)
                .frame(maxWidth: .infinity)
                .padding(24)
        } else {
            ForEach(trades) { entry in
                tradeRow(entry)
                Divider()
                    .opacity(0.15)
                    .padding(.horizontal, 16)
            }
        }
    }

    // MARK: Row

    @ViewBuilder
    private func tradeRow(_ entry: BacktestTradeEntry) -> some View {
        HStack(spacing: 0) {
            Text(Self.dateFormatter.string(from: entry.date))
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.fmsOnSurface)
                .frame(width: ColumnWidth.date, alignment: .leading)

            symbolBadge(entry.symbol)
                .frame(width: ColumnWidth.symbol, alignment: .leading)

            Text(entry.strategy)
                .font(.system(size: 12))
                .foregroundStyle(Color.fmsOnSurface)
                .frame(width: ColumnWidth.strategy, alignment: .leading)

            Text(entry.direction == .long ? "Long" : "Short")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(entry.direction == .long ? Color.fmsPrimary : Color.fmsLoss)
                .frame(width: ColumnWidth.type, alignment: .leading)

            Text(profitText(entry.netProfit))
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(profitColor(entry.netProfit))
                .frame(width: ColumnWidth.profit, alignment: .leading)

            Spacer()

            Image(systemName: "arrow.up.right.square")
                .font(.system(size: 14))
                .foregroundStyle(Color.fmsMuted)
                .opacity(0.5)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(rowAccessibilityLabel(entry))
    }

    private func rowAccessibilityLabel(_ entry: BacktestTradeEntry) -> String {
        let direction = entry.direction == .long ? "Long" : "Short"
        let profit = entry.netProfit >= 0
            ? String(format: "+$%.2f", entry.netProfit)
            : String(format: "-$%.2f", abs(entry.netProfit))
        let dateStr = Self.dateFormatter.string(from: entry.date)
        return "\(entry.symbol), \(direction), \(profit), \(dateStr)"
    }

    private func profitText(_ value: Double) -> String {
        if value > 0 { return String(format: "+$%.2f", value) }
        if value < 0 { return String(format: "-$%.2f", abs(value)) }
        return String(format: "$%.2f", value)  // zero: neutral display
    }

    private func profitColor(_ value: Double) -> Color {
        if value > 0 { return Color.fmsPrimary }
        if value < 0 { return Color.fmsLoss }
        return Color.fmsMuted  // zero: neutral
    }

    // MARK: Helpers

    @ViewBuilder
    private func symbolBadge(_ symbol: String) -> some View {
        let color = badgeColor(for: symbol)
        Text(symbol)
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 4))
    }

    private func badgeColor(for symbol: String) -> Color {
        if symbol.hasPrefix("BTC") { return .blue }
        if symbol.hasPrefix("ETH") { return .purple }
        if symbol.hasPrefix("SOL") { return .orange }
        return Color.fmsMuted
    }

    @ViewBuilder
    private func colHeader(_ title: String, width: CGFloat) -> some View {
        Text(title.uppercased())
            .font(.system(size: 9, weight: .bold))
            .foregroundStyle(Color.fmsMuted)
            .tracking(0.8)
            .frame(width: width, alignment: .leading)
            .accessibilityAddTraits(.isHeader)
    }

    @ViewBuilder
    private func toolbarBtn(systemName: String) -> some View {
        Button {
            // stub — filter/download not implemented
        } label: {
            Image(systemName: systemName)
                .font(.system(size: 14))
                .foregroundStyle(Color.fmsMuted)
                .frame(width: 28, height: 28)
                .background(Color.fmsMuted.opacity(0.08), in: RoundedRectangle(cornerRadius: 6))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.fmsMuted.opacity(0.2), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}
