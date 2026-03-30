// Sources/FMSYSCore/Features/Portfolio/Views/PortfolioInspectorPanel.swift
import SwiftUI

// MARK: - Donut Chart

struct AllocationDonutView: View {
    let slices: [AllocationSlice]

    var body: some View {
        ZStack {
            Canvas { ctx, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let radius = min(size.width, size.height) / 2 - 8
                let lineWidth: CGFloat = 8
                let gapAngle: Double = 0.04
                var startAngle = -Double.pi / 2
                let total = slices.reduce(0) { $0 + $1.percent }
                for slice in slices {
                    let sweep = (slice.percent / total) * (2 * .pi) - gapAngle
                    let path = Path { p in
                        p.addArc(center: center, radius: radius,
                                 startAngle: .radians(startAngle),
                                 endAngle: .radians(startAngle + sweep),
                                 clockwise: false)
                    }
                    ctx.stroke(path, with: .color(slice.color),
                               style: StrokeStyle(lineWidth: lineWidth, lineCap: .butt))
                    startAngle += sweep + gapAngle
                }
            }
            .frame(width: 160, height: 160)

            VStack(spacing: 2) {
                DonutCenterLabel()
            }
        }
    }
}

// Separate subview so it can hold its own @Environment
private struct DonutCenterLabel: View {
    @Environment(LanguageManager.self) private var lang

    var body: some View {
        Text("portfolio.inspector.total_assets", bundle: lang.bundle)
            .font(.system(size: 9, weight: .bold))
            .foregroundStyle(Color.fmsMuted)
            .textCase(.uppercase)
        Text("$142k")
            .font(.system(size: 17, weight: .heavy))
            .foregroundStyle(Color.fmsOnSurface)
    }
}

// MARK: - Inspector Panel

public struct PortfolioInspectorPanel: View {
    let viewModel: PortfolioViewModel
    @Environment(LanguageManager.self) private var lang

    public var body: some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 28) {
                allocationSection
                Divider().overlay(Color.fmsMuted.opacity(0.1))
                riskSection
            }
            .padding(20)
        }
    }

    private var allocationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("portfolio.inspector.allocation.title", bundle: lang.bundle)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Color.fmsMuted)
                .textCase(.uppercase)
                .tracking(1)

            HStack {
                Spacer()
                AllocationDonutView(slices: viewModel.allocation)
                Spacer()
            }

            VStack(spacing: 10) {
                ForEach(viewModel.allocation) { slice in
                    HStack {
                        Circle()
                            .fill(slice.color)
                            .frame(width: 10, height: 10)
                        Text(slice.name)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color.fmsOnSurface)
                        Spacer()
                        Text(String(format: "%.1f%%", slice.percent * 100))
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Color.fmsOnSurface)
                    }
                }
            }
        }
    }

    private var riskSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("portfolio.inspector.risk.title", bundle: lang.bundle)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Color.fmsMuted)
                .textCase(.uppercase)
                .tracking(1)

            riskBar(
                label: String(localized: "portfolio.inspector.risk.position_exposure", bundle: lang.bundle),
                fillFraction: min(1.0, Double(viewModel.openTrades.count) / 10.0),
                displayValue: String(
                    format: String(localized: "portfolio.inspector.risk.open_count", bundle: lang.bundle),
                    viewModel.openTrades.count
                ),
                color: Color(red: 0.231, green: 0.510, blue: 0.965)
            )
            riskBar(
                label: String(localized: "portfolio.inspector.risk.margin_utilization", bundle: lang.bundle),
                fillFraction: viewModel.marginUtilization,
                displayValue: String(format: "%.0f%%", viewModel.marginUtilization * 100),
                color: Color.fmsPrimary
            )
        }
    }

    @ViewBuilder
    private func riskBar(label: String, fillFraction: Double, displayValue: String, color: Color) -> some View {
        VStack(spacing: 6) {
            HStack {
                Text(label)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color.fmsOnSurface)
                Spacer()
                Text(displayValue)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color.fmsOnSurface)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.fmsMuted.opacity(0.15))
                        .frame(height: 4)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color)
                        .frame(width: geo.size.width * max(0, min(1, fillFraction)), height: 4)
                }
            }
            .frame(height: 4)
        }
    }
}
