import SwiftUI

public struct LoginView: View {
    @State private var viewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @Environment(LanguageManager.self) private var lang

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
            formSection
            footerLinks
        }
        .padding(32)
    }

    private var cardHeader: some View {
        VStack(spacing: 6) {
            Text("auth.app_name", bundle: lang.bundle)
                .font(.system(size: 10, weight: .bold))
                .kerning(2)
                .foregroundStyle(Color.fmsMuted)

            Text("FMSYS")
                .font(.system(size: 42, weight: .heavy))
                .foregroundStyle(Color.fmsOnSurface)

            Text("auth.tagline", bundle: lang.bundle)
                .font(.system(size: 14))
                .foregroundStyle(Color.fmsMuted)
                .multilineTextAlignment(.center)
        }
    }

    private var formSection: some View {
        VStack(spacing: 12) {
            // Email
            VStack(alignment: .leading, spacing: 6) {
                Text("auth.username_label", bundle: lang.bundle)
                    .font(.system(size: 11, weight: .bold))
                    .kerning(0.5)
                    .foregroundStyle(Color.fmsMuted)
                HStack(spacing: 8) {
                    Image(systemName: "at")
                        .foregroundStyle(Color.fmsMuted)
                        .frame(width: 16)
                    TextField(
                        String(localized: "auth.email_placeholder", bundle: lang.bundle),
                        text: $email
                    )
                    .foregroundStyle(Color.fmsOnSurface)
                }
                .padding(12)
                .background(Color.fmsBackground, in: RoundedRectangle(cornerRadius: 10))
            }

            // Password
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("auth.password_label", bundle: lang.bundle)
                        .font(.system(size: 11, weight: .bold))
                        .kerning(0.5)
                        .foregroundStyle(Color.fmsMuted)
                    Spacer()
                    Button(String(localized: "auth.forgot_password", bundle: lang.bundle)) {}
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
            }

            // Sign In button
            Button {
                Task { await viewModel.login(email: email, password: password) }
            } label: {
                Group {
                    if viewModel.isLoading {
                        ProgressView().tint(Color.fmsBackground)
                    } else {
                        Text("auth.sign_in", bundle: lang.bundle)
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
                Text("auth.no_account", bundle: lang.bundle)
                    .foregroundStyle(Color.fmsMuted)
                Button(String(localized: "auth.create_account", bundle: lang.bundle)) {}
                    .foregroundStyle(Color.fmsPrimary)
                    .buttonStyle(.plain)
            }
            .font(.system(size: 13))

            HStack(spacing: 16) {
                Button(String(localized: "auth.privacy_policy", bundle: lang.bundle)) {}.buttonStyle(.plain)
                Button(String(localized: "auth.terms", bundle: lang.bundle)) {}.buttonStyle(.plain)
                Button(String(localized: "auth.contact_support", bundle: lang.bundle)) {}.buttonStyle(.plain)
            }
            .font(.system(size: 11))
            .foregroundStyle(Color.fmsMuted)
        }
    }
}
