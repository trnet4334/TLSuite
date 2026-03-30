import SwiftUI

public struct OptionsDetailPanel: View {
    @Environment(LanguageManager.self) private var lang
    @Bindable var trade: Trade
    let viewModel: TradeViewModel
    let onSave: () -> Void

    public init(trade: Trade, viewModel: TradeViewModel, onSave: @escaping () -> Void) {
        self.trade = trade
        self.viewModel = viewModel
        self.onSave = onSave
    }

    private var contractSubtitle: String {
        let type = trade.direction == .long
            ? String(localized: "journal.detail.options.call_bullish", bundle: lang.bundle)
            : String(localized: "journal.detail.options.put_bearish",  bundle: lang.bundle)
        if let exp = trade.expirationDate {
            return "\(type) · \(String(localized: "journal.card.options.exp", bundle: lang.bundle)) \(exp.formatted(.dateTime.month().day().year()))"
        }
        return type
    }

    public var body: some View {
        TradeDetailLayout(
            trade: trade,
            subtitle: contractSubtitle,
            viewModel: viewModel,
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
            MetricCard(label: String(localized: "journal.detail.metric.strike_price", bundle: lang.bundle)) {
                TextField("0.00", value: Binding(
                    get: { trade.strikePrice ?? 0 },
                    set: { trade.strikePrice = $0 }
                ), format: .number)
            }
            MetricCard(label: String(localized: "journal.detail.metric.expiration", bundle: lang.bundle)) {
                DatePicker("", selection: Binding(
                    get: { trade.expirationDate ?? Date() },
                    set: { trade.expirationDate = $0 }
                ), displayedComponents: .date)
                .labelsHidden()
                .font(.system(size: 13))
            }
            MetricCard(label: String(localized: "journal.detail.metric.quantity", bundle: lang.bundle)) {
                TextField("0", value: $trade.positionSize, format: .number)
            }
            MetricCard(label: String(localized: "journal.detail.metric.cost_basis", bundle: lang.bundle)) {
                TextField("0.00", value: Binding(
                    get: { trade.costBasis ?? 0 },
                    set: { trade.costBasis = $0 }
                ), format: .number)
            }
        }
    }

    private var greeksPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(String(localized: "journal.detail.options.greeks_title", bundle: lang.bundle), systemImage: "chart.line.uptrend.xyaxis")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Color.fmsOnSurface)
            HStack(spacing: 12) {
                greekCell(label: String(localized: "journal.detail.options.greek.delta", bundle: lang.bundle), value: trade.greeksDelta)
                greekCell(label: String(localized: "journal.detail.options.greek.gamma", bundle: lang.bundle), value: trade.greeksGamma)
                greekCell(label: String(localized: "journal.detail.options.greek.theta", bundle: lang.bundle), value: trade.greeksTheta)
                greekCell(label: String(localized: "journal.detail.options.greek.vega",  bundle: lang.bundle), value: trade.greeksVega)
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
