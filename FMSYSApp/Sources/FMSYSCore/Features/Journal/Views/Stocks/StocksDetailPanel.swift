import SwiftUI

public struct StocksDetailPanel: View {
    @Environment(LanguageManager.self) private var lang
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
            subtitle: String(localized: "journal.detail.stocks.subtitle", bundle: lang.bundle),
            viewModel: viewModel,
            onDiscard: {},
            onSave: onSave
        ) {
            metricsGrid
        }
    }

    private var metricsGrid: some View {
        HStack(spacing: 12) {
            MetricCard(label: String(localized: "journal.detail.metric.entry_price", bundle: lang.bundle)) {
                TextField("0.00", value: $trade.entryPrice, format: .number)
            }
            MetricCard(label: String(localized: "journal.detail.metric.exit_price", bundle: lang.bundle)) {
                TextField("0.00", value: Binding(
                    get: { trade.exitPrice ?? 0 },
                    set: { trade.exitPrice = $0 }
                ), format: .number)
            }
            MetricCard(label: String(localized: "journal.detail.metric.quantity", bundle: lang.bundle)) {
                TextField("0", value: $trade.positionSize, format: .number)
            }
            MetricCard(label: String(localized: "journal.detail.metric.direction", bundle: lang.bundle)) {
                Text(trade.direction == .long
                     ? String(localized: "journal.detail.metric.direction_long",  bundle: lang.bundle)
                     : String(localized: "journal.detail.metric.direction_short", bundle: lang.bundle))
                    .foregroundStyle(trade.direction == .long ? Color.fmsPrimary : Color.fmsLoss)
            }
        }
    }
}
