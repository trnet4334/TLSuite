import SwiftUI

public struct OptionsDetailPanel: View {
    @Bindable var trade: Trade
    let onSave: () -> Void

    public init(trade: Trade, onSave: @escaping () -> Void) {
        self.trade = trade
        self.onSave = onSave
    }

    private var contractSubtitle: String {
        let type = trade.direction == .long ? "Call · Bullish Long" : "Put · Bearish Short"
        if let exp = trade.expirationDate {
            return "\(type) · Exp \(exp.formatted(.dateTime.month().day().year()))"
        }
        return type
    }

    public var body: some View {
        TradeDetailLayout(
            trade: trade,
            subtitle: contractSubtitle,
            onDiscard: {},
            onSave: onSave
        ) {
            VStack(spacing: 16) {
                metricsGrid
                greeksPanel
            }
        }
    }

    private var metricsGrid: some View {
        HStack(spacing: 12) {
            MetricCard(label: "Strike Price") {
                TextField("0.00", value: Binding(
                    get: { trade.strikePrice ?? 0 },
                    set: { trade.strikePrice = $0 }
                ), format: .number)
            }
            MetricCard(label: "Expiration") {
                DatePicker("", selection: Binding(
                    get: { trade.expirationDate ?? Date() },
                    set: { trade.expirationDate = $0 }
                ), displayedComponents: .date)
                .labelsHidden()
                .font(.system(size: 13))
            }
            MetricCard(label: "Quantity") {
                TextField("0", value: $trade.positionSize, format: .number)
            }
            MetricCard(label: "Cost Basis") {
                TextField("0.00", value: Binding(
                    get: { trade.costBasis ?? 0 },
                    set: { trade.costBasis = $0 }
                ), format: .number)
            }
        }
    }

    private var greeksPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Option Greeks", systemImage: "chart.line.uptrend.xyaxis")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Color.fmsOnSurface)
            HStack(spacing: 12) {
                greekCell(label: "Delta", value: trade.greeksDelta)
                greekCell(label: "Gamma", value: trade.greeksGamma)
                greekCell(label: "Theta", value: trade.greeksTheta)
                greekCell(label: "Vega",  value: trade.greeksVega)
            }
            .padding(16)
            .background(Color.fmsSurface, in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.fmsMuted.opacity(0.12), lineWidth: 1)
            )
        }
    }

    private func greekCell(label: String, value: Double?) -> some View {
        VStack(spacing: 4) {
            Text(label.uppercased())
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(Color.fmsMuted)
                .tracking(0.5)
            Text(value.map { String(format: "%.3f", $0) } ?? "—")
                .font(.system(size: 16, weight: .bold).monospacedDigit())
                .foregroundStyle(Color.fmsOnSurface)
        }
        .frame(maxWidth: .infinity)
    }
}
