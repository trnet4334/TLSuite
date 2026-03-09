import SwiftUI

public struct OptionsTradeCard: View {
    let trade: Trade

    public init(trade: Trade) { self.trade = trade }

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(contractName)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.fmsOnSurface)
                Spacer()
                pnlText
            }
            HStack {
                if let expiry = trade.expirationDate {
                    Text("Exp: \(expiry.formatted(date: .abbreviated, time: .omitted))")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.fmsMuted)
                }
                Spacer()
                Text("Qty: \(trade.positionSize, specifier: "%.0f")")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.fmsMuted)
            }
        }
        .padding(.vertical, 4)
    }

    private var contractName: String {
        let strike = trade.strikePrice.map { "$\(String(format: "%.0f", $0))" } ?? ""
        let type = trade.direction == .long ? "Call" : "Put"
        return "\(trade.asset) \(strike) \(type)"
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
