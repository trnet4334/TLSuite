import Foundation
import SwiftData

// MARK: - Supporting enums

public enum AssetCategory: String, Codable {
    case forex, crypto, stocks, futures, options, commodities
}

public enum Direction: String, Codable {
    case long, short
}

// MARK: - Trade

@Model
public final class Trade {

    public var id: UUID
    public var userId: String

    // Asset
    public var asset: String
    public var assetCategoryRaw: String

    // Position
    public var directionRaw: String
    public var entryPrice: Double
    public var exitPrice: Double?
    public var stopLoss: Double
    public var takeProfit: Double
    public var positionSize: Double

    // Timing
    public var entryAt: Date
    public var exitAt: Date?
    public var entryTime: Date?
    public var exitTime: Date?

    // Metadata
    public var notes: String?
    public var emotionTagRaw: String?
    public var screenshotURL: String?

    // Sync
    public var pendingSync: Bool

    // Journal category
    public var journalCategoryRaw: String

    // Crypto-specific
    public var leverage: Double?
    public var fundingRate: Double?
    public var walletAddress: String?

    // Forex-specific
    public var pipValue: Double?
    public var lotSize: Double?
    public var exposure: Double?
    public var sessionNotes: String?

    // Options-specific
    public var strikePrice: Double?
    public var expirationDate: Date?
    public var costBasis: Double?
    public var greeksDelta: Double?
    public var greeksGamma: Double?
    public var greeksTheta: Double?
    public var greeksVega: Double?

    // MARK: - Computed wrappers

    public var assetCategory: AssetCategory {
        get { AssetCategory(rawValue: assetCategoryRaw) ?? .forex }
        set { assetCategoryRaw = newValue.rawValue }
    }

    public var direction: Direction {
        get { Direction(rawValue: directionRaw) ?? .long }
        set { directionRaw = newValue.rawValue }
    }

    public var emotionTag: EmotionTag? {
        get { emotionTagRaw.flatMap(EmotionTag.init) }
        set { emotionTagRaw = newValue?.rawValue }
    }

    public var journalCategory: JournalCategory {
        get { JournalCategory(rawValue: journalCategoryRaw) ?? .stocksETFs }
        set { journalCategoryRaw = newValue.rawValue }
    }

    // MARK: - Init

    public init(
        id: UUID = UUID(),
        userId: String,
        asset: String,
        assetCategory: AssetCategory,
        direction: Direction,
        entryPrice: Double,
        stopLoss: Double,
        takeProfit: Double,
        positionSize: Double,
        entryAt: Date,
        exitPrice: Double? = nil,
        exitAt: Date? = nil,
        entryTime: Date? = nil,
        exitTime: Date? = nil,
        notes: String? = nil,
        emotionTag: EmotionTag? = nil,
        screenshotURL: String? = nil,
        pendingSync: Bool = true,
        journalCategory: JournalCategory = .stocksETFs,
        leverage: Double? = nil,
        fundingRate: Double? = nil,
        walletAddress: String? = nil,
        pipValue: Double? = nil,
        lotSize: Double? = nil,
        exposure: Double? = nil,
        sessionNotes: String? = nil,
        strikePrice: Double? = nil,
        expirationDate: Date? = nil,
        costBasis: Double? = nil,
        greeksDelta: Double? = nil,
        greeksGamma: Double? = nil,
        greeksTheta: Double? = nil,
        greeksVega: Double? = nil
    ) {
        self.id = id
        self.userId = userId
        self.asset = asset
        self.assetCategoryRaw = assetCategory.rawValue
        self.directionRaw = direction.rawValue
        self.entryPrice = entryPrice
        self.stopLoss = stopLoss
        self.takeProfit = takeProfit
        self.positionSize = positionSize
        self.entryAt = entryAt
        self.exitPrice = exitPrice
        self.exitAt = exitAt
        self.entryTime = entryTime
        self.exitTime = exitTime
        self.notes = notes
        self.emotionTagRaw = emotionTag?.rawValue
        self.screenshotURL = screenshotURL
        self.pendingSync = pendingSync
        self.journalCategoryRaw = journalCategory.rawValue
        self.leverage = leverage
        self.fundingRate = fundingRate
        self.walletAddress = walletAddress
        self.pipValue = pipValue
        self.lotSize = lotSize
        self.exposure = exposure
        self.sessionNotes = sessionNotes
        self.strikePrice = strikePrice
        self.expirationDate = expirationDate
        self.costBasis = costBasis
        self.greeksDelta = greeksDelta
        self.greeksGamma = greeksGamma
        self.greeksTheta = greeksTheta
        self.greeksVega = greeksVega
    }
}
