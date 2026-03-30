import SwiftUI

public struct OptionsTradeCard: View {
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
                    Text(contractName)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.fmsOnSurface)
                        .lineLimit(1)
                    Spacer()
                    pnlText
                }
                HStack {
                    if let exp = trade.expirationDate {
                        Text("\(String(localized: "journal.card.options.exp", bundle: lang.bundle)): \(exp.formatted(date: .abbreviated, time: .omitted))")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.fmsMuted)
                    }
                    if let src = trade.dataSource {
                        TradeSourceBadge(source: src)
                    }
                    Spacer()
                    Text("\(String(localized: "journal.card.options.qty", bundle: lang.bundle)): \(trade.positionSize, specifier: "%.0f")")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.fmsMuted)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(isSelected ? Color.fmsPrimary.opacity(0.06) : Color.clear)
        }
        .clipShape(Rectangle())
    }

    private var contractName: String {
        let strike = trade.strikePrice.map { "$\(String(format: "%.0f", $0))" } ?? ""
        let type = trade.direction == .long ? "Call" : "Put"
        return "\(trade.asset) \(strike) \(type)".trimmingCharacters(in: .whitespaces)
    }

    private var pnlText: some View {
        let pnl = computedPnL
        return Text(pnl >= 0 ? "+$\(pnl, specifier: "%.2f")" : "-$\(abs(pnl), specifier: "%.2f")")
            .font(.system(size: 13, weight: .semibold).monospacedDigit())
            .foregroundStyle(pnl >= 0 ? Color.fmsPrimary : Color.fmsLoss)
    }

    private var computedPnL: Double {
        guard let exit = trade.exitPrice else { return 0 }
        return (exit - trade.entryPrice) * trade.positionSize
    }
}
