// Sources/FMSYSCore/Features/Backtesting/Views/BacktestKPICards.swift
import SwiftUI

public struct BacktestKPICards: View {

    let result: BacktestResult

    public init(result: BacktestResult) {
        self.result = result
    }

    public var body: some View {
        HStack(spacing: 16) {
            kpiCard(
                systemIcon:    "checkmark.seal.fill",
                iconColor:     .blue,
                title:         "Win Rate",
                value:         String(format: "%.1f%%", result.winRate * 100),
                subtext:       result.winRate >= 0.6 ? "Above target (60%)" : "Below target (60%)",
                subtextColor:  result.winRate >= 0.6 ? Color.fmsPrimary : Color.fmsLoss
            )
            kpiCard(
                systemIcon:    "chart.bar.fill",
                iconColor:     .orange,
                title:         "Profit Factor",
                value:         String(format: "%.2f", result.profitFactor),
                subtext:       result.profitFactor >= 2.0 ? "Excellent performance" : "Fair performance",
                subtextColor:  Color.fmsMuted
            )
            kpiCard(
                systemIcon:    "arrow.down.right",
                iconColor:     Color.fmsLoss,
                title:         "Max Drawdown",
                value:         String(format: "%.2f%%", result.maxDrawdown * 100),
                subtext:       "Sharpe: \(String(format: "%.2f", result.sharpeRatio))",
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
    }
}
