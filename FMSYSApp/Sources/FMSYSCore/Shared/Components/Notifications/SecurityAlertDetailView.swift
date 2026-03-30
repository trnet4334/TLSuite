// Sources/FMSYSCore/Shared/Components/Notifications/SecurityAlertDetailView.swift
import SwiftUI

public struct SecurityAlertDetailView: View {
    let notification: AppNotification
    let onDismiss: () -> Void
    let onRemove: (() -> Void)?
    let onViewSettings: (() -> Void)?
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
                    .fill(Color.orange.opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: "exclamationmark.shield.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(Color.orange)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text("notification.security_alert.type", bundle: lang.bundle)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.orange)
                    .textCase(.uppercase)
                    .tracking(0.5)
                Text(notification.title)
                    .font(.system(size: 15, weight: .heavy))
                    .foregroundStyle(Color.fmsOnSurface)
                    .lineLimit(2)
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
        VStack(alignment: .leading, spacing: 16) {
            Text(notification.body)
                .font(.system(size: 13))
                .foregroundStyle(Color.fmsMuted)
                .lineSpacing(3)

            // Details box
            VStack(spacing: 0) {
                detailRow(icon: "desktopcomputer", label: String(localized: "notification.security_alert.device", bundle: lang.bundle), value: "MacBook Pro (macOS 14.2)")
                Divider().padding(.horizontal, 12)
                detailRow(icon: "globe", label: String(localized: "notification.security_alert.ip_address", bundle: lang.bundle), value: "192.168.1.1")
                Divider().padding(.horizontal, 12)
                detailRow(icon: "location.fill", label: String(localized: "notification.security_alert.location", bundle: lang.bundle), value: "San Francisco, CA")
            }
            .background(Color.fmsMuted.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.fmsMuted.opacity(0.1)))

            // Map placeholder
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.fmsMuted.opacity(0.08))
                    .frame(height: 100)
                HStack(spacing: 8) {
                    Image(systemName: "map.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(Color.fmsMuted.opacity(0.4))
                    Text("San Francisco, CA")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.fmsMuted)
                }
            }
        }
        .padding(20)
    }

    private func detailRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(Color.fmsMuted)
                .frame(width: 16)
            Text(label.uppercased())
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(Color.fmsMuted)
                .tracking(0.5)
            Spacer()
            Text(value)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.fmsOnSurface)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
    }

    // MARK: - Footer

    private var footer: some View {
        HStack(spacing: 10) {
            Button(String(localized: "common.view_settings", bundle: lang.bundle)) { onViewSettings?() }
                .buttonStyle(.plain)
                .font(.system(size: 13, weight: .bold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .background(Color.fmsPrimary, in: RoundedRectangle(cornerRadius: 10))
                .foregroundStyle(Color.fmsBackground)
            Button(String(localized: "common.archive", bundle: lang.bundle)) { onAchieve?() }
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
