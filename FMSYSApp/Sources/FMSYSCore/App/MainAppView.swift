// Sources/FMSYSCore/App/MainAppView.swift
import SwiftUI
import SwiftData

public struct MainAppView: View {
    @State private var appState: AppState
    @State private var authViewModel: AuthViewModel
    @State private var selectedScreen: AppScreen = .dashboard
    @State private var journalCategory: JournalCategory = .all

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
        } else {
            authFlow
        }
    }

    // MARK: - Authenticated shell

    private var appShell: some View {
        VStack(spacing: 0) {
            NavigationSplitView {
                SidebarView(selection: $selectedScreen, journalCategory: $journalCategory)
            } detail: {
                screenContent
            }
            .navigationSplitViewStyle(.prominentDetail)
            StatusBar()
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
            BacktestingView()
        case .strategyLab:
            StrategyLabView()
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

