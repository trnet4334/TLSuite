// Sources/FMSYSCore/Features/Settings/Views/AccountManagementView.swift
import SwiftUI

public struct AccountManagementView: View {
    @State private var fullName: String
    @State private var emailAddress: String
    @State private var phoneNumber = "212 555-0198"
    @State private var region = "New York, USA"
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var twoFactorEnabled = true
    @State private var showDeactivateAlert = false

    @Environment(LanguageManager.self) private var lang

    public init(displayName: String, email: String) {
        self._fullName = State(wrappedValue: displayName)
        self._emailAddress = State(wrappedValue: email)
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                profileHeader
                HStack(alignment: .top, spacing: 20) {
                    personalInfoSection
                    securitySection
                }
                accountPreferencesSection
            }
            .padding(28)
        }
        .background(Color.fmsBackground)
        .alert(String(localized: "account.deactivate_alert_title", bundle: lang.bundle), isPresented: $showDeactivateAlert) {
            Button(String(localized: "common.cancel", bundle: lang.bundle), role: .cancel) {}
            Button(String(localized: "account.deactivate_confirm", bundle: lang.bundle), role: .destructive) {}
        } message: {
            Text("account.deactivate_message", bundle: lang.bundle)
        }
    }

    // MARK: - Profile Header

    private var profileHeader: some View {
        HStack(spacing: 20) {
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(LinearGradient(
                        colors: [Color.fmsPrimary.opacity(0.4), Color.fmsPrimary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 80, height: 80)
                    .overlay {
                        Image(systemName: "person.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(Color.fmsBackground)
                    }
                Circle()
                    .fill(Color.fmsSurface)
                    .frame(width: 26, height: 26)
                    .overlay {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.fmsPrimary)
                    }
                    .overlay(Circle().stroke(Color.fmsBackground, lineWidth: 2))
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(fullName)
                    .font(.system(size: 20, weight: .heavy))
                    .foregroundStyle(Color.fmsOnSurface)
                Text("account.member_since", bundle: lang.bundle)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.fmsMuted)
                HStack(spacing: 6) {
                    Text("account.kyc", bundle: lang.bundle)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Color.fmsPrimary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.fmsPrimary.opacity(0.1), in: Capsule())
                        .overlay(Capsule().stroke(Color.fmsPrimary.opacity(0.2)))
                    Text("ID: 4829-THM")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Color.fmsMuted)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.fmsMuted.opacity(0.08), in: Capsule())
                }
            }

            Spacer()

            Button(String(localized: "account.update_profile", bundle: lang.bundle)) {}
                .buttonStyle(.plain)
                .font(.system(size: 13, weight: .bold))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.fmsPrimary, in: RoundedRectangle(cornerRadius: 8))
                .foregroundStyle(Color.fmsBackground)
        }
        .padding(20)
        .background(Color.fmsSurface, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.fmsPrimary.opacity(0.1)))
    }

    // MARK: - Personal Information

    private var personalInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(String(localized: "account.personal_info", bundle: lang.bundle), systemImage: "person.crop.rectangle")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Color.fmsOnSurface)

            VStack(spacing: 12) {
                fieldRow(label: String(localized: "account.field_full_name", bundle: lang.bundle), text: $fullName)
                fieldRow(label: String(localized: "account.field_email", bundle: lang.bundle), text: $emailAddress)
                fieldRow(label: String(localized: "account.field_phone", bundle: lang.bundle), text: $phoneNumber)
                fieldRow(label: String(localized: "account.field_region", bundle: lang.bundle), text: $region)
            }
            .padding(16)
            .background(Color.fmsSurface, in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.fmsPrimary.opacity(0.1)))
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Security

    private var securitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(String(localized: "account.security_auth", bundle: lang.bundle), systemImage: "shield.checkered")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Color.fmsOnSurface)

            VStack(alignment: .leading, spacing: 12) {
                Text("security.change_password", bundle: lang.bundle)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.fmsMuted)

                SecureFieldRow(
                    label: String(localized: "account.field_current_password", bundle: lang.bundle),
                    placeholder: "••••••••",
                    text: $currentPassword
                )
                SecureFieldRow(
                    label: String(localized: "account.field_new_password", bundle: lang.bundle),
                    placeholder: String(localized: "account.password_placeholder", bundle: lang.bundle),
                    text: $newPassword
                )

                Button(String(localized: "account.update_password", bundle: lang.bundle)) {}
                    .buttonStyle(.plain)
                    .font(.system(size: 12, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.fmsPrimary.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                    .foregroundStyle(Color.fmsPrimary)
            }
            .padding(16)
            .background(Color.fmsSurface, in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.fmsPrimary.opacity(0.1)))

            // 2FA
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.fmsPrimary.opacity(0.1))
                        .frame(width: 36, height: 36)
                    Image(systemName: "iphone.and.arrow.forward")
                        .font(.system(size: 15))
                        .foregroundStyle(Color.fmsPrimary)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("account.two_factor_title", bundle: lang.bundle)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color.fmsOnSurface)
                    Text("account.two_factor_subtitle", bundle: lang.bundle)
                        .font(.system(size: 11))
                        .foregroundStyle(Color.fmsMuted)
                }
                Spacer()
                Toggle("", isOn: $twoFactorEnabled)
                    .toggleStyle(.switch)
                    .labelsHidden()
                    .tint(Color.fmsPrimary)
            }
            .padding(12)
            .background(Color.fmsSurface, in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.fmsPrimary.opacity(0.1)))

            if twoFactorEnabled {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.fmsPrimary)
                    Text("account.two_factor_info", bundle: lang.bundle)
                        .font(.system(size: 11))
                        .foregroundStyle(Color.fmsMuted)
                }
                .padding(10)
                .background(Color.fmsMuted.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color.fmsMuted.opacity(0.2), style: StrokeStyle(lineWidth: 1, dash: [4])))
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Account Preferences

    private var accountPreferencesSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("account.preferences", bundle: lang.bundle)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.fmsOnSurface)
                Text("account.adjust", bundle: lang.bundle)
                    .font(.system(size: 11))
                    .foregroundStyle(Color.fmsMuted)
            }
            Spacer()
            HStack(spacing: 8) {
                Button(String(localized: "account.export_data", bundle: lang.bundle)) {}
                    .buttonStyle(.plain)
                    .font(.system(size: 12, weight: .medium))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(Color.fmsSurface, in: RoundedRectangle(cornerRadius: 8))
                    .foregroundStyle(Color.fmsOnSurface)
                    .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color.fmsMuted.opacity(0.2)))
                Button(String(localized: "account.deactivate", bundle: lang.bundle)) { showDeactivateAlert = true }
                    .buttonStyle(.plain)
                    .font(.system(size: 12, weight: .medium))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(Color.fmsLoss.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
                    .foregroundStyle(Color.fmsLoss)
                    .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color.fmsLoss.opacity(0.2)))
            }
        }
        .padding(16)
        .background(Color.fmsMuted.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.fmsPrimary.opacity(0.06)))
    }

    // MARK: - Helpers

    private func fieldRow(label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(Color.fmsMuted)
                .textCase(.uppercase)
                .tracking(0.5)
            TextField("", text: text)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .foregroundStyle(Color.fmsOnSurface)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(Color.fmsBackground, in: RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color.fmsMuted.opacity(0.15)))
        }
    }
}

private struct SecureFieldRow: View {
    let label: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(Color.fmsMuted)
                .textCase(.uppercase)
                .tracking(0.5)
            SecureField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .foregroundStyle(Color.fmsOnSurface)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(Color.fmsBackground, in: RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color.fmsMuted.opacity(0.15)))
        }
    }
}
