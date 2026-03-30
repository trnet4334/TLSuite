// Sources/FMSYSCore/Features/Settings/Views/SecurityPrivacyView.swift
import SwiftUI

public struct SecurityPrivacyView: View {
    @State private var sharePerformanceData = true
    @State private var publicProfile = false
    @State private var marketingEmails = true
    @State private var showDeleteAlert = false
    @State private var showDisableAlert = false

    @Environment(LanguageManager.self) private var lang

    private struct LoginEntry: Identifiable {
        let id = UUID()
        let time: String
        let device: String
        let location: String
        let ip: String
        let status: LoginStatus
    }

    private enum LoginStatus {
        case success, blocked, flagged
        var label: String {
            switch self { case .success: return "Success"; case .blocked: return "Blocked"; case .flagged: return "Flagged" }
        }
        var color: Color {
            switch self { case .success: return .green; case .blocked: return Color.fmsLoss; case .flagged: return Color.fmsWarning }
        }
    }

    private let loginHistory: [LoginEntry] = [
        LoginEntry(time: "Oct 24, 10:45 AM", device: "MacBook Pro M3",   location: "San Francisco, USA", ip: "192.168.1.45", status: .success),
        LoginEntry(time: "Oct 23, 09:12 PM", device: "iPhone 15 Pro",    location: "San Francisco, USA", ip: "172.16.25.1",  status: .success),
        LoginEntry(time: "Oct 22, 02:30 AM", device: "Unknown Chrome",   location: "Moscow, Russia",      ip: "95.161.22.14", status: .blocked),
        LoginEntry(time: "Oct 20, 11:15 AM", device: "Windows PC",       location: "London, UK",          ip: "82.44.112.5", status: .flagged),
    ]

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                privacySection
                apiSection
                loginHistorySection
                dangerZoneSection
            }
            .padding(28)
        }
        .background(Color.fmsBackground)
        .alert(String(localized: "security.disable_alert_title", bundle: lang.bundle), isPresented: $showDisableAlert) {
            Button(String(localized: "common.cancel", bundle: lang.bundle), role: .cancel) {}
            Button(String(localized: "security.disable_confirm", bundle: lang.bundle), role: .destructive) {}
        } message: {
            Text("security.freeze_warning", bundle: lang.bundle)
        }
        .alert(String(localized: "security.delete_alert_title", bundle: lang.bundle), isPresented: $showDeleteAlert) {
            Button(String(localized: "common.cancel", bundle: lang.bundle), role: .cancel) {}
            Button(String(localized: "security.delete_forever_confirm", bundle: lang.bundle), role: .destructive) {}
        } message: {
            Text("security.delete_warning", bundle: lang.bundle)
        }
    }

    // MARK: - Privacy

    private var privacySection: some View {
        sectionCard(
            title: String(localized: "security.privacy_controls_title", bundle: lang.bundle),
            subtitle: String(localized: "security.privacy_controls_subtitle", bundle: lang.bundle)
        ) {
            privacyToggle(
                title: String(localized: "security.privacy_share_perf", bundle: lang.bundle),
                subtitle: String(localized: "security.privacy_share_perf_sub", bundle: lang.bundle),
                binding: $sharePerformanceData
            )
            Divider()
            privacyToggle(
                title: String(localized: "security.privacy_public_profile", bundle: lang.bundle),
                subtitle: String(localized: "security.privacy_public_profile_sub", bundle: lang.bundle),
                binding: $publicProfile
            )
            Divider()
            privacyToggle(
                title: String(localized: "security.privacy_marketing", bundle: lang.bundle),
                subtitle: String(localized: "security.privacy_marketing_sub", bundle: lang.bundle),
                binding: $marketingEmails
            )
        }
    }

    private func privacyToggle(title: String, subtitle: String, binding: Binding<Bool>) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.fmsOnSurface)
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(Color.fmsMuted)
            }
            Spacer(minLength: 20)
            Toggle("", isOn: binding)
                .toggleStyle(.switch)
                .labelsHidden()
                .tint(Color.fmsPrimary)
        }
        .padding(.vertical, 6)
    }

    // MARK: - API

    private var apiSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("security.api_management", bundle: lang.bundle)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.fmsOnSurface)
                    Text("security.api_sub", bundle: lang.bundle)
                        .font(.system(size: 11))
                        .foregroundStyle(Color.fmsMuted)
                }
                Spacer()
                Button {
                } label: {
                    Label(String(localized: "security.api_create_key", bundle: lang.bundle), systemImage: "plus")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color.fmsBackground)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.fmsPrimary, in: RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
            .padding(.bottom, 12)

            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.fmsMuted.opacity(0.1))
                        .frame(width: 40, height: 40)
                    Image(systemName: "terminal")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.fmsMuted)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Trading Terminal Bot Alpha")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color.fmsOnSurface)
                    Text("security.last_used", bundle: lang.bundle)
                        .font(.system(size: 11))
                        .foregroundStyle(Color.fmsMuted)
                }
                Spacer()
                Button(String(localized: "security.revoke_access", bundle: lang.bundle)) {}
                    .buttonStyle(.plain)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color.fmsLoss)
            }
            .padding(12)
            .background(Color.fmsMuted.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.fmsMuted.opacity(0.1)))
        }
        .padding(16)
        .background(Color.fmsSurface, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.fmsMuted.opacity(0.12)))
    }

    // MARK: - Login History

    private var loginHistorySection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("security.login_history", bundle: lang.bundle)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.fmsOnSurface)
                    Text("security.login_history_sub", bundle: lang.bundle)
                        .font(.system(size: 11))
                        .foregroundStyle(Color.fmsMuted)
                }
                Spacer()
                Button {
                } label: {
                    Label(String(localized: "security.export_log", bundle: lang.bundle), systemImage: "arrow.down.doc")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.fmsMuted)
                }
                .buttonStyle(.plain)
            }
            .padding(16)
            .padding(.bottom, 0)

            Divider()

            // Header row
            HStack {
                Text("security.time", bundle: lang.bundle).frame(width: 130, alignment: .leading)
                Text("security.device", bundle: lang.bundle).frame(maxWidth: .infinity, alignment: .leading)
                Text("security.location", bundle: lang.bundle).frame(maxWidth: .infinity, alignment: .leading)
                Text("security.ip", bundle: lang.bundle).frame(width: 110, alignment: .leading)
                Text("security.status", bundle: lang.bundle).frame(width: 70, alignment: .leading)
            }
            .font(.system(size: 9, weight: .bold))
            .foregroundStyle(Color.fmsMuted)
            .textCase(.uppercase)
            .tracking(0.5)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.fmsMuted.opacity(0.04))

            ForEach(loginHistory) { entry in
                loginRow(entry)
                if entry.id != loginHistory.last?.id {
                    Divider().padding(.horizontal, 16)
                }
            }
        }
        .background(Color.fmsSurface, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.fmsMuted.opacity(0.12)))
    }

    private func loginRow(_ entry: LoginEntry) -> some View {
        HStack {
            Text(entry.time)
                .frame(width: 130, alignment: .leading)
                .foregroundStyle(Color.fmsMuted)
            Text(entry.device)
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundStyle(Color.fmsOnSurface)
                .fontWeight(.medium)
            Text(entry.location)
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundStyle(Color.fmsMuted)
            Text(entry.ip)
                .frame(width: 110, alignment: .leading)
                .foregroundStyle(Color.fmsMuted)
                .font(.system(size: 11, design: .monospaced))
            statusBadge(entry.status)
                .frame(width: 70, alignment: .leading)
        }
        .font(.system(size: 12))
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private func statusBadge(_ status: LoginStatus) -> some View {
        Text(status.label)
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(status.color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(status.color.opacity(0.12), in: Capsule())
    }

    // MARK: - Danger Zone

    private var dangerZoneSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 2) {
                Text("security.danger_zone", bundle: lang.bundle)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.fmsLoss)
                Text("security.danger_sub", bundle: lang.bundle)
                    .font(.system(size: 11))
                    .foregroundStyle(Color.fmsLoss.opacity(0.7))
            }
            .padding(16)
            .padding(.bottom, 0)

            Divider().overlay(Color.fmsLoss.opacity(0.15))

            dangerRow(
                title: String(localized: "security.disable_title", bundle: lang.bundle),
                subtitle: String(localized: "security.freeze_warning", bundle: lang.bundle),
                buttonLabel: String(localized: "security.disable_confirm", bundle: lang.bundle),
                destructive: false
            ) { showDisableAlert = true }

            Divider().padding(.horizontal, 16).overlay(Color.fmsLoss.opacity(0.1))

            dangerRow(
                title: String(localized: "security.delete_title", bundle: lang.bundle),
                subtitle: String(localized: "security.delete_warning", bundle: lang.bundle),
                buttonLabel: String(localized: "security.delete_account_btn", bundle: lang.bundle),
                destructive: true
            ) { showDeleteAlert = true }
        }
        .background(Color.fmsLoss.opacity(0.04), in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.fmsLoss.opacity(0.2)))
    }

    private func dangerRow(title: String, subtitle: String, buttonLabel: String, destructive: Bool, action: @escaping () -> Void) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.fmsOnSurface)
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(Color.fmsMuted)
            }
            Spacer()
            Button(buttonLabel, action: action)
                .buttonStyle(.plain)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Color.fmsLoss)
                .padding(.horizontal, 16)
                .padding(.vertical, 7)
                .background(
                    destructive ? Color.fmsLoss : Color.clear,
                    in: RoundedRectangle(cornerRadius: 8)
                )
                .foregroundStyle(destructive ? Color.white : Color.fmsLoss)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Color.fmsLoss.opacity(destructive ? 0 : 0.4))
                )
        }
        .padding(16)
    }

    // MARK: - Helper

    @ViewBuilder
    private func sectionCard<Content: View>(title: String, subtitle: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.fmsOnSurface)
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(Color.fmsMuted)
            }
            .padding(16)
            .padding(.bottom, 0)

            Divider()

            VStack(spacing: 0) {
                content()
            }
            .padding(16)
        }
        .background(Color.fmsSurface, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.fmsMuted.opacity(0.12)))
    }
}
