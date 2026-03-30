// Sources/FMSYSCore/Features/Backtesting/Views/BacktestingView.swift
import SwiftUI
import SwiftData

public struct BacktestingView: View {

    @Bindable var viewModel: BacktestViewModel
    @Environment(LanguageManager.self) private var lang

    public init(viewModel: BacktestViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 24) {
                headerRow

                if let result = viewModel.selectedResult {
                    BacktestEquityCurveSection(result: result)
                    BacktestKPICards(result: result)
                    BacktestTradeLogTable(result: result)
                } else {
                    emptyState
                }
            }
            .padding(24)
        }
        .background(Color.fmsBackground)
        .task { viewModel.load() }
    }

    // MARK: Header

    private var headerRow: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text("backtest.title", bundle: lang.bundle)
                    .font(.system(size: 20, weight: .heavy))
                    .foregroundStyle(Color.fmsOnSurface)
                if let result = viewModel.selectedResult {
                    Text("Strategy: \(result.strategyName) - \(result.assetPair) (\(result.timeframe.rawValue.uppercased()))")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.fmsMuted)
                }
            }
            Spacer()
            newBacktestButton
        }
    }

    private var newBacktestButton: some View {
        Button {
            // TODO: Phase 4 — trigger backtest from strategy
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 14))
                    .accessibilityHidden(true)
                Text("backtest.button.new", bundle: lang.bundle)
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundStyle(Color.black)
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .background(Color.fmsPrimary)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.borderless)
    }

    // MARK: Empty state

    private var emptyState: some View {
        ContentUnavailableView(
            String(localized: "backtest.empty.title", bundle: lang.bundle),
            systemImage: "arrow.clockwise.circle",
            description: Text("backtest.empty.description", bundle: lang.bundle)
        )
    }
}
