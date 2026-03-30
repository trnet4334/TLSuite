// Sources/FMSYSCore/Features/Settings/Views/SettingsView.swift
import SwiftUI

public struct SettingsView: View {
    @State private var selectedTab: SettingsTab
    let displayName: String
    let email: String
    let onDismiss: () -> Void
    @Environment(LanguageManager.self) private var lang

    public init(
        initialTab: SettingsTab = .account,
        displayName: String,
        email: String,
        onDismiss: @escaping () -> Void
    ) {
        self._selectedTab = State(wrappedValue: initialTab)
        self.displayName = displayName
        self.email = email
        self.onDismiss = onDismiss
    }

    public var body: some View {
        HStack(spacing: 0) {
            sidebar
            Divider()
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 860, height: 620)
        .background(Color.fmsBackground)
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text("settings.title", bundle: lang.bundle)
                    .font(.system(size: 18, weight: .heavy))
                    .foregroundStyle(Color.fmsOnSurface)
                Text(displayName)
                    .font(.system(size: 11))
                    .foregroundStyle(Color.fmsMuted)
            }
            .padding(.horizontal, 16)
            .padding(.top, 24)
            .padding(.bottom, 20)

            Divider()
                .padding(.bottom, 8)

            ForEach(SettingsTab.allCases) { tab in
                sidebarRow(tab)
            }

            Spacer()

            Button(action: onDismiss) {
                HStack(spacing: 8) {
                    Image(systemName: "xmark.circle")
                        .font(.system(size: 13))
                    Text("settings.close", bundle: lang.bundle)
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundStyle(Color.fmsMuted)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 8)
            .padding(.bottom, 16)
        }
        .frame(width: 200)
        .background(Color.fmsSurface)
    }

    private func sidebarRow(_ tab: SettingsTab) -> some View {
        Button { selectedTab = tab } label: {
            HStack(spacing: 10) {
                Image(systemName: tab.systemImage)
                    .font(.system(size: 13))
                    .foregroundStyle(selectedTab == tab ? Color.fmsPrimary : Color.fmsMuted)
                    .frame(width: 20)
                Text(tab.rawValue)
                    .font(.system(size: 13, weight: selectedTab == tab ? .semibold : .regular))
                    .foregroundStyle(selectedTab == tab ? Color.fmsOnSurface : Color.fmsMuted)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(
                selectedTab == tab ? Color.fmsPrimary.opacity(0.1) : Color.clear,
                in: RoundedRectangle(cornerRadius: 8)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 8)
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        switch selectedTab {
        case .account:
            AccountManagementView(displayName: displayName, email: email)
        case .preferences:
            AppPreferencesView()
        case .security:
            SecurityPrivacyView()
        case .subscription:
            SubscriptionManagementView()
        case .referral:
            ReferralProgramView()
        }
    }
}
