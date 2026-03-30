// Sources/FMSYSCore/Shared/Components/Notifications/UserNotificationDetailView.swift
import SwiftUI

public struct UserNotificationDetailView: View {
    let notification: AppNotification
    let onDismiss: () -> Void
    let onRemove: (() -> Void)?
    let onViewAccount: (() -> Void)?
    let onAchieve: (() -> Void)?
    @Environment(LanguageManager.self) private var lang

    public var body: some View {
        VStack(spacing: 0) {
            header
            content
            footer
        }
        .frame(width: 460)
        .background(Color.fmsSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.purple.opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(Color.purple)
            }
            Text("notification.user.account_update", bundle: lang.bundle)
                .font(.system(size: 17, weight: .heavy))
                .foregroundStyle(Color.fmsOnSurface)
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
        VStack(alignment: .leading, spacing: 14) {
            // Plan card
            VStack(alignment: .leading, spacing: 0) {
                ZStack {
                    RoundedRectangle(cornerRadius: 0)
                        .fill(LinearGradient(
                            colors: [Color.purple.opacity(0.2), Color.fmsPrimary.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(height: 80)
                        .overlay {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 32))
                                .foregroundStyle(Color.white.opacity(0.1))
                        }
                }
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("notification.user.plan_renewal", bundle: lang.bundle)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color.fmsOnSurface)
                        Text("Transaction ID: #TRX-99812-APP")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.fmsMuted)
                    }
                    Spacer()
                }
                .padding(12)
                .background(Color.fmsPrimary.opacity(0.05))
            }
            .background(Color.fmsMuted.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.fmsMuted.opacity(0.1)))

            // Body text
            Text(notification.body)
                .font(.system(size: 13))
                .foregroundStyle(Color.fmsMuted)
                .lineSpacing(3)
                .padding(12)
                .background(Color.fmsMuted.opacity(0.05), in: RoundedRectangle(cornerRadius: 10))

            // Account details
            VStack(spacing: 0) {
                detailRow(label: String(localized: "notification.user.account_status", bundle: lang.bundle), value: "Active - Pro Plan", valueColor: Color.fmsPrimary)
                Divider().padding(.horizontal, 12)
                detailRow(label: String(localized: "notification.user.renewal_date", bundle: lang.bundle), value: "October 24, 2024")
                Divider().padding(.horizontal, 12)
                detailRow(label: String(localized: "notification.user.billing_cycle", bundle: lang.bundle), value: "Annual")
            }
            .background(Color.fmsMuted.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.fmsMuted.opacity(0.1)))
        }
        .padding(20)
    }

    private func detailRow(label: String, value: String, valueColor: Color = Color.fmsOnSurface) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(Color.fmsMuted)
            Spacer()
            Text(value)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(valueColor)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
    }

    // MARK: - Footer

    private var footer: some View {
        HStack(spacing: 10) {
            Button(String(localized: "common.view_account", bundle: lang.bundle)) { onViewAccount?() }
                .buttonStyle(.plain)
                .font(.system(size: 13, weight: .bold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .background(Color.fmsPrimary, in: RoundedRectangle(cornerRadius: 10))
                .foregroundStyle(Color.fmsBackground)
            Button(String(localized: "common.archived", bundle: lang.bundle)) { onAchieve?() }
                .buttonStyle(.plain)
                .font(.system(size: 13, weight: .bold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .background(Color.fmsMuted.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
                .foregroundStyle(Color.fmsOnSurface)
            Button(String(localized: "common.dismiss", bundle: lang.bundle)) { onRemove?() ?? onDismiss() }
                .buttonStyle(.plain)
                .font(.system(size: 13, weight: .bold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .foregroundStyle(Color.fmsMuted)
        }
        .padding(20)
        .background(Color.fmsMuted.opacity(0.04))
        .overlay(alignment: .top) { Divider() }
    }
}
