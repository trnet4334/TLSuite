// Sources/FMSYSCore/Shared/Components/Notifications/PriceAlertDetailView.swift
import SwiftUI
import Charts

public struct PriceAlertDetailView: View {
    let notification: AppNotification
    let onDismiss: () -> Void
    let onRemove: (() -> Void)?
    let onViewTrade: (() -> Void)?
    let onAchieve: (() -> Void)?
    @Environment(LanguageManager.self) private var lang

    private let sparklinePoints: [Double] = [80, 20, 50, 30, 70, 10, 40]

    public var body: some View {
        VStack(spacing: 0) {
            header
            content
            footer
        }
        .frame(width: 480)
        .background(Color.fmsSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.fmsPrimary.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: "target")
                    .font(.system(size: 18))
                    .foregroundStyle(Color.fmsPrimary)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text("notification.price_alert.type", bundle: lang.bundle)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.fmsMuted)
                    .textCase(.uppercase)
                    .tracking(0.5)
                Text("BTC / USDT")
                    .font(.system(size: 18, weight: .heavy))
                    .foregroundStyle(Color.fmsOnSurface)
            }
            Spacer()
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.fmsMuted)
                    .frame(width: 28, height: 28)
                    .background(Color.fmsMuted.opacity(0.1), in: Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .overlay(alignment: .bottom) { Divider() }
    }

    // MARK: - Content

    private var content: some View {
        VStack(spacing: 20) {
            // Price comparison
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("notification.price_alert.current_price", bundle: lang.bundle)
                        .font(.system(size: 11))
                        .foregroundStyle(Color.fmsMuted)
                    Text("$65,042.50")
                        .font(.system(size: 22, weight: .heavy))
                        .foregroundStyle(Color.fmsOnSurface)
                    Text("+2.45%")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color.fmsPrimary)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.fmsMuted.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 4) {
                    Text("notification.price_alert.target_price", bundle: lang.bundle)
                        .font(.system(size: 11))
                        .foregroundStyle(Color.fmsMuted)
                    Text("$65,000.00")
                        .font(.system(size: 22, weight: .heavy))
                        .foregroundStyle(Color.fmsOnSurface)
                    Text("Hit at 10:42 AM")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.fmsMuted)
                        .italic()
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.fmsSurface, in: RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.fmsMuted.opacity(0.12)))
            }

            // Alert description
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.fmsPrimary)
                VStack(alignment: .leading, spacing: 3) {
                    Text("notification.price_alert.triggered_title", bundle: lang.bundle)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color.fmsOnSurface)
                    Text("notification.price_alert.triggered_body", bundle: lang.bundle)
                        .font(.system(size: 12))
                        .foregroundStyle(Color.fmsMuted)
                        .lineSpacing(2)
                }
            }

            // Volatility sparkline
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("notification.price_alert.volatility_label", bundle: lang.bundle)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color.fmsMuted)
                        .textCase(.uppercase)
                        .tracking(0.5)
                    Spacer()
                    Text("notification.price_alert.high_risk", bundle: lang.bundle)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Color.fmsLoss)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.fmsLoss.opacity(0.1), in: Capsule())
                }
                Chart {
                    ForEach(Array(sparklinePoints.enumerated()), id: \.offset) { i, val in
                        LineMark(x: .value("t", i), y: .value("v", val))
                            .interpolationMethod(.catmullRom)
                            .foregroundStyle(Color.fmsPrimary)
                        AreaMark(x: .value("t", i), y: .value("v", val))
                            .interpolationMethod(.catmullRom)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.fmsPrimary.opacity(0.25), Color.fmsPrimary.opacity(0)],
                                    startPoint: .top, endPoint: .bottom
                                )
                            )
                    }
                }
                .chartXAxis(.hidden)
                .chartYAxis(.hidden)
                .frame(height: 72)
            }
        }
        .padding(20)
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(spacing: 10) {
            Button(String(localized: "common.view_trade", bundle: lang.bundle)) { onViewTrade?() }
                .buttonStyle(.plain)
                .font(.system(size: 13, weight: .bold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.fmsPrimary, in: RoundedRectangle(cornerRadius: 10))
                .foregroundStyle(Color.fmsBackground)

            HStack(spacing: 10) {
                Button(String(localized: "common.mark_achieved", bundle: lang.bundle)) { onAchieve?() }
                    .buttonStyle(.plain)
                    .font(.system(size: 12, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .background(Color.fmsSurface, in: RoundedRectangle(cornerRadius: 10))
                    .foregroundStyle(Color.fmsOnSurface)
                    .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.fmsMuted.opacity(0.15)))
                Button(String(localized: "common.dismiss", bundle: lang.bundle)) { onRemove?() ?? onDismiss() }
                    .buttonStyle(.plain)
                    .font(.system(size: 12, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .foregroundStyle(Color.fmsMuted)
            }
        }
        .padding(20)
        .background(Color.fmsMuted.opacity(0.04))
        .overlay(alignment: .top) { Divider() }
    }
}
