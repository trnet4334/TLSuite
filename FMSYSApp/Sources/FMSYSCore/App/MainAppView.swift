// Sources/FMSYSCore/App/MainAppView.swift
import SwiftUI

public struct MainAppView: View {
    @State private var store: AppStore
    @State private var authViewModel: AuthViewModel
    @State private var showNotificationsPopover = false
    @State private var showSharePopover = false
    @State private var showAvatarPopover = false
    @AppStorage("isDarkMode") private var isDarkMode = true

    private let authService: any AuthServiceProtocol

    public init(
        store: AppStore,
        authService: any AuthServiceProtocol
    ) {
        self._store = State(wrappedValue: store)
        self._authViewModel = State(wrappedValue: AuthViewModel(authService: authService))
        self.authService = authService
    }

    public var body: some View {
        if store.isAuthenticated {
            appShell
                .preferredColorScheme(isDarkMode ? .dark : .light)
                .environment(store)
        } else {
            authFlow
        }
    }

    // MARK: - Authenticated shell

    private var appShell: some View {
        VStack(spacing: 0) {
            titleBar

            HStack(spacing: 0) {
                SidebarView(
                    selection: $store.selectedScreen,
                    journalCategory: $store.journalCategory
                )

                Divider()

                screenContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(maxHeight: .infinity)

            StatusBar()
        }
    }

    // MARK: - Title bar

    private var titleBar: some View {
        HStack(spacing: 0) {
            // Space for macOS window traffic lights
            Spacer().frame(width: 80)

            Spacer()

            // Centered search stub
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.fmsMuted.opacity(0.6))
                Text("Search trades, journals, analytics...")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.fmsMuted.opacity(0.6))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .frame(width: 320)
            .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.fmsMuted.opacity(0.1), lineWidth: 1)
            )

            Spacer()

            // Right controls
            HStack(spacing: 4) {
                // Bell with unread badge
                Button {
                    showNotificationsPopover.toggle()
                } label: {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "bell")
                            .font(.system(size: 15))
                            .foregroundStyle(Color.fmsMuted)
                            .frame(width: 32, height: 32)
                            .contentShape(Rectangle())
                        if store.notificationUnreadCount > 0 {
                            Circle()
                                .fill(Color.fmsPrimary)
                                .frame(width: 7, height: 7)
                                .offset(x: 2, y: -2)
                        }
                    }
                }
                .buttonStyle(.plain)
                .popover(isPresented: $showNotificationsPopover, arrowEdge: .top) {
                    NotificationsPopover(unreadCount: $store.notificationUnreadCount)
                }

                toolbarIconButton(systemName: "square.and.arrow.up", isPresented: $showSharePopover) {
                    SharePopover()
                }

                // Avatar
                Button {
                    showAvatarPopover.toggle()
                } label: {
                    Circle()
                        .fill(Color.fmsMuted.opacity(0.3))
                        .frame(width: 32, height: 32)
                        .overlay {
                            Image(systemName: "person.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(Color.fmsMuted)
                        }
                }
                .buttonStyle(.plain)
                .popover(isPresented: $showAvatarPopover, arrowEdge: .top) {
                    AvatarPopover(
                        displayName: store.userDisplayName,
                        email: store.userEmail,
                        role: store.userRole,
                        onSignOut: {
                            showAvatarPopover = false
                            store.markLoggedOut()
                        }
                    )
                }
                .padding(.leading, 4)
            }
            .padding(.trailing, 12)
        }
        .frame(height: 48)
        .background(.thickMaterial)
        .overlay(alignment: .bottom) {
            Divider()
                .overlay(Color.fmsBorder)
        }
    }

    @ViewBuilder
    private func toolbarIconButton<Content: View>(
        systemName: String,
        isPresented: Binding<Bool>,
        @ViewBuilder popoverContent: @escaping () -> Content
    ) -> some View {
        Button {
            isPresented.wrappedValue.toggle()
        } label: {
            Image(systemName: systemName)
                .font(.system(size: 15))
                .foregroundStyle(Color.fmsMuted)
                .frame(width: 32, height: 32)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .popover(isPresented: isPresented, arrowEdge: .top) {
            popoverContent()
        }
    }

    @ViewBuilder
    private var screenContent: some View {
        switch store.selectedScreen {
        case .dashboard:
            DashboardView(viewModel: store.dashboard)
        case .journal:
            JournalDetailView(viewModel: store.journal, category: store.journalCategory)
        case .backtesting:
            BacktestingView(viewModel: store.backtest)
        case .strategyLab:
            StrategyLabView(viewModel: store.strategyLab)
        case .portfolio:
            PortfolioView(viewModel: store.portfolio)
        }
    }

    // MARK: - Auth flow

    @ViewBuilder
    private var authFlow: some View {
        NavigationStack {
            LoginView(
                viewModel: authViewModel,
                onAuthenticated: { store.markAuthenticated() },
                onMFARequired: { _, _ in }
            )
            .navigationDestination(
                isPresented: Binding(
                    get: {
                        if case .mfaRequired = authViewModel.state { return true }
                        return false
                    },
                    set: { if !$0 { authViewModel.state = .idle } }
                )
            ) {
                if case .mfaRequired(let token, let userId) = authViewModel.state {
                    MFAVerificationView(
                        viewModel: MFAViewModel(
                            authService: authService,
                            sessionToken: token,
                            userId: userId
                        ),
                        onAuthenticated: { store.markAuthenticated() }
                    )
                }
            }
        }
    }
}
