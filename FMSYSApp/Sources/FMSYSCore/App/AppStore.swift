// Sources/FMSYSCore/App/AppStore.swift
import Foundation
import SwiftData
import Observation

/// Single source of truth for the entire application.
/// Consolidates auth state, navigation, UI state, and all feature view models.
@MainActor
@Observable
public final class AppStore {

    // MARK: - Auth

    public var isAuthenticated: Bool
    public var userDisplayName: String = "Trading Desk"
    public var userEmail: String = "trader@fmsys.app"
    public var userRole: String = "Trader"

    // MARK: - Navigation

    public var selectedScreen: AppScreen = .portfolio
    public var journalCategory: JournalCategory = .all

    // MARK: - UI State

    public var notificationUnreadCount: Int = 4

    // MARK: - Feature ViewModels

    public let trading: TradingDataService
    public let dashboard: DashboardViewModel
    public let portfolio: PortfolioViewModel
    public let strategyLab: StrategyViewModel
    public let backtest: BacktestViewModel
    public let journal: TradeViewModel

    // MARK: - Private

    private let keychain: KeychainManager

    // MARK: - Init

    public init(keychain: KeychainManager = KeychainManager(), modelContainer: ModelContainer) {
        self.keychain = keychain
        self.isAuthenticated = (try? keychain.load(forKey: .accessToken)) != nil

        let context = modelContainer.mainContext
        let tradingService = TradingDataService(modelContainer: modelContainer)
        tradingService.loadAll()
        self.trading = tradingService

        let tradeRepo = TradeRepository(context: context)
        let allTrades = tradingService.trades

        self.dashboard = DashboardViewModel(trades: allTrades)
        self.portfolio = PortfolioViewModel(trades: allTrades)
        self.strategyLab = StrategyViewModel(
            repository: StrategyRepository(context: context),
            userId: "current-user"
        )
        self.backtest = BacktestViewModel(context: context)
        self.journal = TradeViewModel(repository: tradeRepo, userId: "current-user")

        // Keep dashboard and portfolio trades in sync when journal mutates
        self.journal.onTradesChanged = { [weak tradingService,
                                          weak dashboard = self.dashboard,
                                          weak portfolio = self.portfolio] in
            tradingService?.loadAll()
            let fresh = tradingService?.trades ?? []
            dashboard?.trades = fresh
            portfolio?.trades = fresh
        }
    }

    // MARK: - Auth actions

    public func markAuthenticated() { isAuthenticated = true }
    public func markLoggedOut() { isAuthenticated = false }
}
