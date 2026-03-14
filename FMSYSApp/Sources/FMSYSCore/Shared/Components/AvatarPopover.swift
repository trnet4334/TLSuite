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
        VStack(alignment: .leading, spacing: 0) {
            // User info header
            HStack(spacing: 12) {
                Circle()
                    .fill(Color.fmsMuted.opacity(0.3))
                    .frame(width: 40, height: 40)
                    .overlay {
                        Image(systemName: "person.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(Color.fmsMuted)
                    }
                VStack(alignment: .leading, spacing: 2) {
                    Text(displayName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.fmsOnSurface)
                    Text(email)
                        .font(.system(size: 11))
                        .foregroundStyle(Color.fmsMuted)
                    Text(role)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color.fmsBackground)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.fmsPrimary, in: Capsule())
                }
            }
            .padding(16)

            Divider()

            // Actions
            VStack(spacing: 0) {
                Button {
                    // TODO: navigate to Settings screen
                } label: {
                    Label("Account Settings", systemImage: "gearshape")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.fmsOnSurface)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Button(role: .destructive) {
                    onSignOut()
                } label: {
                    Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.fmsLoss)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 4)
        }
        .frame(width: 260)
        .background(Color.fmsSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
