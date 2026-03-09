// Sources/FMSYSCore/Features/Journal/Views/TradeListPanel.swift
import SwiftUI

public struct TradeListPanel: View {
    let category: JournalCategory
    let trades: [Trade]
    @Binding var selectedTrade: Trade?
    @Binding var sortByPnL: Bool

    public init(
        category: JournalCategory,
        trades: [Trade],
        selectedTrade: Binding<Trade?>,
        sortByPnL: Binding<Bool>
    ) {
        self.category = category
        self.trades = trades
        self._selectedTrade = selectedTrade
        self._sortByPnL = sortByPnL
    }

    public var body: some View {
        VStack(spacing: 0) {
            listHeader
            Divider()
            if trades.isEmpty {
                emptyState
            } else {
                tradeList
            }
        }
        .background(Color.fmsSurface)
    }

    private var listHeader: some View {
        HStack {
            Text(category == .all ? "All Trades" : category.rawValue)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Color.fmsMuted)
                .textCase(.uppercase)
            Spacer()
            Button {
                sortByPnL.toggle()
            } label: {
                Label(sortByPnL ? "P&L" : "Newest", systemImage: "arrow.up.arrow.down")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.fmsMuted)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private var tradeList: some View {
        List(trades, id: \.id, selection: $selectedTrade) { trade in
            tradeCard(trade)
                .tag(trade)
                .listRowBackground(
                    selectedTrade?.id == trade.id
                        ? Color.fmsPrimary.opacity(0.08)
                        : Color.clear
                )
                .listRowInsets(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    @ViewBuilder
    private func tradeCard(_ trade: Trade) -> some View {
        switch trade.journalCategory {
        case .crypto:  CryptoTradeCard(trade: trade)
        case .forex:   ForexTradeCard(trade: trade)
        case .options: OptionsTradeCard(trade: trade)
        default:       StocksTradeCard(trade: trade)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "square.and.pencil")
                .font(.system(size: 48))
                .foregroundStyle(Color.fmsMuted.opacity(0.3))
            Text("Start Your Trading Journal")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.fmsOnSurface)
            Text("Record your first trade to begin\ntracking performance.")
                .font(.system(size: 13))
                .foregroundStyle(Color.fmsMuted)
                .multilineTextAlignment(.center)
            Button("+ Log First Trade") {}
                .buttonStyle(.plain)
                .font(.system(size: 13, weight: .semibold))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.fmsPrimary, in: RoundedRectangle(cornerRadius: 8))
                .foregroundStyle(Color.fmsBackground)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}
