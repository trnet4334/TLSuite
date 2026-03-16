// Tests/FMSYSAppTests/ImageCompressionServiceTests.swift
import Testing
import AppKit
@testable import FMSYSCore

struct ImageCompressionServiceTests {

    private func makeTestImage(width: Int, height: Int) -> NSImage {
        let size = NSSize(width: width, height: height)
        let image = NSImage(size: size)
        image.lockFocus()
        NSColor.red.setFill()
        NSRect(origin: .zero, size: size).fill()
        image.unlockFocus()
        return image
    }

    @Test func compressProducesNonEmptyData() throws {
        let service = ImageCompressionService()
        let image = makeTestImage(width: 800, height: 600)
        let result = try service.compress(image)
        #expect(!result.imageData.isEmpty)
        #expect(!result.thumbnailData.isEmpty)
    }

    @Test func largeImageIsResizedBelow1920() throws {
        let service = ImageCompressionService()
        let image = makeTestImage(width: 3000, height: 2000)
        let result = try service.compress(image)
        guard let compressed = NSImage(data: result.imageData) else {
            Issue.record("Could not decode compressed image")
            return
        }
        let maxEdge = max(compressed.size.width, compressed.size.height)
        #expect(maxEdge <= ImageCompressionService.maxDimension)
    }

    @Test func thumbnailIsSmallerThanMain() throws {
        let service = ImageCompressionService()
        let image = makeTestImage(width: 800, height: 600)
        let result = try service.compress(image)
        #expect(result.thumbnailData.count < result.imageData.count)
    }
}
