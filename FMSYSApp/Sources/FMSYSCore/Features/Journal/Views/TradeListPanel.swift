// Sources/FMSYSCore/Features/Journal/Views/TradeListPanel.swift
import SwiftUI

public struct TradeListPanel: View {
    let category: JournalCategory
    let trades: [Trade]
    @Binding var selectedTrade: Trade?
    @Binding var sortByPnL: Bool

    @State private var activeFilter: String = "All"

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
            filterBar
            Divider()
            if filteredTrades.isEmpty {
                emptyState
            } else {
                tradeList
            }
        }
        .background(Color.fmsSurface)
        .onChange(of: category) { _, _ in activeFilter = "All" }
    }

    @ViewBuilder
    private var filterBar: some View {
        switch category {
        case .all:
            EmptyView()
        case .stocksETFs:
            segmentedFilter(options: ["All", "Buy", "Sell"])
        case .crypto:
            segmentedFilter(options: ["All", "Spot", "Futures"])
        case .forex:
            EmptyView()
        case .options:
            segmentedFilter(options: ["All", "Call", "Put"])
        }
    }

    private func segmentedFilter(options: [String]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(options, id: \.self) { opt in
                    Button(opt) { activeFilter = opt }
                        .buttonStyle(.plain)
                        .font(.system(size: 11, weight: activeFilter == opt ? .bold : .regular))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            activeFilter == opt ? Color.fmsPrimary.opacity(0.15) : Color.clear,
                            in: Capsule()
                        )
                        .foregroundStyle(activeFilter == opt ? Color.fmsPrimary : Color.fmsMuted)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
        }
    }

    private var filteredTrades: [Trade] {
        guard activeFilter != "All" else { return trades }
        switch category {
        case .stocksETFs:
            if activeFilter == "Buy"  { return trades.filter { $0.direction == .long } }
            if activeFilter == "Sell" { return trades.filter { $0.direction == .short } }
        case .crypto:
            if activeFilter == "Spot"    { return trades.filter { ($0.leverage ?? 1) <= 1 } }
            if activeFilter == "Futures" { return trades.filter { ($0.leverage ?? 1) > 1 } }
        case .options:
            if activeFilter == "Call" { return trades.filter { $0.direction == .long } }
            if activeFilter == "Put"  { return trades.filter { $0.direction == .short } }
        default: break
        }
        return trades
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
        List(filteredTrades, id: \.id, selection: $selectedTrade) { trade in
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
