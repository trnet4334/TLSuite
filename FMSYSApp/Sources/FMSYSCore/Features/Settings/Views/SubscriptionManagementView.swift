// Sources/FMSYSCore/Features/Settings/Views/SubscriptionManagementView.swift
import SwiftUI

public struct SubscriptionManagementView: View {
    @Environment(LanguageManager.self) private var lang

    private struct BillingEntry: Identifiable {
        let id = UUID()
        let date: String
        let amount: String
    }

    private let billingHistory: [BillingEntry] = [
        BillingEntry(date: "Oct 24, 2023", amount: "$299.00"),
        BillingEntry(date: "Oct 24, 2022", amount: "$299.00"),
    ]

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                currentPlanCard
                HStack(alignment: .top, spacing: 16) {
                    paymentMethodCard
                    billingHistoryCard
                }
                comparePlansSection
                supportFooter
            }
            .padding(28)
        }
        .background(Color.fmsBackground)
    }

    // MARK: - Current Plan

    private var currentPlanCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("subscription.title", bundle: lang.bundle)
                        .font(.system(size: 18, weight: .heavy))
                        .foregroundStyle(Color.fmsOnSurface)
                }
                Spacer()
                Text("subscription.status_active", bundle: lang.bundle)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color.fmsPrimary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.fmsPrimary.opacity(0.15), in: Capsule())
            }
            .padding(.bottom, 16)

            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.fmsPrimary.opacity(0.1))
                        .frame(width: 72, height: 72)
                    Image(systemName: "crown.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(Color.fmsPrimary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("subscription.current_plan_label", bundle: lang.bundle)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Color.fmsMuted)
                        .textCase(.uppercase)
                        .tracking(0.5)
                    Text("subscription.pro_plan_annual", bundle: lang.bundle)
                        .font(.system(size: 18, weight: .heavy))
                        .foregroundStyle(Color.fmsOnSurface)
                    Text("subscription.renewal_info", bundle: lang.bundle)
                        .font(.system(size: 12))
                        .foregroundStyle(Color.fmsMuted)
                }

                Spacer()

                VStack(spacing: 8) {
                    Button(String(localized: "subscription.manage_billing", bundle: lang.bundle)) {}
                        .buttonStyle(.plain)
                        .font(.system(size: 13, weight: .bold))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.fmsPrimary, in: RoundedRectangle(cornerRadius: 8))
                        .foregroundStyle(Color.fmsBackground)

                    Button(String(localized: "subscription.switch_monthly", bundle: lang.bundle)) {}
                        .buttonStyle(.plain)
                        .font(.system(size: 13, weight: .bold))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.fmsSurface, in: RoundedRectangle(cornerRadius: 8))
                        .foregroundStyle(Color.fmsOnSurface)
                        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color.fmsMuted.opacity(0.2)))
                }
            }
        }
        .padding(20)
        .background(Color.fmsSurface, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.fmsPrimary.opacity(0.1)))
    }

    // MARK: - Payment Method

    private var paymentMethodCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("subscription.payment_method", bundle: lang.bundle)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.fmsOnSurface)
                Spacer()
                Button(String(localized: "subscription.update_payment", bundle: lang.bundle)) {}
                    .buttonStyle(.plain)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color.fmsPrimary)
            }

            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(white: 0.1))
                        .frame(width: 48, height: 32)
                    Text("VISA")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("subscription.visa_ending", bundle: lang.bundle)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color.fmsOnSurface)
                    Text("subscription.visa_expires", bundle: lang.bundle)
                        .font(.system(size: 11))
                        .foregroundStyle(Color.fmsMuted)
                }
                Spacer()
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color.fmsPrimary)
            }
            .padding(12)
            .background(Color.fmsBackground, in: RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.fmsMuted.opacity(0.12)))
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Color.fmsSurface, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.fmsMuted.opacity(0.12)))
    }

    // MARK: - Billing History

    private var billingHistoryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("subscription.billing_history", bundle: lang.bundle)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.fmsOnSurface)
                Spacer()
                Button(String(localized: "subscription.view_all", bundle: lang.bundle)) {}
                    .buttonStyle(.plain)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color.fmsPrimary)
            }

            ForEach(billingHistory) { entry in
                HStack {
                    Text(entry.date)
                        .font(.system(size: 12))
                        .foregroundStyle(Color.fmsMuted)
                    Spacer()
                    Text(entry.amount)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color.fmsOnSurface)
                    Button {
                    } label: {
                        Image(systemName: "arrow.down.circle")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.fmsMuted)
                    }
                    .buttonStyle(.plain)
                }
                if entry.id != billingHistory.last?.id {
                    Divider()
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Color.fmsSurface, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.fmsMuted.opacity(0.12)))
    }

    // MARK: - Compare Plans

    private var comparePlansSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("subscription.compare_plans", bundle: lang.bundle)
                .font(.system(size: 18, weight: .heavy))
                .foregroundStyle(Color.fmsOnSurface)

            HStack(alignment: .top, spacing: 16) {
                planCard(
                    name: String(localized: "subscription.plan_basic_name", bundle: lang.bundle),
                    subtitle: String(localized: "subscription.plan_basic_subtitle", bundle: lang.bundle),
                    price: "$0",
                    period: String(localized: "subscription.period_monthly", bundle: lang.bundle),
                    features: [
                        (String(localized: "subscription.feature_realtime_quotes", bundle: lang.bundle), true),
                        (String(localized: "subscription.feature_basic_indicators", bundle: lang.bundle), true),
                        (String(localized: "subscription.feature_watchlists_3", bundle: lang.bundle), true),
                        (String(localized: "subscription.feature_api_access", bundle: lang.bundle), false),
                    ],
                    ctaLabel: String(localized: "subscription.cta_current_plan", bundle: lang.bundle),
                    isHighlighted: false
                )
                planCard(
                    name: String(localized: "subscription.plan_pro_name", bundle: lang.bundle),
                    subtitle: String(localized: "subscription.plan_pro_subtitle", bundle: lang.bundle),
                    price: "$29",
                    period: String(localized: "subscription.period_monthly", bundle: lang.bundle),
                    features: [
                        (String(localized: "subscription.feature_multi_chart", bundle: lang.bundle), true),
                        (String(localized: "subscription.feature_100_indicators", bundle: lang.bundle), true),
                        (String(localized: "subscription.feature_unlimited_watchlists", bundle: lang.bundle), true),
                        (String(localized: "subscription.feature_full_api", bundle: lang.bundle), true),
                        (String(localized: "subscription.feature_level2_data", bundle: lang.bundle), true),
                    ],
                    ctaLabel: String(localized: "subscription.cta_manage_subscription", bundle: lang.bundle),
                    isHighlighted: true,
                    badge: String(localized: "subscription.badge_recommended", bundle: lang.bundle)
                )
            }
        }
    }

    private func planCard(
        name: String,
        subtitle: String,
        price: String,
        period: String,
        features: [(String, Bool)],
        ctaLabel: String,
        isHighlighted: Bool,
        badge: String? = nil
    ) -> some View {
        ZStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(name)
                        .font(.system(size: 16, weight: .heavy))
                        .foregroundStyle(Color.fmsOnSurface)
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundStyle(Color.fmsMuted)
                    HStack(alignment: .lastTextBaseline, spacing: 2) {
                        Text(price)
                            .font(.system(size: 28, weight: .heavy))
                            .foregroundStyle(Color.fmsOnSurface)
                        Text(period)
                            .font(.system(size: 12))
                            .foregroundStyle(Color.fmsMuted)
                    }
                    .padding(.top, 8)
                }
                .padding(.bottom, 16)

                VStack(alignment: .leading, spacing: 10) {
                    ForEach(features, id: \.0) { feature, included in
                        HStack(spacing: 8) {
                            Image(systemName: included ? "checkmark" : "xmark")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(included ? Color.fmsPrimary : Color.fmsMuted.opacity(0.4))
                                .frame(width: 14)
                            Text(feature)
                                .font(.system(size: 12))
                                .foregroundStyle(included ? Color.fmsOnSurface : Color.fmsMuted.opacity(0.5))
                                .strikethrough(!included)
                        }
                    }
                }
                .padding(.bottom, 20)

                Spacer()

                Button(ctaLabel) {}
                    .buttonStyle(.plain)
                    .font(.system(size: 13, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        isHighlighted ? Color.fmsPrimary : Color.fmsSurface,
                        in: RoundedRectangle(cornerRadius: 8)
                    )
                    .foregroundStyle(isHighlighted ? Color.fmsBackground : Color.fmsMuted)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(isHighlighted ? Color.clear : Color.fmsMuted.opacity(0.2))
                    )
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                isHighlighted ? Color.fmsPrimary.opacity(0.05) : Color.fmsSurface,
                in: RoundedRectangle(cornerRadius: 12)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(
                        isHighlighted ? Color.fmsPrimary : Color.fmsMuted.opacity(0.12),
                        lineWidth: isHighlighted ? 2 : 1
                    )
            )

            if let badge {
                Text(badge)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Color.fmsBackground)
                    .textCase(.uppercase)
                    .tracking(0.5)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.fmsPrimary, in: Capsule())
                    .offset(y: -12)
            }
        }
    }

    // MARK: - Support Footer

    private var supportFooter: some View {
        VStack(spacing: 10) {
            Text("subscription.support_prompt", bundle: lang.bundle)
                .font(.system(size: 12))
                .foregroundStyle(Color.fmsMuted)
            HStack(spacing: 20) {
                Button {
                } label: {
                    Label(String(localized: "subscription.contact_support", bundle: lang.bundle), systemImage: "headphones")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color.fmsPrimary)
                }
                .buttonStyle(.plain)
                Button {
                } label: {
                    Label(String(localized: "subscription.help_center", bundle: lang.bundle), systemImage: "questionmark.circle")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color.fmsPrimary)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color.fmsSurface, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.fmsMuted.opacity(0.1)))
    }
}
