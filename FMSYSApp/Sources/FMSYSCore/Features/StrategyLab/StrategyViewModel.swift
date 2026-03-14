// Sources/FMSYSCore/Features/StrategyLab/StrategyViewModel.swift
import Foundation
import Observation
import SwiftData

@Observable
public final class StrategyViewModel {
    public var strategies: [Strategy] = []
    public var selectedStrategy: Strategy?
    public var errorMessage: String?

    private let repository: StrategyRepository
    private let userId: String
    private let defaults: UserDefaults

    private static let seededKey = "fmsys.strategySeeded"

    public init(
        repository: StrategyRepository,
        userId: String = "current-user",
        defaults: UserDefaults = .standard
    ) {
        self.repository = repository
        self.userId = userId
        self.defaults = defaults
    }

    @MainActor
    public func load() {
        seedIfNeeded()
        do {
            strategies = try repository.findAll(userId: userId)
            if selectedStrategy == nil {
                selectedStrategy = strategies.first
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    public func add() {
        let s = Strategy(userId: userId, name: "New Strategy", indicatorTag: "")
        do {
            try repository.create(s)
            strategies = try repository.findAll(userId: userId)
            selectedStrategy = s
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    public func update(_ strategy: Strategy) {
        strategy.updatedAt = Date()
        do {
            try repository.save()
            strategies = try repository.findAll(userId: userId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    public func delete(id: UUID) {
        guard let s = strategies.first(where: { $0.id == id }) else { return }
        do {
            if selectedStrategy?.id == id { selectedStrategy = nil }
            try repository.delete(s)
            strategies = try repository.findAll(userId: userId)
            if selectedStrategy == nil { selectedStrategy = strategies.first }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Seed

    private func seedIfNeeded() {
        guard !defaults.bool(forKey: Self.seededKey) else { return }
        guard (try? repository.findAll(userId: userId))?.isEmpty == true else {
            defaults.set(true, forKey: Self.seededKey)
            return
        }
        let logic = "func onBarUpdate() {\n    // Check EMA Cross\n    if ema9.crossAbove(ema21) {\n        if rsi.value > 50 {\n            enterLong(\"L1\")\n        }\n    }\n}"
        let seed: [(String, String, StrategyStatus, Double?, Double?)] = [
            ("Trend Follower Pro",  "EMA Cross + RSI",      .active,   0.642, 2.14),
            ("Mean Reversion V2",   "Bollinger Band Scalp",  .paused,   0.588, 1.45),
            ("Volatility Breakout", "ATR Expansion",         .drafting, nil,   nil),
        ]
        for (name, tag, status, wr, pf) in seed {
            let s = Strategy(
                userId: userId,
                name: name,
                indicatorTag: tag,
                status: status,
                logicCode: status == .active ? logic : "",
                riskMgmtEnabled: status == .active,
                winRate: wr,
                profitFactor: pf
            )
            try? repository.create(s)
        }
        defaults.set(true, forKey: Self.seededKey)
    }
}
