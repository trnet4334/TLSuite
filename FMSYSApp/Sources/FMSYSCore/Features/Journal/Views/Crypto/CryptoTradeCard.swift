import SwiftUI

public struct CryptoTradeCard: View {
    let trade: Trade

    public init(trade: Trade) { self.trade = trade }

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(trade.asset)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.fmsOnSurface)
                Spacer()
                directionBadge
            }
            HStack {
                if let leverage = trade.leverage {
                    Text("\(trade.direction == .long ? "LONG" : "SHORT") \(leverage, specifier: "%.0f")x")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.fmsMuted)
                }
                Spacer()
                pnlText
            }
            HStack {
                Text(trade.entryAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 11))
                    .foregroundStyle(Color.fmsMuted)
                if let wallet = trade.walletAddress {
                    Spacer()
                    Text(String(wallet.prefix(8)) + "...")
                        .font(.system(size: 10).monospaced())
                        .foregroundStyle(Color.fmsMuted)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var directionBadge: some View {
        Text(trade.direction == .long ? "LONG" : "SHORT")
            .font(.system(size: 10, weight: .bold))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                trade.direction == .long ? Color.fmsPrimary.opacity(0.2) : Color.fmsLoss.opacity(0.2),
                in: RoundedRectangle(cornerRadius: 4)
            )
            .foregroundStyle(trade.direction == .long ? Color.fmsPrimary : Color.fmsLoss)
    }

    private var pnlText: some View {
        let pnl = computedPnL
        return Text(pnl >= 0 ? "+$\(pnl, specifier: "%.2f")" : "-$\(abs(pnl), specifier: "%.2f")")
            .font(.system(size: 13, weight: .semibold).monospacedDigit())
            .foregroundStyle(pnl >= 0 ? Color.fmsPrimary : Color.fmsLoss)
    }

    private var computedPnL: Double {
        guard let exit = trade.exitPrice else { return 0 }
        let multiplier = trade.direction == .long ? 1.0 : -1.0
        return (exit - trade.entryPrice) * trade.positionSize * multiplier
    }
}
