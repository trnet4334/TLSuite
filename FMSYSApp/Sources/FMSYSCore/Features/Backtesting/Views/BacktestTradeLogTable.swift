// Sources/FMSYSCore/Features/Backtesting/Views/BacktestTradeLogTable.swift
import SwiftUI

public struct BacktestTradeLogTable: View {

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
        VStack(spacing: 0) {
            tableHeader
            Divider().opacity(0.3)
            columnHeaderRow
            Divider().opacity(0.3)
            tableBody
        }
        .background(Color.fmsSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.fmsMuted.opacity(0.15), lineWidth: 1)
        )
    }

    // MARK: Subviews

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
            colHeader("Date",       width: 140)
            colHeader("Symbol",     width: 100)
            colHeader("Strategy",   width: 160)
            colHeader("Type",       width: 80)
            colHeader("Net Profit", width: 120)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.fmsMuted.opacity(0.05))
    }

    @ViewBuilder
    private var tableBody: some View {
        if result.tradeLog.isEmpty {
            Text("No trades in log")
                .font(.system(size: 12))
                .foregroundStyle(Color.fmsMuted)
                .frame(maxWidth: .infinity)
                .padding(24)
        } else {
            ForEach(result.tradeLog) { entry in
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
                .frame(width: 140, alignment: .leading)

            symbolBadge(entry.symbol)
                .frame(width: 100, alignment: .leading)

            Text(entry.strategy)
                .font(.system(size: 12))
                .foregroundStyle(Color.fmsOnSurface)
                .frame(width: 160, alignment: .leading)

            Text(entry.direction == .long ? "Long" : "Short")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(entry.direction == .long ? Color.fmsPrimary : Color.fmsLoss)
                .frame(width: 80, alignment: .leading)

            Text(
                entry.netProfit >= 0
                    ? String(format: "+$%.2f", entry.netProfit)
                    : String(format: "-$%.2f", abs(entry.netProfit))
            )
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(entry.netProfit >= 0 ? Color.fmsPrimary : Color.fmsLoss)
            .frame(width: 120, alignment: .leading)

            Spacer()

            Image(systemName: "arrow.up.right.square")
                .font(.system(size: 14))
                .foregroundStyle(Color.fmsMuted)
                .opacity(0.5)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
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
