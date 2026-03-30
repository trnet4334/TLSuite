import SwiftUI

public struct CryptoDetailPanel: View {
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
            subtitle: subtitle,
            viewModel: viewModel,
            onDiscard: {},
            onSave: onSave
        ) {
            VStack(spacing: 16) {
                metricsGrid
                if trade.walletAddress != nil {
                    walletRow
                }
            }
        }
    }

    private var subtitle: String {
        if let lev = trade.leverage, lev > 1 {
            return "\(String(localized: "journal.detail.crypto.futures", bundle: lang.bundle)) · \(String(format: "%.0f", lev))x \(String(localized: "journal.detail.crypto.leverage", bundle: lang.bundle))"
        }
        return String(localized: "journal.detail.crypto.spot", bundle: lang.bundle)
    }

    private var metricsGrid: some View {
        HStack(spacing: 12) {
            MetricCard(label: String(localized: "journal.detail.metric.entry_price",   bundle: lang.bundle)) {
                TextField("0.00", value: $trade.entryPrice, format: .number)
            }
            MetricCard(label: String(localized: "journal.detail.metric.exit_price",    bundle: lang.bundle)) {
                TextField("0.00", value: Binding(
                    get: { trade.exitPrice ?? 0 },
                    set: { trade.exitPrice = $0 }
                ), format: .number)
            }
            MetricCard(label: String(localized: "journal.detail.metric.leverage",      bundle: lang.bundle)) {
                TextField("1x", value: Binding(
                    get: { trade.leverage ?? 1 },
                    set: { trade.leverage = $0 }
                ), format: .number)
            }
            MetricCard(label: String(localized: "journal.detail.metric.funding_rate",  bundle: lang.bundle)) {
                TextField("0.0000%", value: Binding(
                    get: { trade.fundingRate ?? 0 },
                    set: { trade.fundingRate = $0 }
                ), format: .number)
            }
        }
    }

    private var walletRow: some View {
        HStack(spacing: 12) {
            Image(systemName: "wallet.pass")
                .font(.system(size: 16))
                .foregroundStyle(Color.fmsPrimary)
                .frame(width: 36, height: 36)
                .background(Color.fmsPrimary.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text("journal.detail.crypto.executing_wallet", bundle: lang.bundle)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color.fmsMuted)
                    .tracking(0.5)
                Text(trade.walletAddress ?? "—")
                    .font(.system(size: 12).monospaced())
                    .foregroundStyle(Color.fmsOnSurface)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer()

            Button {
                if let addr = trade.walletAddress {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(addr, forType: .string)
                }
            } label: {
                Label(String(localized: "journal.detail.crypto.copy", bundle: lang.bundle), systemImage: "doc.on.doc")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.fmsPrimary)
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(Color.fmsPrimary.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.fmsPrimary.opacity(0.2), lineWidth: 1)
        )
    }
}
