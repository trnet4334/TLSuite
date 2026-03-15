import SwiftUI

public struct ForexDetailPanel: View {
    @Bindable var trade: Trade
    let onSave: () -> Void

    public init(trade: Trade, onSave: @escaping () -> Void) {
        self.trade = trade
        self.onSave = onSave
    }

    public var body: some View {
        TradeDetailLayout(
            trade: trade,
            subtitle: "Active Trade Analysis · \(sessionLabel)",
            onDiscard: {},
            onSave: onSave
        ) {
            metricsGrid
        }
    }

    private var sessionLabel: String {
        let hour = Calendar.current.component(.hour, from: trade.entryAt)
        switch hour {
        case 8..<12:  return "London Session"
        case 12..<17: return "NY Session"
        case 0..<8:   return "Asia Session"
        default:      return "Off-Hours"
        }
    }

    private var metricsGrid: some View {
        HStack(spacing: 12) {
            MetricCard(label: "Pip Value") {
                TextField("0.00", value: Binding(
                    get: { trade.pipValue ?? 0 },
                    set: { trade.pipValue = $0 }
                ), format: .number)
            }
            MetricCard(label: "Lot Size") {
                TextField("0.00", value: Binding(
                    get: { trade.lotSize ?? 0 },
                    set: { trade.lotSize = $0 }
                ), format: .number)
            }
            MetricCard(label: "Entry Rate") {
                TextField("0.0000", value: $trade.entryPrice, format: .number)
            }
            MetricCard(label: "Exposure") {
                TextField("0", value: Binding(
                    get: { trade.exposure ?? 0 },
                    set: { trade.exposure = $0 }
                ), format: .number)
            }
        }
    }
}
