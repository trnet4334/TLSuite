// Sources/FMSYSCore/Features/Journal/Views/JournalDetailView.swift
import SwiftUI

public struct JournalDetailView: View {
    let category: JournalCategory
    @Bindable var viewModel: TradeViewModel

    @State private var selectedTrade: Trade?
    @State private var sortByPnL = false
    @State private var showingEntry = false

    public init(viewModel: TradeViewModel, category: JournalCategory) {
        self.viewModel = viewModel
        self.category = category
    }

    public var body: some View {
        ZStack {
            HSplitView {
                TradeListPanel(
                    category: category,
                    trades: sortedTrades,
                    selectedTrade: $selectedTrade,
                    sortByPnL: $sortByPnL,
                    onNewTrade: { showingEntry = true },
                    onImport: { viewModel.importTrades($0) }
                )
                .frame(minWidth: 320, maxWidth: 320)

                detailPanel
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            if showingEntry {
                TradeEntryView(
                    initialCategory: category,
                    viewModel: viewModel,
                    onDismiss: {
                        showingEntry = false
                        viewModel.loadTrades(category: category)
                    }
                )
            }
        }
        .onAppear {
            viewModel.loadTrades(category: category)
            selectedTrade = sortedTrades.first
        }
        .onChange(of: category) { _, newCategory in
            showingEntry = false
            viewModel.loadTrades(category: newCategory)
            selectedTrade = sortedTrades.first
        }
        .onChange(of: sortByPnL) { _, _ in
            selectedTrade = sortedTrades.first
        }
        .onChange(of: viewModel.trades) { _, _ in
            if selectedTrade == nil {
                selectedTrade = sortedTrades.first
            }
        }
    }

    @ViewBuilder
    private var detailPanel: some View {
        if let trade = selectedTrade {
            switch trade.journalCategory {
            case .crypto:
                CryptoDetailPanel(trade: trade, viewModel: viewModel, onSave: { viewModel.updateTrade(trade) })
            case .stocksETFs:
                StocksDetailPanel(trade: trade, viewModel: viewModel, onSave: { viewModel.updateTrade(trade) })
            case .forex:
                ForexDetailPanel(trade: trade, viewModel: viewModel, onSave: { viewModel.updateTrade(trade) })
            case .options:
                OptionsDetailPanel(trade: trade, viewModel: viewModel, onSave: { viewModel.updateTrade(trade) })
            case .all:
                StocksDetailPanel(trade: trade, viewModel: viewModel, onSave: { viewModel.updateTrade(trade) })
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
