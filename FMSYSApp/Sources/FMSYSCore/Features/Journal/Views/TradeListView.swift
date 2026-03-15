import SwiftUI

public struct TradeListView: View {
    @State private var viewModel: TradeViewModel
    @State private var showingEntry = false
    @State private var showingDashboard = false

    public init(viewModel: TradeViewModel) {
        self._viewModel = State(wrappedValue: viewModel)
    }

    public var body: some View {
        Group {
            if viewModel.trades.isEmpty {
                emptyState
            } else {
                tradeList
            }
        }
        .navigationTitle("Journal")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingEntry = true
                } label: {
                    Image(systemName: "plus")
                        .foregroundStyle(Color.fmsPrimary)
                }
            }
            ToolbarItem(placement: .automatic) {
                Button {
                    showingDashboard = true
                } label: {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .foregroundStyle(Color.fmsPrimary)
                }
            }
        }
        .sheet(isPresented: $showingEntry) {
            TradeEntryView(
                initialCategory: .all,
                viewModel: viewModel,
                onDismiss: { showingEntry = false }
            )
        }
        .sheet(isPresented: $showingDashboard) {
            DashboardView(trades: viewModel.trades)
                .frame(minWidth: 480, minHeight: 560)
        }
        .onAppear { viewModel.loadTrades() }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundStyle(Color.fmsMuted)
            Text("No trades yet")
                .font(.title3.bold())
                .foregroundStyle(Color.fmsOnSurface)
            Text("Tap + to log your first trade.")
                .font(.subheadline)
                .foregroundStyle(Color.fmsMuted)
        }
    }

    private var tradeList: some View {
        List {
            ForEach(viewModel.trades, id: \.id) { trade in
                TradeRowView(trade: trade)
                    .listRowBackground(Color.fmsSurface)
            }
            .onDelete { indices in
                for i in indices {
                    viewModel.deleteTrade(viewModel.trades[i])
                }
            }
        }
        .listStyle(.plain)
        .background(Color.fmsBackground)
        .scrollContentBackground(.hidden)
    }
}

private struct TradeRowView: View {
    let trade: Trade

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(trade.asset)
                        .font(.headline)
                        .foregroundStyle(Color.fmsOnSurface)
                    directionBadge
                }
                Text(trade.entryAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(Color.fmsMuted)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(trade.entryPrice, format: .number.precision(.fractionLength(5)))
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(Color.fmsOnSurface)
                if let exit = trade.exitPrice {
                    let pnl = (exit - trade.entryPrice) * (trade.direction == .long ? 1 : -1)
                    Text(pnl >= 0 ? "+\(pnl, specifier: "%.5f")" : "\(pnl, specifier: "%.5f")")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(pnl >= 0 ? Color.fmsPrimary : Color.fmsLoss)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var directionBadge: some View {
        Text(trade.direction == .long ? "LONG" : "SHORT")
            .font(.caption2.bold())
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                trade.direction == .long ? Color.fmsPrimary.opacity(0.2) : Color.fmsLoss.opacity(0.2),
                in: Capsule()
            )
            .foregroundStyle(trade.direction == .long ? Color.fmsPrimary : Color.fmsLoss)
    }
}
