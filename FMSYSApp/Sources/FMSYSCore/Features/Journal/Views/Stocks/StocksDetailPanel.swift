import SwiftUI

public struct StocksDetailPanel: View {
    @Bindable var trade: Trade
    let viewModel: TradeViewModel
    let onSave: () -> Void

    public init(trade: Trade, viewModel: TradeViewModel, onSave: @escaping () -> Void) {
        self.trade = trade
        self.viewModel = viewModel
        self.onSave = onSave
    }

    public var body: some View {
        TradeDetailLayout(
            trade: trade,
            subtitle: "Stocks & ETFs",
            viewModel: viewModel,
            onDiscard: {},
            onSave: onSave
        ) {
            metricsGrid
        }
    }

    private var metricsGrid: some View {
        HStack(spacing: 12) {
            MetricCard(label: "Entry Price") {
                TextField("0.00", value: $trade.entryPrice, format: .number)
            }
            MetricCard(label: "Exit Price") {
                TextField("0.00", value: Binding(
                    get: { trade.exitPrice ?? 0 },
                    set: { trade.exitPrice = $0 }
                ), format: .number)
            }
            MetricCard(label: "Quantity") {
                TextField("0", value: $trade.positionSize, format: .number)
            }
            MetricCard(label: "Direction") {
                Text(trade.direction == .long ? "Long" : "Short")
                    .foregroundStyle(trade.direction == .long ? Color.fmsPrimary : Color.fmsLoss)
            }
        }
    }
}
