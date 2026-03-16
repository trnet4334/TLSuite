// Sources/FMSYSCore/Core/Models/JournalAttachment.swift
import Foundation
import SwiftData

@Model
public final class JournalAttachment {
    public var id: UUID
    public var tradeId: UUID
    public var imageData: Data
    public var thumbnailData: Data
    public var originalFileName: String
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        tradeId: UUID,
        imageData: Data,
        thumbnailData: Data,
        originalFileName: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.tradeId = tradeId
        self.imageData = imageData
        self.thumbnailData = thumbnailData
        self.originalFileName = originalFileName
        self.createdAt = createdAt
    }
}
