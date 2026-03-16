import AppKit
import Foundation
import Observation
import SwiftData

@Observable
public final class TradeViewModel {

    public var trades: [Trade] = []
    public var isLoading = false
    public var errorMessage: String?
    public var journalCategory: JournalCategory = .all

    /// Called after any trade mutation (create/update/delete). Used by AppStore to keep TradingDataService in sync.
    public var onTradesChanged: (() -> Void)?

    private let repository: TradeRepository
    private let userId: String

    public init(repository: TradeRepository, userId: String) {
        self.repository = repository
        self.userId = userId
    }

    @MainActor
    public func loadTrades() {
        do {
            trades = try repository.findAll(userId: userId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    public func loadTrades(category: JournalCategory = .all) {
        journalCategory = category
        do {
            trades = try repository.findAll(userId: userId, journalCategory: category)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    public func updateTrade(_ trade: Trade) {
        do {
            try repository.save()
            trades = try repository.findAll(userId: userId, journalCategory: journalCategory)
            onTradesChanged?()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    public func createTrade(
        asset: String,
        assetCategory: AssetCategory,
        direction: Direction,
        entryPrice: Double,
        stopLoss: Double,
        takeProfit: Double,
        positionSize: Double
    ) {
        let trade = Trade(
            userId: userId,
            asset: asset,
            assetCategory: assetCategory,
            direction: direction,
            entryPrice: entryPrice,
            stopLoss: stopLoss,
            takeProfit: takeProfit,
            positionSize: positionSize,
            entryAt: Date()
        )
        do {
            try repository.create(trade)
            trades = try repository.findAll(userId: userId)
            onTradesChanged?()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    public func createTrade(
        asset: String,
        journalCategory: JournalCategory,
        direction: Direction,
        entryPrice: Double,
        exitPrice: Double?,
        positionSize: Double,
        notes: String?,
        pipValue: Double?,
        lotSize: Double?,
        exposure: Double?,
        leverage: Double?,
        fundingRate: Double?,
        walletAddress: String?,
        strikePrice: Double?,
        expirationDate: Date?,
        costBasis: Double?
    ) {
        let trade = Trade(
            userId: userId,
            asset: asset,
            assetCategory: journalCategory.assetCategory,
            direction: direction,
            entryPrice: entryPrice,
            stopLoss: 0,
            takeProfit: 0,
            positionSize: positionSize,
            entryAt: Date(),
            exitPrice: exitPrice,
            notes: notes?.isEmpty == true ? nil : notes,
            journalCategory: journalCategory,
            leverage: leverage,
            fundingRate: fundingRate,
            walletAddress: walletAddress?.isEmpty == true ? nil : walletAddress,
            pipValue: pipValue,
            lotSize: lotSize,
            exposure: exposure,
            strikePrice: strikePrice,
            expirationDate: expirationDate,
            costBasis: costBasis
        )
        do {
            try repository.create(trade)
            trades = try repository.findAll(userId: userId, journalCategory: self.journalCategory)
            onTradesChanged?()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    public func deleteTrade(_ trade: Trade) {
        do {
            try repository.delete(trade)
            trades = try repository.findAll(userId: userId)
            onTradesChanged?()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Attachments

    public var attachments: [JournalAttachment] = []

    @MainActor
    public func loadAttachments(for tradeId: UUID) {
        let all = (try? repository.context.fetch(FetchDescriptor<JournalAttachment>())) ?? []
        attachments = all.filter { $0.tradeId == tradeId }
    }

    @MainActor
    public func addAttachment(image: NSImage, tradeId: UUID) {
        do {
            let service = ImageCompressionService()
            let result = try service.compress(image)
            let attachment = JournalAttachment(
                tradeId: tradeId,
                imageData: result.imageData,
                thumbnailData: result.thumbnailData,
                originalFileName: "attachment-\(Int(Date().timeIntervalSince1970)).jpg"
            )
            repository.context.insert(attachment)
            try repository.context.save()
            loadAttachments(for: tradeId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    public func deleteAttachment(_ attachment: JournalAttachment) {
        guard let tradeId = attachments.first(where: { $0.id == attachment.id })?.tradeId else { return }
        repository.context.delete(attachment)
        try? repository.context.save()
        loadAttachments(for: tradeId)
    }

    // MARK: - Bulk Import

    @MainActor
    public func importTrades(_ newTrades: [Trade]) {
        do {
            for trade in newTrades {
                try repository.create(trade)
            }
            trades = try repository.findAll(userId: userId)
            onTradesChanged?()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
