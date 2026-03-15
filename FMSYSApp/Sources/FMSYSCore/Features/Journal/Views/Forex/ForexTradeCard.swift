import SwiftUI

public struct ForexTradeCard: View {
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
                    pnlChangePill
                }
                HStack(alignment: .bottom) {
                    Text(trade.entryPrice, format: .number.precision(.fractionLength(4)))
                        .font(.system(size: 18, weight: .medium).monospacedDigit())
                        .foregroundStyle(Color.fmsOnSurface)
                    Spacer()
                    pnlText
                }
                Text(lastTradeNote)
                    .font(.system(size: 10))
                    .foregroundStyle(Color.fmsMuted)
                    .lineLimit(1)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(isSelected ? Color.fmsPrimary.opacity(0.06) : Color.clear)
        }
        .clipShape(Rectangle())
    }

    private var pnlChangePill: some View {
        let pct: Double
        if let exit = trade.exitPrice, trade.entryPrice > 0 {
            pct = ((exit - trade.entryPrice) / trade.entryPrice) * 100
        } else {
            pct = 0.0
        }
        let color: Color = pct > 0 ? Color.fmsPrimary : (pct < 0 ? Color.fmsLoss : Color.fmsMuted)
        let sign = pct >= 0 ? "+" : ""
        return Text("\(sign)\(String(format: "%.2f", pct))%")
            .font(.system(size: 10, weight: .semibold).monospacedDigit())
            .foregroundStyle(color)
    }

    private var pnlText: some View {
        let pnl = computedPnL
        return Text(pnl >= 0 ? "+$\(pnl, specifier: "%.2f")" : "-$\(abs(pnl), specifier: "%.2f")")
            .font(.system(size: 13, weight: .semibold).monospacedDigit())
            .foregroundStyle(pnl >= 0 ? Color.fmsPrimary : Color.fmsLoss)
    }

    private var lastTradeNote: String {
        let pnl = computedPnL
        if trade.exitPrice == nil { return "No active trades" }
        if pnl >= 0 { return "Last trade: Profit $\(String(format: "%.2f", pnl))" }
        return "Last trade: Loss -$\(String(format: "%.2f", abs(pnl)))"
    }

    private var computedPnL: Double {
        guard let exit = trade.exitPrice else { return 0 }
        let multiplier = trade.direction == .long ? 1.0 : -1.0
        return (exit - trade.entryPrice) * trade.positionSize * multiplier
    }
}
