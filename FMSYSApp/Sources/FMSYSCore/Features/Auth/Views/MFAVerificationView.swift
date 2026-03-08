import SwiftUI

public struct MFAVerificationView: View {
    @State private var viewModel: MFAViewModel
    @State private var code = ""

    let onAuthenticated: () -> Void

    public init(
        viewModel: MFAViewModel,
        onAuthenticated: @escaping () -> Void
    ) {
        self._viewModel = State(wrappedValue: viewModel)
        self.onAuthenticated = onAuthenticated
    }

    public var body: some View {
        ZStack {
            Color.fmsBackground
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            VStack(spacing: 0) {
                // Window chrome row
                HStack {
                    HStack(spacing: 6) {
                        Circle().fill(Color(hex: "#ff5f57")).frame(width: 12, height: 12)
                        Circle().fill(Color(hex: "#ffbd2e")).frame(width: 12, height: 12)
                        Circle().fill(Color(hex: "#28c840")).frame(width: 12, height: 12)
                    }
                    Spacer()
                    Text("FMSYS")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.fmsOnSurface)
                    Spacer()
                    HStack(spacing: 6) {
                        Circle().fill(Color.clear).frame(width: 12, height: 12)
                        Circle().fill(Color.clear).frame(width: 12, height: 12)
                        Circle().fill(Color.clear).frame(width: 12, height: 12)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(Color.fmsSurface.opacity(0.6))
                .overlay(alignment: .bottom) {
                    Rectangle().frame(height: 0.5).foregroundStyle(Color.fmsMuted.opacity(0.2))
                }

                // Content
                VStack(spacing: 28) {
                    // Shield icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.fmsPrimary.opacity(0.12))
                            .frame(width: 80, height: 80)
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(Color.fmsPrimary)
                    }
                    .padding(.top, 32)

                    // Title
                    VStack(spacing: 8) {
                        Text("Verify Identity")
                            .font(.system(size: 24, weight: .heavy))
                            .foregroundStyle(Color.fmsOnSurface)
                        Text("Enter the 6-digit code from\nyour authenticator app")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.fmsMuted)
                            .multilineTextAlignment(.center)
                    }

                    // OTP inputs
                    OTPFieldView(code: $code) { completed in
                        Task { await viewModel.verify(code: completed) }
                    }

                    // Locked state or Verify button
                    if viewModel.isLocked {
                        Label("Account locked. Too many attempts.", systemImage: "lock.fill")
                            .font(.footnote)
                            .foregroundStyle(Color.fmsLoss)
                    } else {
                        VStack(spacing: 16) {
                            Button {
                                Task { await viewModel.verify(code: code) }
                            } label: {
                                Group {
                                    if viewModel.isLoading {
                                        ProgressView().tint(Color.fmsBackground)
                                    } else {
                                        Text("Verify Identity")
                                            .font(.system(size: 14, weight: .bold))
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.fmsPrimary, in: RoundedRectangle(cornerRadius: 12))
                                .foregroundStyle(Color.fmsBackground)
                                .shadow(color: Color.fmsPrimary.opacity(0.3), radius: 12, y: 4)
                            }
                            .buttonStyle(.plain)
                            .disabled(viewModel.isLoading || code.count < 6)

                            Button("Resend code") {}
                                .font(.system(size: 13))
                                .foregroundStyle(Color.fmsPrimary)
                                .buttonStyle(.plain)
                        }
                    }

                    // Method pill
                    HStack(spacing: 8) {
                        Image(systemName: "iphone")
                            .font(.system(size: 13))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Method").font(.system(size: 10)).foregroundStyle(Color.fmsMuted)
                            Text("Google Authenticator").font(.system(size: 12, weight: .semibold))
                        }
                    }
                    .foregroundStyle(Color.fmsOnSurface)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.fmsBackground.opacity(0.5), in: Capsule())
                    .padding(.bottom, 32)
                }
                .padding(.horizontal, 40)
            }

            // Error toast
            if let msg = viewModel.errorMessage, !viewModel.isLocked {
                VStack {
                    Spacer()
                    ToastOverlay(message: msg, style: .error)
                        .padding(.bottom, 32)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.3), value: viewModel.errorMessage)
        .onChange(of: viewModel.isAuthenticated) { _, authenticated in
            if authenticated { onAuthenticated() }
        }
    }
}
