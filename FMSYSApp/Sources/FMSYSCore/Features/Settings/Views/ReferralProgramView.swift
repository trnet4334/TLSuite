// Sources/FMSYSCore/Features/Settings/Views/ReferralProgramView.swift
import SwiftUI

public struct ReferralProgramView: View {
    @State private var linkCopied = false

    @Environment(LanguageManager.self) private var lang

    private let referralLink = "fmsys.app/ref/johndoe_772"

    private struct RewardTier: Identifiable {
        let id = UUID()
        let icon: String
        let count: Int
        let reward: String
        let progress: Double
        let progressLabel: String
    }

    private struct Referral: Identifiable {
        let id = UUID()
        let initials: String
        let name: String
        let email: String
        let status: ReferralStatus
        let date: String
        let reward: String?
    }

    private enum ReferralStatus {
        case active, pending
        var label: String { self == .active ? "Active" : "Pending" }
        var color: Color { self == .active ? .green : Color.fmsWarning }
    }

    private let rewardTiers: [RewardTier] = [
        RewardTier(icon: "person.badge.plus",    count: 1,  reward: "1 Month Free Pro",     progress: 1.0,  progressLabel: "Completed"),
        RewardTier(icon: "star.fill",             count: 5,  reward: "6 Months Free Pro",    progress: 0.8,  progressLabel: "4/5 Completed"),
        RewardTier(icon: "crown.fill",            count: 10, reward: "1 Year Free Pro",       progress: 0.4,  progressLabel: "4/10 Completed"),
        RewardTier(icon: "diamond.fill",          count: 25, reward: "Pro Lifetime License",  progress: 0.16, progressLabel: "4/25 Completed"),
    ]

    private let referrals: [Referral] = [
        Referral(initials: "SM", name: "Sarah Miller", email: "sarah.m@gmail.com",    status: .active,  date: "Oct 12, 2023", reward: "30 Days Pro"),
        Referral(initials: "RK", name: "Robert King",  email: "king.r@outlook.com",   status: .pending, date: "Oct 14, 2023", reward: nil),
        Referral(initials: "AL", name: "Alex Lee",     email: "lee.alex@me.com",       status: .active,  date: "Oct 09, 2023", reward: "30 Days Pro"),
    ]

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                heroBanner
                HStack(alignment: .top, spacing: 16) {
                    referralLinkCard
                    statsColumn
                }
                rewardTiersSection
                recentReferralsTable
            }
            .padding(28)
        }
        .background(Color.fmsBackground)
    }

    // MARK: - Hero

    private var heroBanner: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 16)
                .fill(LinearGradient(
                    colors: [Color(white: 0.08), Color.fmsPrimary.opacity(0.3)],
                    startPoint: .leading,
                    endPoint: .trailing
                ))
            VStack(alignment: .leading, spacing: 8) {
                Text("referral.hero_eyebrow", bundle: lang.bundle)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Color.fmsPrimary)
                    .textCase(.uppercase)
                    .tracking(1.5)
                Text("referral.hero_headline", bundle: lang.bundle)
                    .font(.system(size: 22, weight: .heavy))
                    .foregroundStyle(.white)
                    .lineSpacing(2)
                Text("referral.hero_body", bundle: lang.bundle)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.white.opacity(0.75))
                    .lineLimit(3)
                Button {
                } label: {
                    Label(String(localized: "referral.invite_cta", bundle: lang.bundle), systemImage: "paperplane.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color.fmsBackground)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.fmsPrimary, in: RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
            .padding(20)
        }
        .frame(height: 160)
    }

    // MARK: - Referral Link

    private var referralLinkCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(String(localized: "referral.your_link_title", bundle: lang.bundle), systemImage: "link")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Color.fmsOnSurface)

            Text("referral.your_link_subtitle", bundle: lang.bundle)
                .font(.system(size: 11))
                .foregroundStyle(Color.fmsMuted)

            HStack(spacing: 8) {
                Text(referralLink)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.fmsOnSurface)
                    .lineLimit(1)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.fmsMuted.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color.fmsMuted.opacity(0.12)))

                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString("https://\(referralLink)", forType: .string)
                    linkCopied = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) { linkCopied = false }
                } label: {
                    Image(systemName: linkCopied ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 13))
                        .foregroundStyle(linkCopied ? Color.fmsPrimary : Color.fmsOnSurface)
                        .frame(width: 36, height: 36)
                        .background(Color.fmsSurface, in: RoundedRectangle(cornerRadius: 8))
                        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color.fmsMuted.opacity(0.15)))
                }
                .buttonStyle(.plain)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("referral.quick_share", bundle: lang.bundle)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Color.fmsMuted)
                    .textCase(.uppercase)
                    .tracking(1)
                HStack(spacing: 8) {
                    shareButton(icon: "bubble.left.fill", color: Color(red: 0.11, green: 0.63, blue: 0.95))
                    shareButton(icon: "person.2.fill", color: Color(red: 0.0, green: 0.47, blue: 0.71))
                    shareButton(icon: "envelope.fill", color: Color.fmsPrimary)
                }
            }
            .padding(.top, 4)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Color.fmsSurface, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.fmsMuted.opacity(0.12)))
    }

    private func shareButton(icon: String, color: Color) -> some View {
        Button {
        } label: {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundStyle(color)
                .frame(width: 36, height: 36)
                .background(color.opacity(0.1), in: Circle())
                .overlay(Circle().strokeBorder(color.opacity(0.2)))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Stats

    private var statsColumn: some View {
        VStack(spacing: 10) {
            statCard(label: String(localized: "referral.stat_total", bundle: lang.bundle), value: "24", badge: "+12%")
            statCard(
                label: String(localized: "referral.stat_rewards", bundle: lang.bundle),
                value: "5 Months",
                sub: String(localized: "referral.stat_rewards_sub", bundle: lang.bundle),
                valueColor: Color.fmsPrimary
            )
            statCard(label: String(localized: "referral.stat_pending", bundle: lang.bundle), value: "3")
        }
        .frame(width: 160)
    }

    private func statCard(label: String, value: String, badge: String? = nil, sub: String? = nil, valueColor: Color = Color.fmsOnSurface) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.system(size: 11))
                    .foregroundStyle(Color.fmsMuted)
                Spacer()
                if let badge {
                    Text(badge)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Color.fmsPrimary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.fmsPrimary.opacity(0.15), in: Capsule())
                }
            }
            Text(value)
                .font(.system(size: 22, weight: .heavy))
                .foregroundStyle(valueColor)
            if let sub {
                Text(sub)
                    .font(.system(size: 10))
                    .foregroundStyle(Color.fmsMuted)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.fmsSurface, in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.fmsMuted.opacity(0.12)))
    }

    // MARK: - Reward Tiers

    private var rewardTiersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("referral.program_rewards", bundle: lang.bundle)
                .font(.system(size: 16, weight: .heavy))
                .foregroundStyle(Color.fmsOnSurface)

            HStack(spacing: 12) {
                ForEach(rewardTiers) { tier in
                    tierCard(tier)
                }
            }
        }
    }

    private func tierCard(_ tier: RewardTier) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.fmsMuted.opacity(0.08))
                    .frame(width: 40, height: 40)
                Image(systemName: tier.icon)
                    .font(.system(size: 16))
                    .foregroundStyle(tier.progress >= 1 ? Color.fmsPrimary : Color.fmsMuted)
            }
            Text("\(tier.count) Referral\(tier.count == 1 ? "" : "s")")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Color.fmsOnSurface)
            Text(tier.reward)
                .font(.system(size: 11))
                .foregroundStyle(Color.fmsMuted)
                .lineLimit(2)
            Spacer()
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.fmsMuted.opacity(0.12)).frame(height: 6)
                    Capsule()
                        .fill(Color.fmsPrimary)
                        .frame(width: geo.size.width * tier.progress, height: 6)
                }
            }
            .frame(height: 6)
            Text(tier.progressLabel)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(tier.progress >= 1 ? Color.fmsPrimary : Color.fmsMuted)
                .textCase(.uppercase)
                .tracking(0.5)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.fmsSurface, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.fmsMuted.opacity(0.1)))
    }

    // MARK: - Recent Referrals

    private var recentReferralsTable: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("referral.recent_title", bundle: lang.bundle)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color.fmsOnSurface)
                Spacer()
                Button(String(localized: "referral.view_all", bundle: lang.bundle)) {}
                    .buttonStyle(.plain)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color.fmsPrimary)
            }
            .padding(16)
            .padding(.bottom, 0)

            Divider()

            HStack {
                Text("referral.col_user", bundle: lang.bundle).frame(maxWidth: .infinity, alignment: .leading)
                Text("referral.col_status", bundle: lang.bundle).frame(width: 80, alignment: .leading)
                Text("referral.col_date", bundle: lang.bundle).frame(width: 100, alignment: .leading)
                Text("referral.col_reward", bundle: lang.bundle).frame(width: 100, alignment: .leading)
            }
            .font(.system(size: 9, weight: .bold))
            .foregroundStyle(Color.fmsMuted)
            .textCase(.uppercase)
            .tracking(0.5)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.fmsMuted.opacity(0.04))

            ForEach(referrals) { referral in
                HStack {
                    HStack(spacing: 10) {
                        Circle()
                            .fill(Color.fmsMuted.opacity(0.15))
                            .frame(width: 32, height: 32)
                            .overlay {
                                Text(referral.initials)
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(Color.fmsMuted)
                            }
                        VStack(alignment: .leading, spacing: 1) {
                            Text(referral.name)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Color.fmsOnSurface)
                            Text(referral.email)
                                .font(.system(size: 10))
                                .foregroundStyle(Color.fmsMuted)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    statusPill(referral.status)
                        .frame(width: 80, alignment: .leading)

                    Text(referral.date)
                        .font(.system(size: 12))
                        .foregroundStyle(Color.fmsMuted)
                        .frame(width: 100, alignment: .leading)

                    Text(referral.reward ?? "—")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(referral.reward != nil ? Color.fmsOnSurface : Color.fmsMuted)
                        .frame(width: 100, alignment: .leading)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)

                if referral.id != referrals.last?.id {
                    Divider().padding(.horizontal, 16)
                }
            }
        }
        .background(Color.fmsSurface, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.fmsMuted.opacity(0.12)))
    }

    private func statusPill(_ status: ReferralStatus) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(status.color)
                .frame(width: 6, height: 6)
            Text(status.label)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(status.color)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(status.color.opacity(0.1), in: Capsule())
    }
}
