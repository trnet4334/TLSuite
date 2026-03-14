import Foundation
import SwiftData

// MARK: - StrategyStatus

public enum StrategyStatus: String, Codable, CaseIterable {
    case active, paused, drafting, archived
}

// MARK: - Strategy

@Model
public final class Strategy {
    public var id: UUID
    public var userId: String
    public var name: String
    public var indicatorTag: String        // e.g. "EMA Cross + RSI"
    public var statusRaw: String
    public var logicCode: String
    public var emaFastPeriod: Int
    public var emaSlowPeriod: Int
    public var riskMgmtEnabled: Bool
    public var trailingStopEnabled: Bool
    public var winRate: Double?
    public var profitFactor: Double?
    public var createdAt: Date
    public var updatedAt: Date

    public var status: StrategyStatus {
        get { StrategyStatus(rawValue: statusRaw) ?? .drafting }
        set { statusRaw = newValue.rawValue }
    }

    public init(
        id: UUID = UUID(),
        userId: String,
        name: String,
        indicatorTag: String = "",
        status: StrategyStatus = .drafting,
        logicCode: String = "",
        emaFastPeriod: Int = 9,
        emaSlowPeriod: Int = 21,
        riskMgmtEnabled: Bool = false,
        trailingStopEnabled: Bool = false,
        winRate: Double? = nil,
        profitFactor: Double? = nil
    ) {
        self.id = id
        self.userId = userId
        self.name = name
        self.indicatorTag = indicatorTag
        self.statusRaw = status.rawValue
        self.logicCode = logicCode
        self.emaFastPeriod = emaFastPeriod
        self.emaSlowPeriod = emaSlowPeriod
        self.riskMgmtEnabled = riskMgmtEnabled
        self.trailingStopEnabled = trailingStopEnabled
        self.winRate = winRate
        self.profitFactor = profitFactor
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
