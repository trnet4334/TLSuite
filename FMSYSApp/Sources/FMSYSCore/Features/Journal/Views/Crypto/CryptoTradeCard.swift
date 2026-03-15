import SwiftUI

public struct CryptoTradeCard: View {
    let trade: Trade
    let isSelected: Bool

    public init(trade: Trade, isSelected: Bool = false) {
        self.trade = trade
        self.isSelected = isSelected
    }

    public var body: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(isSelected ? Color.fmsPrimary : Color.clear)
                .frame(width: 3)

            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(trade.asset)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.fmsOnSurface)
                    Spacer()
                    leverageBadge
                }
                HStack {
                    Text(trade.entryAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.system(size: 11))
                        .foregroundStyle(Color.fmsMuted)
                    Spacer()
                    VStack(alignment: .trailing, spacing: 1) {
                        pnlText
                        if let roe = roePercent {
                            Text(roe)
                                .font(.system(size: 10).monospacedDigit())
                                .foregroundStyle(Color.fmsMuted)
                        }
                    }
                }
                if let wallet = trade.walletAddress {
                    Text(wallet.prefix(8) + "..." + wallet.suffix(4))
                        .font(.system(size: 10).monospaced())
                        .foregroundStyle(Color.fmsMuted)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(isSelected ? Color.fmsPrimary.opacity(0.06) : Color.clear)
        }
        .clipShape(Rectangle())
    }

    private var leverageBadge: some View {
        let lev = trade.leverage ?? 1
        let isLong = trade.direction == .long
        let label = lev > 1
            ? "\(isLong ? "LONG" : "SHORT") \(String(format: "%.0f", lev))x"
            : (isLong ? "SPOT" : "SHORT")
        let color: Color = lev > 1 ? (isLong ? Color.fmsPrimary : Color.fmsLoss) : Color.fmsMuted
        return Text(label)
            .font(.system(size: 10, weight: .bold).monospaced())
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.18), in: RoundedRectangle(cornerRadius: 4))
            .foregroundStyle(color)
    }

    private var pnlText: some View {
        let pnl = computedPnL
        return Text(pnl >= 0 ? "+$\(pnl, specifier: "%.2f")" : "-$\(abs(pnl), specifier: "%.2f")")
            .font(.system(size: 13, weight: .semibold).monospacedDigit())
            .foregroundStyle(pnl >= 0 ? Color.fmsPrimary : Color.fmsLoss)
    }

    private var roePercent: String? {
        guard let exit = trade.exitPrice, trade.entryPrice > 0 else { return nil }
        let multiplier = trade.direction == .long ? 1.0 : -1.0
        let pct = ((exit - trade.entryPrice) / trade.entryPrice) * (trade.leverage ?? 1) * multiplier * 100
        let sign = pct >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f", pct))% ROE"
    }

    private var computedPnL: Double {
        guard let exit = trade.exitPrice else { return 0 }
        let multiplier = trade.direction == .long ? 1.0 : -1.0
        return (exit - trade.entryPrice) * trade.positionSize * multiplier
    }
}
