// Sources/FMSYSCore/App/MainAppView.swift
import SwiftUI
import SwiftData

public struct MainAppView: View {
    @State private var appState: AppState
    @State private var authViewModel: AuthViewModel
    @State private var selectedScreen: AppScreen = .dashboard
    @State private var journalCategory: JournalCategory = .all
    @State private var showNotificationsPopover = false
    @State private var showSharePopover = false
    @State private var showSettingsPopover = false
    @State private var showAvatarPopover = false
    @State private var showSidebar = false
    @AppStorage("isDarkMode") private var isDarkMode = true

    private let authService: any AuthServiceProtocol
    private let modelContainer: ModelContainer

    public init(
        appState: AppState,
        authService: any AuthServiceProtocol,
        modelContainer: ModelContainer
    ) {
        self._appState = State(wrappedValue: appState)
        self._authViewModel = State(wrappedValue: AuthViewModel(authService: authService))
        self.authService = authService
        self.modelContainer = modelContainer
    }

    public var body: some View {
        if appState.isAuthenticated {
            appShell
                .preferredColorScheme(isDarkMode ? .dark : .light)
        } else {
            authFlow
        }
    }

    // MARK: - Authenticated shell

    private var appShell: some View {
        ZStack(alignment: .topLeading) {
            // Base: rail spans full height, title bar lives in the right column
            HStack(spacing: 0) {
                SidebarRail(selection: $selectedScreen, onToggle: {
                    withAnimation(.easeInOut(duration: 0.22)) { showSidebar.toggle() }
                })
                .frame(maxHeight: .infinity)

                Divider()

                VStack(spacing: 0) {
                    titleBar
                    screenContent
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    StatusBar()
                }
            }

            // Expanded sidebar — overlays full left side including title bar
            if showSidebar {
                Color.black.opacity(0.25)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.22)) { showSidebar = false }
                    }

                SidebarView(
                    selection: $selectedScreen,
                    journalCategory: $journalCategory,
                    onToggle: {
                        withAnimation(.easeInOut(duration: 0.22)) { showSidebar = false }
                    }
                )
                .frame(maxHeight: .infinity)
                .transition(.move(edge: .leading))
                .onChange(of: selectedScreen) { _, _ in
                    withAnimation(.easeInOut(duration: 0.22)) { showSidebar = false }
                }
            }
        }
        .animation(.easeInOut(duration: 0.22), value: showSidebar)
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
                toolbarIconButton(systemName: "bell", isPresented: $showNotificationsPopover) {
                    NotificationsPopover()
                }
                toolbarIconButton(systemName: "square.and.arrow.up", isPresented: $showSharePopover) {
                    SharePopover()
                }
                toolbarIconButton(systemName: "gearshape", isPresented: $showSettingsPopover) {
                    SettingsPopover()
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
                        displayName: appState.userDisplayName,
                        email: appState.userEmail,
                        role: appState.userRole,
                        onSignOut: {
                            showAvatarPopover = false
                            appState.markLoggedOut()
                        }
                    )
                }
                .padding(.leading, 4)
            }
            .padding(.trailing, 12)
        }
        .frame(height: 48)
        .background(Color(NSColor.windowBackgroundColor))
        .overlay(alignment: .bottom) {
            Divider()
                .overlay(Color.fmsMuted.opacity(0.15))
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
        switch selectedScreen {
        case .dashboard:
            DashboardView(trades: loadTrades())
        case .journal:
            JournalDetailView(
                category: journalCategory,
                modelContainer: modelContainer
            )
        case .backtesting:
            BacktestingView(modelContainer: modelContainer)
        case .strategyLab:
            StrategyLabView(modelContainer: modelContainer)
        case .portfolio:
            PortfolioView()
        }
    }

    private func loadTrades() -> [Trade] {
        let repo = TradeRepository(context: modelContainer.mainContext)
        return (try? repo.findAll(userId: "current-user")) ?? []
    }

    // MARK: - Auth flow


    @ViewBuilder
    private var authFlow: some View {
        NavigationStack {
        LoginView(
            viewModel: authViewModel,
            onAuthenticated: { appState.markAuthenticated() },
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
                    onAuthenticated: { appState.markAuthenticated() }
                )
            }
        }
        }
    }
}

