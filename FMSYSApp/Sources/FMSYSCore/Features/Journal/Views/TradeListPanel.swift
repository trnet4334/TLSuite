// Sources/FMSYSCore/Features/Journal/Views/TradeListPanel.swift
import SwiftUI
import AppKit

public struct TradeListPanel: View {
    @Environment(LanguageManager.self) private var lang
    let category: JournalCategory
    let trades: [Trade]
    @Binding var selectedTrade: Trade?
    @Binding var sortByPnL: Bool
    let onNewTrade: () -> Void
    let onImport: ([Trade]) -> Void

    @State private var activeFilter: String = "all"
    @State private var showingMapping      = false
    @State private var showingPreview      = false
    @State private var csvText             = ""
    @State private var csvFileName         = ""
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
        .onChange(of: category) { _, _ in activeFilter = "all" }
        .sheet(isPresented: $showingMapping) {
            ColumnMappingSheet(
                csvHeaders: csvHeaders,
                preview: csvPreviewRows,
                onConfirm: { mapping in
                    let service = CSVImportService()
                    let res = service.map(csvText: csvText, format: .unknown,
                                         columnMapping: mapping,
                                         sourceLabel: "CSV: \(csvFileName)")
                    importResult = res
                    showingMapping = false
                    showingPreview = true
                },
                onCancel: { showingMapping = false }
            )
            .environment(LanguageManager.shared)
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
                .environment(LanguageManager.shared)
            }
        }
    }

    // MARK: - CSV file picking via NSOpenPanel (avoids SwiftUI sheet conflict)

    private func openCSVFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.commaSeparatedText, .plainText]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.title = String(localized: "journal.list.import_panel_title", bundle: lang.bundle)
        panel.prompt = String(localized: "journal.list.import_panel_prompt", bundle: lang.bundle)

        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            guard url.startAccessingSecurityScopedResource() else { return }
            defer { url.stopAccessingSecurityScopedResource() }
            guard let text = try? String(contentsOf: url, encoding: .utf8) else { return }

            let service = CSVImportService()
            let analysis = service.analyze(csvText: text)
            let fileName = url.lastPathComponent

            DispatchQueue.main.async {
                csvText = text
                csvFileName = fileName
                csvHeaders = analysis.headers
                csvPreviewRows = analysis.preview
                importFormat = analysis.format

                if analysis.format == .unknown {
                    showingMapping = true
                } else {
                    importResult = service.map(csvText: text, format: analysis.format,
                                              sourceLabel: "CSV: \(fileName)")
                    showingPreview = true
                }
            }
        }
    }

    // MARK: - Filter bar

    @ViewBuilder
    private var filterBar: some View {
        switch category {
        case .all:
            EmptyView()
        case .stocksETFs:
            segmentedFilter(options: [
                ("all",  String(localized: "journal.filter.all",     bundle: lang.bundle)),
                ("buy",  String(localized: "journal.filter.buy",     bundle: lang.bundle)),
                ("sell", String(localized: "journal.filter.sell",    bundle: lang.bundle))
            ])
        case .crypto:
            segmentedFilter(options: [
                ("all",     String(localized: "journal.filter.all",     bundle: lang.bundle)),
                ("spot",    String(localized: "journal.filter.spot",    bundle: lang.bundle)),
                ("futures", String(localized: "journal.filter.futures", bundle: lang.bundle))
            ])
        case .forex:
            EmptyView()
        case .options:
            segmentedFilter(options: [
                ("all",  String(localized: "journal.filter.all",  bundle: lang.bundle)),
                ("call", String(localized: "journal.filter.call", bundle: lang.bundle)),
                ("put",  String(localized: "journal.filter.put",  bundle: lang.bundle))
            ])
        }
    }

    private func segmentedFilter(options: [(key: String, label: String)]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(options, id: \.key) { opt in
                    Button(opt.label) { activeFilter = opt.key }
                        .buttonStyle(.plain)
                        .font(.system(size: 11, weight: activeFilter == opt.key ? .bold : .regular))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            activeFilter == opt.key ? Color.fmsPrimary.opacity(0.15) : Color.clear,
                            in: Capsule()
                        )
                        .foregroundStyle(activeFilter == opt.key ? Color.fmsPrimary : Color.fmsMuted)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
        }
    }

    private var filteredTrades: [Trade] {
        guard activeFilter != "all" else { return trades }
        switch category {
        case .stocksETFs:
            if activeFilter == "buy"  { return trades.filter { $0.direction == .long } }
            if activeFilter == "sell" { return trades.filter { $0.direction == .short } }
        case .crypto:
            if activeFilter == "spot"    { return trades.filter { ($0.leverage ?? 1) <= 1 } }
            if activeFilter == "futures" { return trades.filter { ($0.leverage ?? 1) > 1 } }
        case .options:
            if activeFilter == "call" { return trades.filter { $0.direction == .long } }
            if activeFilter == "put"  { return trades.filter { $0.direction == .short } }
        default: break
        }
        return trades
    }

    // MARK: - Header

    private var listHeader: some View {
        HStack {
            Text(category == .all
                 ? String(localized: "journal.list.all_trades", bundle: lang.bundle)
                 : category.rawValue)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Color.fmsMuted)
                .textCase(.uppercase)
            Spacer()
            Button {
                openCSVFile()
            } label: {
                Image(systemName: "square.and.arrow.down")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.fmsMuted)
            }
            .buttonStyle(.plain)
            .help(String(localized: "journal.list.import_help", bundle: lang.bundle))
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
                Label(sortByPnL
                  ? String(localized: "journal.list.sort_pnl", bundle: lang.bundle)
                  : String(localized: "journal.list.sort_newest", bundle: lang.bundle),
                  systemImage: "arrow.up.arrow.down")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.fmsMuted)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    // MARK: - Trade list

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
            Text("journal.list.empty_title", bundle: lang.bundle)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.fmsOnSurface)
            Text("journal.list.empty_subtitle", bundle: lang.bundle)
                .font(.system(size: 13))
                .foregroundStyle(Color.fmsMuted)
                .multilineTextAlignment(.center)
            Button(String(localized: "journal.list.log_first_trade", bundle: lang.bundle)) { onNewTrade() }
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
