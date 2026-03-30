// Sources/FMSYSCore/Shared/Components/AvatarPopover.swift
import SwiftUI

public struct AvatarPopover: View {
    public let displayName: String
    public let email: String
    public let role: String
    public let onSignOut: () -> Void
    public let onShowSettings: (SettingsTab) -> Void

    @AppStorage("isDarkMode") private var isDarkMode = true
    @AppStorage("priceAlertsEnabled") private var priceAlertsEnabled = false
    @Environment(LanguageManager.self) private var lang

    public init(
        displayName: String,
        email: String,
        role: String,
        onSignOut: @escaping () -> Void,
        onShowSettings: @escaping (SettingsTab) -> Void = { _ in }
    ) {
        self.displayName = displayName
        self.email = email
        self.role = role
        self.onSignOut = onSignOut
        self.onShowSettings = onShowSettings
    }

    public var body: some View {
        VStack(spacing: 0) {
            userHeader
            Divider()
            accountSection
            Divider()
            settingsSection
            Divider()
            signOutButton
        }
        .frame(width: 300)
        .background(Color.fmsSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - User Header

    private var userHeader: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.fmsPrimary.opacity(0.4), Color.fmsPrimary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 64, height: 64)
                    .overlay {
                        Image(systemName: "person.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(Color.fmsBackground)
                    }
                Circle()
                    .fill(Color.fmsPrimary)
                    .frame(width: 14, height: 14)
                    .overlay(Circle().stroke(Color.fmsSurface, lineWidth: 2))
            }

            VStack(spacing: 4) {
                Text(displayName)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color.fmsOnSurface)
                Text(email)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.fmsMuted)
                Text(role.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color.fmsPrimary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.fmsPrimary.opacity(0.15), in: Capsule())
            }
        }
        .padding(.vertical, 16)
    }

    // MARK: - Account Section

    private var accountSection: some View {
        VStack(spacing: 0) {
            menuRow(systemImage: "person", label: String(localized: "avatar.account_management", bundle: lang.bundle)) { onShowSettings(.account) }
            menuRow(systemImage: "creditcard", label: String(localized: "avatar.subscription_management", bundle: lang.bundle)) { onShowSettings(.subscription) }
            menuRow(systemImage: "lock.shield", label: String(localized: "avatar.security_privacy", bundle: lang.bundle)) { onShowSettings(.security) }
            menuRow(systemImage: "person.3", label: String(localized: "avatar.referral_program", bundle: lang.bundle)) { onShowSettings(.referral) }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Settings Section

    private var settingsSection: some View {
        VStack(spacing: 0) {
            sectionHeader(String(localized: "avatar.settings", bundle: lang.bundle))
            toggleRow(systemImage: "moon.fill", label: String(localized: "avatar.dark_mode", bundle: lang.bundle), binding: $isDarkMode)
            toggleRow(systemImage: "bell.fill", label: String(localized: "avatar.price_alerts", bundle: lang.bundle), binding: $priceAlertsEnabled)
            menuRow(systemImage: "gearshape.fill", label: String(localized: "avatar.app_preferences", bundle: lang.bundle)) { onShowSettings(.preferences) }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Sign Out

    private var signOutButton: some View {
        Button(action: onSignOut) {
            HStack(spacing: 10) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.fmsLoss)
                Text("avatar.sign_out", bundle: lang.bundle)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.fmsLoss)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(4)
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(Color.fmsMuted)
                .textCase(.uppercase)
                .tracking(0.5)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 2)
    }

    private func menuRow(
        systemImage: String,
        label: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.fmsMuted)
                    .frame(width: 28, height: 28)
                    .background(Color.fmsMuted.opacity(0.08), in: RoundedRectangle(cornerRadius: 6))
                Text(label)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.fmsOnSurface)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.fmsMuted)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func toggleRow(
        systemImage: String,
        label: String,
        binding: Binding<Bool>
    ) -> some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 13))
                .foregroundStyle(Color.fmsMuted)
                .frame(width: 28, height: 28)
                .background(Color.fmsMuted.opacity(0.08), in: RoundedRectangle(cornerRadius: 6))
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.fmsOnSurface)
            Spacer()
            Toggle("", isOn: binding)
                .toggleStyle(.switch)
                .labelsHidden()
                .tint(Color.fmsPrimary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}
