// Tests/FMSYSAppTests/JournalAttachmentTests.swift
import Testing
import Foundation
import SwiftData
@testable import FMSYSCore

@Suite(.serialized)
@MainActor
struct JournalAttachmentTests {

    private func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: JournalAttachment.self, configurations: config)
    }

    @Test func insertAndFetchAttachment() throws {
        let container = try makeContainer()
        let ctx = container.mainContext
        let tradeId = UUID()
        let attachment = JournalAttachment(
            tradeId: tradeId,
            imageData: Data([0xFF, 0xD8, 0xFF]),
            thumbnailData: Data([0x89, 0x50, 0x4E]),
            originalFileName: "screenshot.jpg"
        )
        ctx.insert(attachment)
        try ctx.save()

        let fetched = try ctx.fetch(FetchDescriptor<JournalAttachment>())
        #expect(fetched.count == 1)
        #expect(fetched[0].tradeId == tradeId)
        #expect(fetched[0].originalFileName == "screenshot.jpg")
    }

    @Test func fetchByTradeId() throws {
        let container = try makeContainer()
        let ctx = container.mainContext
        let id1 = UUID()
        let id2 = UUID()
        ctx.insert(JournalAttachment(tradeId: id1, imageData: Data(), thumbnailData: Data(), originalFileName: "a.jpg"))
        ctx.insert(JournalAttachment(tradeId: id2, imageData: Data(), thumbnailData: Data(), originalFileName: "b.jpg"))
        try ctx.save()

        let all = try ctx.fetch(FetchDescriptor<JournalAttachment>())
        let results = all.filter { $0.tradeId == id1 }
        #expect(results.count == 1)
        #expect(results[0].originalFileName == "a.jpg")
    }
}
