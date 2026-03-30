// Sources/FMSYSCore/Features/Backtesting/Views/BacktestKPICards.swift
import SwiftUI

public struct BacktestKPICards: View {

    let result: BacktestResult
    @Environment(LanguageManager.self) private var lang

    private let winRateTarget: Double      = 0.6
    private let profitFactorTarget: Double = 2.0

    public init(result: BacktestResult) {
        self.result = result
    }

    public var body: some View {
        HStack(spacing: 16) {
            kpiCard(
                systemIcon:    "checkmark.seal.fill",
                iconColor:     .blue,
                title:         String(localized: "backtest.kpi.win_rate", bundle: lang.bundle),
                value:         String(format: "%.1f%%", result.winRate * 100),
                subtext:       result.winRate >= winRateTarget
                    ? String(localized: "backtest.kpi.win_rate.above_target", bundle: lang.bundle)
                    : String(localized: "backtest.kpi.win_rate.below_target", bundle: lang.bundle),
                subtextColor:  result.winRate >= winRateTarget ? Color.fmsPrimary : Color.fmsLoss
            )
            kpiCard(
                systemIcon:    "chart.bar.fill",
                iconColor:     .orange,
                title:         String(localized: "backtest.kpi.profit_factor", bundle: lang.bundle),
                value:         String(format: "%.2f", result.profitFactor),
                subtext:       result.profitFactor >= profitFactorTarget
                    ? String(localized: "backtest.kpi.profit_factor.excellent", bundle: lang.bundle)
                    : String(localized: "backtest.kpi.profit_factor.fair", bundle: lang.bundle),
                subtextColor:  Color.fmsMuted
            )
            kpiCard(
                systemIcon:    "arrow.down.right",
                iconColor:     Color.fmsLoss,
                title:         String(localized: "backtest.kpi.max_drawdown", bundle: lang.bundle),
                value:         String(format: "%.2f%%", result.maxDrawdown * 100),
                subtext:       String(
                    format: String(localized: "backtest.kpi.sharpe", bundle: lang.bundle),
                    result.sharpeRatio
                ),
                subtextColor:  Color.fmsMuted
            )
        }
    }

    @ViewBuilder
    private func kpiCard(
        systemIcon:   String,
        iconColor:    Color,
        title:        String,
        value:        String,
        subtext:      String,
        subtextColor: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: systemIcon)
                    .font(.system(size: 14))
                    .foregroundStyle(iconColor)
                    .accessibilityHidden(true)
                Text(title.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color.fmsMuted)
                    .tracking(0.8)
            }
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(Color.fmsOnSurface)
            Text(subtext)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(subtextColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color.fmsSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.fmsMuted.opacity(0.15), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
    }
}
