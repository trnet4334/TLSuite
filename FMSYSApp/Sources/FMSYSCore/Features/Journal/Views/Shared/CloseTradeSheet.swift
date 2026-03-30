// Sources/FMSYSCore/Features/Journal/Views/Shared/CloseTradeSheet.swift
import SwiftUI

public struct CloseTradeSheet: View {
    @Environment(LanguageManager.self) private var lang

    let trade: Trade
    let onConfirm: (Double, Date) -> Void
    let onCancel: () -> Void

    @State private var exitPriceText: String = ""
    @State private var exitAt: Date = Date()

    public init(trade: Trade, onConfirm: @escaping (Double, Date) -> Void, onCancel: @escaping () -> Void) {
        self.trade = trade
        self.onConfirm = onConfirm
        self.onCancel = onCancel
    }

    private var exitPrice: Double? { Double(exitPriceText) }

    private var pnl: Double? {
        guard let price = exitPrice else { return nil }
        let mult = trade.direction == .long ? 1.0 : -1.0
        return (price - trade.entryPrice) * trade.positionSize * mult
    }

    private var canConfirm: Bool { exitPrice != nil }

    public var body: some View {
        VStack(spacing: 0) {
            header
            Divider().overlay(Color.fmsBorder)
            content
            Spacer()
            Divider().overlay(Color.fmsBorder)
            footer
        }
        .frame(width: 400, height: 360)
        .background(Color.fmsBackground)
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 3) {
                Text("journal.close_trade.title", bundle: lang.bundle)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.fmsOnSurface)
                HStack(spacing: 6) {
                    Text(trade.asset)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color.fmsOnSurface)
                    directionBadge
                }
            }
            Spacer()
            Button(String(localized: "common.cancel", bundle: lang.bundle), action: onCancel)
                .buttonStyle(.plain)
                .font(.system(size: 12))
                .foregroundStyle(Color.fmsMuted)
        }
        .padding(16)
    }

    private var directionBadge: some View {
        Text(trade.direction == .long ? "LONG" : "SHORT")
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(trade.direction == .long ? Color.fmsPrimary : Color.fmsLoss)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                (trade.direction == .long ? Color.fmsPrimary : Color.fmsLoss).opacity(0.12),
                in: RoundedRectangle(cornerRadius: 4)
            )
    }

    // MARK: - Content

    private var content: some View {
        VStack(spacing: 16) {
            // Entry price (read-only)
            row(label: String(localized: "journal.close_trade.entry_price", bundle: lang.bundle)) {
                Text(String(format: "$%.4g", trade.entryPrice))
                    .font(.system(size: 14, weight: .semibold).monospacedDigit())
                    .foregroundStyle(Color.fmsOnSurface)
            }

            // Exit price (input)
            row(label: String(localized: "journal.close_trade.exit_price", bundle: lang.bundle)) {
                TextField("0.00", text: $exitPriceText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14, weight: .semibold).monospacedDigit())
                    .multilineTextAlignment(.trailing)
                    .frame(width: 120)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.fmsSurface, in: RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(Color.fmsPrimary.opacity(0.3), lineWidth: 1)
                    )
            }

            // Exit time
            row(label: String(localized: "journal.close_trade.exit_time", bundle: lang.bundle)) {
                DatePicker("", selection: $exitAt, displayedComponents: [.date, .hourAndMinute])
                    .labelsHidden()
                    .font(.system(size: 12))
            }

            // P/L preview
            if let p = pnl {
                pnlPreview(p)
            }
        }
        .padding(20)
    }

    private func row<V: View>(label: String, @ViewBuilder value: () -> V) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.fmsMuted)
            Spacer()
            value()
        }
    }

    private func pnlPreview(_ p: Double) -> some View {
        let positive = p >= 0
        let color = positive ? Color.fmsPrimary : Color.fmsLoss
        return HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("journal.close_trade.estimated_pl", bundle: lang.bundle)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(color.opacity(0.7))
                    .textCase(.uppercase)
                    .tracking(0.5)
                Text(positive ? "+$\(String(format: "%.2f", p))" : "-$\(String(format: "%.2f", abs(p)))")
                    .font(.system(size: 22, weight: .heavy).monospacedDigit())
                    .foregroundStyle(color)
            }
            Spacer()
            // ROI %
            let roi = ((exitPrice ?? 0) - trade.entryPrice) / trade.entryPrice * 100 * (trade.direction == .long ? 1 : -1)
            Text(String(format: "%@%.1f%%", roi >= 0 ? "+" : "", roi))
                .font(.system(size: 14, weight: .bold).monospacedDigit())
                .foregroundStyle(color)
        }
        .padding(14)
        .background(color.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(color.opacity(0.2), lineWidth: 1)
        )
        .animation(.easeInOut(duration: 0.15), value: p)
    }

    // MARK: - Footer

    private var footer: some View {
        HStack {
            Spacer()
            Button {
                guard let price = exitPrice else { return }
                onConfirm(price, exitAt)
            } label: {
                Text("journal.close_trade.confirm_button", bundle: lang.bundle)
                    .font(.system(size: 13, weight: .semibold))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(canConfirm ? Color.fmsPrimary : Color.fmsMuted.opacity(0.2),
                                in: RoundedRectangle(cornerRadius: 8))
                    .foregroundStyle(canConfirm ? Color.black : Color.fmsMuted)
            }
            .buttonStyle(.plain)
            .disabled(!canConfirm)
        }
        .padding(16)
    }
}
