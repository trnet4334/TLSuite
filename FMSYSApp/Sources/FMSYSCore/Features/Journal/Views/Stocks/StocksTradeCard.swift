import SwiftUI

public struct StocksTradeCard: View {
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
                Text("$\(trade.entryPrice, specifier: "%.2f") · \(trade.positionSize, specifier: "%.0f") shares")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.fmsMuted)
                Spacer()
                pnlText
            }
            Text(trade.entryAt.formatted(date: .abbreviated, time: .omitted))
                .font(.system(size: 11))
                .foregroundStyle(Color.fmsMuted)
        }
        .padding(.vertical, 4)
    }

    private var directionBadge: some View {
        Text(trade.direction == .long ? "BUY" : "SELL")
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
