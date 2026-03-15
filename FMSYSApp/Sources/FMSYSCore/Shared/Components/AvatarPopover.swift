// Sources/FMSYSCore/Shared/Components/AvatarPopover.swift
import SwiftUI

public struct AvatarPopover: View {
    public let displayName: String
    public let email: String
    public let role: String
    public let onSignOut: () -> Void

    public init(
        displayName: String,
        email: String,
        role: String,
        onSignOut: @escaping () -> Void
    ) {
        self.displayName = displayName
        self.email = email
        self.role = role
        self.onSignOut = onSignOut
    }

    public var body: some View {
        VStack(spacing: 0) {
            // User info header
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

            Divider()

            // Menu items
            VStack(spacing: 0) {
                menuRow(systemImage: "person", label: "Account Management") {}
                menuRow(systemImage: "creditcard", label: "Subscription Management") {}
                menuRow(systemImage: "lock.shield", label: "Security & Privacy") {}
                menuRow(systemImage: "person.3", label: "Referral Program") {}
            }
            .padding(.vertical, 4)

            Divider()

            // Sign out
            Button(action: onSignOut) {
                HStack(spacing: 10) {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.fmsLoss)
                    Text("Sign Out")
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
        .frame(width: 280)
        .background(Color.fmsSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
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
}
