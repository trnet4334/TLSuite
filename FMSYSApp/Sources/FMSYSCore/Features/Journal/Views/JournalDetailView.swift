// Sources/FMSYSCore/Features/Journal/Views/JournalDetailView.swift
import SwiftUI
import SwiftData

public struct JournalDetailView: View {
    let category: JournalCategory
    let modelContainer: ModelContainer

    @State private var viewModel: TradeViewModel
    @State private var selectedTrade: Trade?
    @State private var sortByPnL = false

    public init(category: JournalCategory, modelContainer: ModelContainer) {
        self.category = category
        self.modelContainer = modelContainer
        self._viewModel = State(wrappedValue: TradeViewModel(
            repository: TradeRepository(context: modelContainer.mainContext),
            userId: "current-user"
        ))
    }

    public var body: some View {
        HSplitView {
            TradeListPanel(
                category: category,
                trades: sortedTrades,
                selectedTrade: $selectedTrade,
                sortByPnL: $sortByPnL
            )
            .frame(minWidth: 320, maxWidth: 320)

            detailPanel
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear { viewModel.loadTrades(category: category) }
        .onChange(of: category) { _, newCategory in
            selectedTrade = nil
            viewModel.loadTrades(category: newCategory)
        }
    }

    @ViewBuilder
    private var detailPanel: some View {
        if let trade = selectedTrade {
            switch trade.journalCategory {
            case .crypto:
                CryptoDetailPanel(trade: trade, onSave: { viewModel.updateTrade(trade) })
            case .stocksETFs:
                StocksDetailPanel(trade: trade, onSave: { viewModel.updateTrade(trade) })
            case .forex:
                ForexDetailPanel(trade: trade, onSave: { viewModel.updateTrade(trade) })
            case .options:
                OptionsDetailPanel(trade: trade, onSave: { viewModel.updateTrade(trade) })
            case .all:
                StocksDetailPanel(trade: trade, onSave: { viewModel.updateTrade(trade) })
            }
        } else {
            emptyDetailState
        }
    }

    private var emptyDetailState: some View {
        VStack(spacing: 12) {
            Image(systemName: "square.and.pencil")
                .font(.system(size: 48))
                .foregroundStyle(Color.fmsMuted.opacity(0.3))
            Text("Select a trade to view details")
                .font(.system(size: 14))
                .foregroundStyle(Color.fmsMuted)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.fmsBackground)
    }

    private func pnl(_ trade: Trade) -> Double {
        guard let exit = trade.exitPrice else { return 0 }
        let multiplier = trade.direction == .long ? 1.0 : -1.0
        return (exit - trade.entryPrice) * trade.positionSize * multiplier
    }

    private var sortedTrades: [Trade] {
        sortByPnL ? viewModel.trades.sorted { pnl($0) > pnl($1) } : viewModel.trades
    }
}

