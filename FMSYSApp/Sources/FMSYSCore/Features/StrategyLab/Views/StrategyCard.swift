// Sources/FMSYSCore/Features/StrategyLab/Views/StrategyCard.swift
import SwiftUI
import Charts

private struct SparkPoint: Identifiable {
    let id: Int
    let value: Double
}

public struct StrategyCard: View {
    let strategy: Strategy
    let isSelected: Bool
    let onTap: () -> Void

    private var statusColor: Color {
        switch strategy.status {
        case .active:   return Color.fmsPrimary
        case .paused:   return Color.fmsMuted
        case .drafting: return Color.fmsWarning
        case .archived: return Color.fmsMuted.opacity(0.5)
        }
    }

    // MARK: - Stub sparkline data (Phase N wires real equityCurve)
    private var sparklinePoints: [Double] {
        switch strategy.status {
        case .active:   return [10, 12, 11, 15, 14, 18, 20]
        case .paused:   return [15, 14, 16, 13, 15, 14, 15]
        case .drafting: return [10, 10, 11, 10, 12, 11, 13]
        case .archived: return [20, 18, 15, 12, 10, 8, 7]
        }
    }

    private var sparkPoints: [SparkPoint] {
        sparklinePoints.enumerated().map { SparkPoint(id: $0.offset, value: $0.element) }
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(strategy.name)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color.fmsOnSurface)
                    Text(strategy.indicatorTag.isEmpty ? "No indicator" : strategy.indicatorTag)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color.fmsMuted)
                        .textCase(.uppercase)
                }
                Spacer()
                statusBadge
            }
            .padding(.bottom, 12)

            // Sparkline
            Chart(sparkPoints) { point in
                LineMark(
                    x: .value("t", point.id),
                    y: .value("v", point.value)
                )
                .foregroundStyle(statusColor)
                .lineStyle(strategy.status == .drafting
                    ? StrokeStyle(lineWidth: 1.5, dash: [4])
                    : StrokeStyle(lineWidth: 1.5))
            }
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .frame(height: 48)
            .opacity(strategy.status == .paused ? 0.6 : 1.0)
            .padding(.bottom, 12)
            .accessibilityHidden(true)

            // Metrics
            Divider()
                .overlay(Color.fmsMuted.opacity(0.1))
                .padding(.bottom, 8)

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(strategy.status == .drafting ? "EXP. WIN RATE" : "WIN RATE")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Color.fmsMuted)
                    Text(strategy.winRate.map { String(format: "%.1f%%", $0 * 100) } ?? "—")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color.fmsOnSurface)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(strategy.status == .drafting ? "RR RATIO" : "PROFIT FACTOR")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Color.fmsMuted)
                    Text(strategy.profitFactor.map { String(format: "%.2f", $0) } ?? "—")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color.fmsOnSurface)
                }
            }
        }
        .padding(16)
        .background(Color.fmsSurface, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    isSelected ? Color.fmsPrimary.opacity(0.5) : Color.fmsMuted.opacity(0.1),
                    lineWidth: isSelected ? 1.5 : 1
                )
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }

    private var statusBadge: some View {
        Text(strategy.status.rawValue.capitalized)
            .font(.system(size: 9, weight: .bold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(statusColor.opacity(0.15), in: Capsule())
            .foregroundStyle(statusColor)
    }
}
