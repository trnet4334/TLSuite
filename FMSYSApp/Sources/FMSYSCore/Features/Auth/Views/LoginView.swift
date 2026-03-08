import SwiftUI

public struct LoginView: View {
    @State private var viewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""

    let onAuthenticated: () -> Void
    let onMFARequired: (String, String) -> Void

    public init(
        viewModel: AuthViewModel,
        onAuthenticated: @escaping () -> Void,
        onMFARequired: @escaping (String, String) -> Void
    ) {
        self._viewModel = State(wrappedValue: viewModel)
        self.onAuthenticated = onAuthenticated
        self.onMFARequired = onMFARequired
    }

    public var body: some View {
        ZStack {
            // Gradient background
            Color.fmsBackground
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            RadialGradient(
                colors: [Color.fmsPrimary.opacity(0.07), Color.clear],
                center: .init(x: 0.5, y: 0.05),
                startRadius: 0,
                endRadius: 500
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Card
            VStack(spacing: 0) {
                card
            }
            .frame(width: 400)
            .background(Color.fmsSurface, in: RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.4), radius: 40, y: 20)

            // Toast
            if let msg = viewModel.errorMessage {
                VStack {
                    Spacer()
                    ToastOverlay(message: msg, style: .error)
                        .padding(.bottom, 32)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.3), value: viewModel.errorMessage)
        .onChange(of: viewModel.state) { _, state in
            switch state {
            case .authenticated:
                onAuthenticated()
            case .mfaRequired(let t, let u):
                onMFARequired(t, u)
            case .idle:
                break
            }
        }
    }

    // MARK: - Card

    private var card: some View {
        VStack(spacing: 24) {
            cardHeader
            oauthButtons
            divider
            formSection
            footerLinks
        }
        .padding(32)
    }

    private var cardHeader: some View {
        VStack(spacing: 6) {
            Text("TRADING SUITE PRO")
                .font(.system(size: 10, weight: .bold))
                .kerning(2)
                .foregroundStyle(Color.fmsMuted)

            Text("FMSYS")
                .font(.system(size: 42, weight: .heavy))
                .foregroundStyle(Color.fmsOnSurface)

            Text("Secure Login for Trading Suite Pro")
                .font(.system(size: 14))
                .foregroundStyle(Color.fmsMuted)
                .multilineTextAlignment(.center)
        }
    }

    private var oauthButtons: some View {
        VStack(spacing: 10) {
            Button {
                // OAuth — coming soon
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "globe")
                        .font(.system(size: 16, weight: .medium))
                    Text("Continue with Google")
                        .font(.system(size: 14, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2), lineWidth: 1))
                .foregroundStyle(Color.black)
            }
            .buttonStyle(.plain)

            Button {
                // Passkey — coming soon
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "key.fill")
                        .font(.system(size: 16, weight: .medium))
                    Text("Continue with Apple Passkey")
                        .font(.system(size: 14, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.fmsSurface, in: RoundedRectangle(cornerRadius: 12))
                .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
        }
    }

    private var divider: some View {
        HStack(spacing: 12) {
            Rectangle().frame(height: 0.5).foregroundStyle(Color.fmsMuted.opacity(0.4))
            Text("OR").font(.system(size: 11, weight: .semibold)).foregroundStyle(Color.fmsMuted)
            Rectangle().frame(height: 0.5).foregroundStyle(Color.fmsMuted.opacity(0.4))
        }
    }

    private var formSection: some View {
        VStack(spacing: 12) {
            // Email
            VStack(alignment: .leading, spacing: 6) {
                Text("USERNAME / EMAIL")
                    .font(.system(size: 11, weight: .bold))
                    .kerning(0.5)
                    .foregroundStyle(Color.fmsMuted)
                HStack(spacing: 8) {
                    Image(systemName: "at")
                        .foregroundStyle(Color.fmsMuted)
                        .frame(width: 16)
                    TextField("name@company.com", text: $email)
                        .foregroundStyle(Color.fmsOnSurface)
                }
                .padding(12)
                .background(Color.fmsBackground, in: RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.fmsMuted.opacity(0.2), lineWidth: 1))
            }

            // Password
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("PASSWORD")
                        .font(.system(size: 11, weight: .bold))
                        .kerning(0.5)
                        .foregroundStyle(Color.fmsMuted)
                    Spacer()
                    Button("Forgot?") {}
                        .font(.system(size: 12))
                        .foregroundStyle(Color.fmsPrimary)
                        .buttonStyle(.plain)
                }
                HStack(spacing: 8) {
                    Image(systemName: "lock.fill")
                        .foregroundStyle(Color.fmsMuted)
                        .frame(width: 16)
                    SecureField("••••••••", text: $password)
                        .foregroundStyle(Color.fmsOnSurface)
                }
                .padding(12)
                .background(Color.fmsBackground, in: RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.fmsMuted.opacity(0.2), lineWidth: 1))
            }

            // Sign In button
            Button {
                Task { await viewModel.login(email: email, password: password) }
            } label: {
                Group {
                    if viewModel.isLoading {
                        ProgressView().tint(Color.fmsBackground)
                    } else {
                        Text("SIGN IN")
                            .font(.system(size: 14, weight: .bold))
                            .kerning(1)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.fmsPrimary, in: RoundedRectangle(cornerRadius: 12))
                .foregroundStyle(Color.fmsBackground)
                .shadow(color: Color.fmsPrimary.opacity(0.3), radius: 12, y: 4)
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isLoading || email.isEmpty || password.isEmpty)
            .padding(.top, 4)
        }
    }

    private var footerLinks: some View {
        VStack(spacing: 12) {
            HStack(spacing: 4) {
                Text("Don't have an account?")
                    .foregroundStyle(Color.fmsMuted)
                Button("Create an account") {}
                    .foregroundStyle(Color.fmsPrimary)
                    .buttonStyle(.plain)
            }
            .font(.system(size: 13))

            HStack(spacing: 16) {
                Button("Privacy Policy") {}.buttonStyle(.plain)
                Button("Terms") {}.buttonStyle(.plain)
                Button("Contact Support") {}.buttonStyle(.plain)
            }
            .font(.system(size: 11))
            .foregroundStyle(Color.fmsMuted)
        }
    }
}
