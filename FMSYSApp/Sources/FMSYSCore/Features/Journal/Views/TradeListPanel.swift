// Sources/FMSYSCore/Features/Journal/Views/TradeListPanel.swift
import SwiftUI
import UniformTypeIdentifiers

public struct TradeListPanel: View {
    let category: JournalCategory
    let trades: [Trade]
    @Binding var selectedTrade: Trade?
    @Binding var sortByPnL: Bool
    let onNewTrade: () -> Void
    let onImport: ([Trade]) -> Void

    @State private var activeFilter: String = "All"
    @State private var showingCSVPicker    = false
    @State private var showingMapping      = false
    @State private var showingPreview      = false
    @State private var csvText             = ""
    @State private var csvHeaders: [String] = []
    @State private var csvPreviewRows: [[String]] = []
    @State private var importResult: CSVImportResult?
    @State private var importFormat: BrokerFormat = .unknown

    public init(
        category: JournalCategory,
        trades: [Trade],
        selectedTrade: Binding<Trade?>,
        sortByPnL: Binding<Bool>,
        onNewTrade: @escaping () -> Void,
        onImport: @escaping ([Trade]) -> Void = { _ in }
    ) {
        self.category = category
        self.trades = trades
        self._selectedTrade = selectedTrade
        self._sortByPnL = sortByPnL
        self.onNewTrade = onNewTrade
        self.onImport = onImport
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
        .fileImporter(
            isPresented: $showingCSVPicker,
            allowedContentTypes: [.commaSeparatedText, .plainText]
        ) { result in
            guard let url = try? result.get(),
                  url.startAccessingSecurityScopedResource() else { return }
            defer { url.stopAccessingSecurityScopedResource() }
            guard let text = try? String(contentsOf: url, encoding: .utf8) else { return }
            csvText = text
            let service = CSVImportService()
            let analysis = service.analyze(csvText: text)
            csvHeaders = analysis.headers
            csvPreviewRows = analysis.preview
            importFormat = analysis.format
            if analysis.format == .unknown {
                showingMapping = true
            } else {
                let res = service.map(csvText: text, format: analysis.format)
                importResult = res
                showingPreview = true
            }
        }
        .sheet(isPresented: $showingMapping) {
            ColumnMappingSheet(
                csvHeaders: csvHeaders,
                preview: csvPreviewRows,
                onConfirm: { mapping in
                    let service = CSVImportService()
                    let res = service.map(csvText: csvText, format: .unknown, columnMapping: mapping)
                    importResult = res
                    showingMapping = false
                    showingPreview = true
                },
                onCancel: { showingMapping = false }
            )
        }
        .sheet(isPresented: $showingPreview) {
            if let result = importResult {
                ImportPreviewSheet(
                    result: result,
                    onConfirm: {
                        onImport(result.trades)
                        showingPreview = false
                    },
                    onCancel: { showingPreview = false }
                )
            }
        }
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
                showingCSVPicker = true
            } label: {
                Image(systemName: "square.and.arrow.down")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.fmsMuted)
            }
            .buttonStyle(.plain)
            .help("Import trades from CSV")
            .padding(.trailing, 4)
            Button {
                onNewTrade()
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.fmsPrimary)
            }
            .buttonStyle(.plain)
            .padding(.trailing, 6)
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
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    @ViewBuilder
    private func tradeCard(_ trade: Trade) -> some View {
        let selected = selectedTrade?.id == trade.id
        switch trade.journalCategory {
        case .crypto:  CryptoTradeCard(trade: trade, isSelected: selected)
        case .forex:   ForexTradeCard(trade: trade, isSelected: selected)
        case .options: OptionsTradeCard(trade: trade, isSelected: selected)
        default:       StocksTradeCard(trade: trade, isSelected: selected)
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
            Button("+ Log First Trade") { onNewTrade() }
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
