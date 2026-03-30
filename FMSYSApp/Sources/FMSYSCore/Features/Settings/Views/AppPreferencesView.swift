// Sources/FMSYSCore/Features/Settings/Views/AppPreferencesView.swift
import SwiftUI

public struct AppPreferencesView: View {
    @AppStorage("isDarkMode") private var isDarkMode = true
    @AppStorage("priceAlertsEnabled") private var priceAlertsEnabled = false
    @State private var themeMode: ThemeMode = .system
    @State private var autoSave = true
    @State private var soundEffects = false
    @State private var selectedLanguage: String = LanguageManager.shared.currentLanguage
    @State private var refreshRate: Double = 0

    @Environment(LanguageManager.self) private var lang

    private enum ThemeMode: String, CaseIterable {
        case system = "System"
        case light  = "Light"
        case dark   = "Dark"
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                headerSection
                appearanceSection
                behaviorSection
                bottomActions
            }
            .padding(28)
        }
        .background(Color.fmsBackground)
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("prefs.title", bundle: lang.bundle)
                .font(.system(size: 22, weight: .heavy))
                .foregroundStyle(Color.fmsOnSurface)
            Text("prefs.subtitle", bundle: lang.bundle)
                .font(.system(size: 13))
                .foregroundStyle(Color.fmsMuted)
        }
    }

    // MARK: - Appearance

    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label(String(localized: "prefs.appearance", bundle: lang.bundle), systemImage: "paintpalette")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.fmsOnSurface)

            HStack(spacing: 12) {
                ForEach(ThemeMode.allCases, id: \.self) { mode in
                    themeCard(mode)
                }
            }
        }
    }

    private func themeCard(_ mode: ThemeMode) -> some View {
        let label: String = {
            switch mode {
            case .system: return String(localized: "prefs.theme_system", bundle: lang.bundle)
            case .light:  return String(localized: "prefs.theme_light",  bundle: lang.bundle)
            case .dark:   return String(localized: "prefs.theme_dark",   bundle: lang.bundle)
            }
        }()
        return Button { themeMode = mode } label: {
            VStack(spacing: 10) {
                themePreview(mode)
                    .frame(height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.fmsOnSurface)
            }
            .padding(12)
            .frame(maxWidth: .infinity)
            .background(
                themeMode == mode
                    ? Color.fmsPrimary.opacity(0.08)
                    : Color.fmsSurface,
                in: RoundedRectangle(cornerRadius: 12)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(
                        themeMode == mode ? Color.fmsPrimary : Color.fmsMuted.opacity(0.12),
                        lineWidth: themeMode == mode ? 2 : 1
                    )
            )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func themePreview(_ mode: ThemeMode) -> some View {
        switch mode {
        case .system:
            HStack(spacing: 0) {
                Rectangle().fill(Color.white)
                Rectangle().fill(Color(white: 0.12))
            }
        case .light:
            Rectangle().fill(Color.white)
                .overlay(alignment: .topLeading) {
                    VStack(alignment: .leading, spacing: 3) {
                        Capsule().fill(Color(white: 0.85)).frame(width: 32, height: 4)
                        Capsule().fill(Color(white: 0.9)).frame(width: 48, height: 4)
                    }.padding(8)
                }
        case .dark:
            Rectangle().fill(Color(white: 0.1))
                .overlay(alignment: .topLeading) {
                    VStack(alignment: .leading, spacing: 3) {
                        Capsule().fill(Color(white: 0.25)).frame(width: 32, height: 4)
                        Capsule().fill(Color(white: 0.2)).frame(width: 48, height: 4)
                    }.padding(8)
                }
        }
    }

    // MARK: - Behavior

    private var behaviorSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Label(String(localized: "prefs.behavior", bundle: lang.bundle), systemImage: "app.badge.checkmark")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.fmsOnSurface)
                .padding(.bottom, 16)

            Divider()

            behaviorToggleRow(
                title: String(localized: "prefs.auto_save",     bundle: lang.bundle),
                subtitle: String(localized: "prefs.auto_save_sub", bundle: lang.bundle),
                binding: $autoSave
            )
            Divider()
            behaviorToggleRow(
                title: String(localized: "prefs.sound_effects",     bundle: lang.bundle),
                subtitle: String(localized: "prefs.sound_effects_sub", bundle: lang.bundle),
                binding: $soundEffects
            )
            Divider()

            // Language picker
            VStack(alignment: .leading, spacing: 4) {
                VStack(alignment: .leading, spacing: 1) {
                    Text("prefs.language", bundle: lang.bundle)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.fmsOnSurface)
                    Text("prefs.language_sub", bundle: lang.bundle)
                        .font(.system(size: 11))
                        .foregroundStyle(Color.fmsMuted)
                }
                Picker(String(localized: "prefs.language", bundle: lang.bundle), selection: $selectedLanguage) {
                    ForEach(LanguageManager.languageOptions, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .tint(Color.fmsPrimary)
                .padding(.top, 4)
            }
            .padding(.vertical, 14)

            Divider()

            // Refresh rate
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("prefs.refresh_rate", bundle: lang.bundle)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.fmsOnSurface)
                    Spacer()
                    Text(refreshLabel)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color.fmsPrimary)
                }
                Slider(value: $refreshRate, in: 0...100)
                    .tint(Color.fmsPrimary)
                HStack {
                    Text("prefs.realtime",   bundle: lang.bundle).font(.system(size: 9, weight: .bold)).foregroundStyle(Color.fmsMuted).textCase(.uppercase)
                    Spacer()
                    Text("prefs.balanced",   bundle: lang.bundle).font(.system(size: 9, weight: .bold)).foregroundStyle(Color.fmsMuted).textCase(.uppercase)
                    Spacer()
                    Text("prefs.power_save", bundle: lang.bundle).font(.system(size: 9, weight: .bold)).foregroundStyle(Color.fmsMuted).textCase(.uppercase)
                }
            }
            .padding(.vertical, 14)
        }
        .padding(16)
        .background(Color.fmsSurface, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.fmsMuted.opacity(0.12)))
    }

    private var refreshLabel: String {
        if refreshRate < 34 { return String(localized: "prefs.realtime",   bundle: lang.bundle) }
        if refreshRate < 67 { return String(localized: "prefs.balanced",   bundle: lang.bundle) }
        return String(localized: "prefs.power_save", bundle: lang.bundle)
    }

    private func behaviorToggleRow(title: String, subtitle: String, binding: Binding<Bool>) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.fmsOnSurface)
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(Color.fmsMuted)
            }
            Spacer()
            Toggle("", isOn: binding)
                .toggleStyle(.switch)
                .labelsHidden()
                .tint(Color.fmsPrimary)
        }
        .padding(.vertical, 12)
    }

    // MARK: - Bottom Actions

    private var bottomActions: some View {
        HStack {
            Spacer()
            Button(String(localized: "prefs.reset", bundle: lang.bundle)) {
                themeMode = .system
                autoSave = true
                soundEffects = false
                selectedLanguage = "English (United States)"
                refreshRate = 0
            }
            .buttonStyle(.plain)
            .font(.system(size: 13, weight: .medium))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.fmsSurface, in: RoundedRectangle(cornerRadius: 8))
            .foregroundStyle(Color.fmsMuted)
            .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color.fmsMuted.opacity(0.2)))

            Button(String(localized: "prefs.save", bundle: lang.bundle)) {
                lang.set(language: selectedLanguage)
                isDarkMode = themeMode == .dark || (themeMode == .system)
            }
            .buttonStyle(.plain)
            .font(.system(size: 13, weight: .semibold))
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .background(Color.fmsPrimary, in: RoundedRectangle(cornerRadius: 8))
            .foregroundStyle(Color.fmsBackground)
        }
    }
}
