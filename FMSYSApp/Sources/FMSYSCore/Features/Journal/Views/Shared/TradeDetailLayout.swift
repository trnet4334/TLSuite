// Sources/FMSYSCore/Features/Journal/Views/Shared/TradeDetailLayout.swift
import SwiftUI

/// Shared layout shell for all category detail panels.
/// Callers supply the 4-column metrics content via `metricsContent`.
public struct TradeDetailLayout<Metrics: View>: View {
    @Bindable var trade: Trade
    let subtitle: String
    let onDiscard: () -> Void
    let onSave: () -> Void
    @ViewBuilder let metricsContent: () -> Metrics

    public init(
        trade: Trade,
        subtitle: String,
        onDiscard: @escaping () -> Void,
        onSave: @escaping () -> Void,
        @ViewBuilder metricsContent: @escaping () -> Metrics
    ) {
        self.trade = trade
        self.subtitle = subtitle
        self.onDiscard = onDiscard
        self.onSave = onSave
        self.metricsContent = metricsContent
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                heroHeader
                metricsContent()
                notesSection
                chartSection
                footerActions
            }
            .padding(32)
        }
        .background(Color.fmsBackground)
    }

    // MARK: Hero Header

    private var heroHeader: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(trade.asset)
                    .font(.system(size: 32, weight: .heavy))
                    .foregroundStyle(Color.fmsOnSurface)
                Text(subtitle)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.fmsMuted)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(pnlFormatted)
                    .font(.system(size: 32, weight: .heavy).monospacedDigit())
                    .foregroundStyle(pnlColor)
                if let roi = roiPercent {
                    Text(roi)
                        .font(.system(size: 12, weight: .bold).monospacedDigit())
                        .foregroundStyle(pnlColor.opacity(0.7))
                }
            }
        }
    }

    // MARK: Notes

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Notes & Reflection", systemImage: "note.text")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Color.fmsOnSurface)
            TextEditor(text: Binding(
                get: { trade.notes ?? "" },
                set: { trade.notes = $0 }
            ))
            .font(.system(size: 13))
            .foregroundStyle(Color.fmsOnSurface)
            .frame(minHeight: 200)
            .padding(14)
            .background(Color.fmsSurface, in: RoundedRectangle(cornerRadius: 12))
            .scrollContentBackground(.hidden)
        }
    }

    // MARK: Chart Analysis

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Chart Analysis", systemImage: "photo")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Color.fmsOnSurface)
            HStack(spacing: 14) {
                uploadArea(label: "Entry Chart")
                uploadArea(label: "Exit Chart")
            }
        }
    }

    private func uploadArea(label: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "plus.viewfinder")
                .font(.system(size: 28))
                .foregroundStyle(Color.fmsMuted)
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.fmsMuted)
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(16 / 9, contentMode: .fit)
        .background(Color.fmsSurface, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    style: StrokeStyle(lineWidth: 1.5, dash: [6])
                )
                .foregroundStyle(Color.fmsMuted.opacity(0.35))
        )
    }

    // MARK: Footer

    private var footerActions: some View {
        HStack {
            Spacer()
            Button("Discard") { onDiscard() }
                .buttonStyle(.plain)
                .font(.system(size: 13, weight: .semibold))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .foregroundStyle(Color.fmsMuted)
                .background(Color.fmsSurface, in: RoundedRectangle(cornerRadius: 8))
            Button("Save Entry") { onSave() }
                .buttonStyle(.plain)
                .font(.system(size: 13, weight: .semibold))
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(Color.fmsPrimary, in: RoundedRectangle(cornerRadius: 8))
                .foregroundStyle(Color.fmsBackground)
        }
        .padding(.top, 8)
    }

    // MARK: P&L helpers

    private var computedPnL: Double {
        guard let exit = trade.exitPrice else { return 0 }
        let multiplier = trade.direction == .long ? 1.0 : -1.0
        return (exit - trade.entryPrice) * trade.positionSize * multiplier
    }

    private var pnlFormatted: String {
        let v = computedPnL
        return v >= 0 ? "+$\(String(format: "%.2f", v))" : "-$\(String(format: "%.2f", abs(v)))"
    }

    private var pnlColor: Color {
        let v = computedPnL
        if v > 0 { return Color.fmsPrimary }
        if v < 0 { return Color.fmsLoss }
        return Color.fmsMuted
    }

    private var roiPercent: String? {
        guard let exit = trade.exitPrice, trade.entryPrice > 0 else { return nil }
        let pct = ((exit - trade.entryPrice) / trade.entryPrice) * 100
        let sign = pct >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f", pct))% ROI"
    }
}

// MARK: - MetricCard

/// Reusable editable metric card used in all category panels.
public struct MetricCard<Content: View>: View {
    let label: String
    @ViewBuilder let content: () -> Content

    public init(label: String, @ViewBuilder content: @escaping () -> Content) {
        self.label = label
        self.content = content
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(Color.fmsMuted)
                .textCase(.uppercase)
                .tracking(0.5)
            content()
                .font(.system(size: 16, weight: .semibold).monospacedDigit())
                .foregroundStyle(Color.fmsOnSurface)
                .textFieldStyle(.plain)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.fmsSurface, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.fmsMuted.opacity(0.12), lineWidth: 1)
        )
    }
}
