import SwiftUI

public struct ForexDetailPanel: View {
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
            subtitle: "\(String(localized: "journal.detail.forex.subtitle_prefix", bundle: lang.bundle)) · \(sessionLabel)",
            viewModel: viewModel,
            onDiscard: {},
            onSave: onSave
        ) {
            metricsGrid
        }
    }

    private var sessionLabel: String {
        let hour = Calendar.current.component(.hour, from: trade.entryAt)
        switch hour {
        case 8..<12:  return String(localized: "journal.detail.forex.session.london",    bundle: lang.bundle)
        case 12..<17: return String(localized: "journal.detail.forex.session.ny",        bundle: lang.bundle)
        case 0..<8:   return String(localized: "journal.detail.forex.session.asia",      bundle: lang.bundle)
        default:      return String(localized: "journal.detail.forex.session.off_hours", bundle: lang.bundle)
        }
    }

    private var metricsGrid: some View {
        HStack(spacing: 12) {
            MetricCard(label: String(localized: "journal.detail.metric.pip_value",   bundle: lang.bundle)) {
                TextField("0.00", value: Binding(
                    get: { trade.pipValue ?? 0 },
                    set: { trade.pipValue = $0 }
                ), format: .number)
            }
            MetricCard(label: String(localized: "journal.detail.metric.lot_size",    bundle: lang.bundle)) {
                TextField("0.00", value: Binding(
                    get: { trade.lotSize ?? 0 },
                    set: { trade.lotSize = $0 }
                ), format: .number)
            }
            MetricCard(label: String(localized: "journal.detail.metric.entry_rate",  bundle: lang.bundle)) {
                TextField("0.0000", value: $trade.entryPrice, format: .number)
            }
            MetricCard(label: String(localized: "journal.detail.metric.exposure",    bundle: lang.bundle)) {
                TextField("0", value: Binding(
                    get: { trade.exposure ?? 0 },
                    set: { trade.exposure = $0 }
                ), format: .number)
            }
        }
    }
}
