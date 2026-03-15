// Sources/FMSYSCore/Shared/Components/SettingsPopover.swift
import SwiftUI

public struct SettingsPopover: View {
    @AppStorage("isDarkMode") private var isDarkMode = true
    @AppStorage("priceAlertsEnabled") private var priceAlertsEnabled = false

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            // Handle pill
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.fmsMuted.opacity(0.3))
                .frame(width: 32, height: 4)
                .padding(.top, 10)

            Text("Quick Settings")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Color.fmsOnSurface)
                .padding(.top, 8)
                .padding(.bottom, 8)

            VStack(spacing: 2) {
                toggleRow(systemImage: "moon.fill", label: "Dark Mode", binding: $isDarkMode)
                toggleRow(systemImage: "bell.fill", label: "Price Alerts", binding: $priceAlertsEnabled)

                Divider()
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)

                navigateRow(systemImage: "gearshape.fill", label: "App Preferences")
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 12)
        }
        .frame(width: 300)
        .background(Color.fmsSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func toggleRow(
        systemImage: String,
        label: String,
        binding: Binding<Bool>
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 14))
                .foregroundStyle(Color.fmsMuted)
                .frame(width: 34, height: 34)
                .background(Color.fmsMuted.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.fmsOnSurface)
            Spacer()
            Toggle("", isOn: binding)
                .toggleStyle(.switch)
                .labelsHidden()
                .tint(Color.fmsPrimary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
    }

    private func navigateRow(systemImage: String, label: String) -> some View {
        Button {} label: {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.fmsMuted)
                    .frame(width: 34, height: 34)
                    .background(Color.fmsMuted.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                Text(label)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.fmsOnSurface)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.fmsMuted)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
