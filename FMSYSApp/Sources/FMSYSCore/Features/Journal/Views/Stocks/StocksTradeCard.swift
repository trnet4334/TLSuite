import SwiftUI

public struct StocksTradeCard: View {
    @Environment(LanguageManager.self) private var lang
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
                    directionBadge
                }
                HStack {
                    Text(String(format: "$%.2f · %.0f \(String(localized: "journal.card.shares", bundle: lang.bundle))", trade.entryPrice, trade.positionSize))
                        .font(.system(size: 12))
                        .foregroundStyle(Color.fmsMuted)
                    Spacer()
                    pnlText
                }
                HStack(spacing: 6) {
                    Text(trade.entryAt.formatted(date: .abbreviated, time: .omitted))
                        .font(.system(size: 11))
                        .foregroundStyle(Color.fmsMuted)
                    if let src = trade.dataSource {
                        TradeSourceBadge(source: src)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(isSelected ? Color.fmsPrimary.opacity(0.06) : Color.clear)
        }
        .clipShape(Rectangle())
    }

    private var directionBadge: some View {
        Text(trade.direction == .long
             ? String(localized: "journal.card.buy", bundle: lang.bundle)
             : String(localized: "journal.card.sell", bundle: lang.bundle))
            .font(.system(size: 10, weight: .bold))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                trade.direction == .long ? Color.fmsPrimary.opacity(0.18) : Color.fmsLoss.opacity(0.18),
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
