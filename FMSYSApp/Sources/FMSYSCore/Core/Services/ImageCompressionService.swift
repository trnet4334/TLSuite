// Sources/FMSYSCore/Core/Services/ImageCompressionService.swift
import AppKit
import Foundation

public struct CompressionResult {
    public let imageData: Data
    public let thumbnailData: Data
}

public struct ImageCompressionService {

    public static let maxDimension: CGFloat = 1920
    public static let jpegQuality: CGFloat  = 0.75
    public static let thumbnailSize: CGFloat = 120

    public init() {}

    public func compress(_ image: NSImage) throws -> CompressionResult {
        let resized   = resize(image, maxEdge: Self.maxDimension)
        let thumbnail = resize(image, maxEdge: Self.thumbnailSize)

        guard
            let imageData     = jpegData(from: resized,   quality: Self.jpegQuality),
            let thumbnailData = jpegData(from: thumbnail, quality: 0.6)
        else {
            throw CompressionError.encodingFailed
        }
        return CompressionResult(imageData: imageData, thumbnailData: thumbnailData)
    }

    // MARK: - Private helpers

    private func resize(_ image: NSImage, maxEdge: CGFloat) -> NSImage {
        let original = image.size
        let scale = min(maxEdge / original.width, maxEdge / original.height, 1.0)
        guard scale < 1.0 else { return image }
        let newSize = NSSize(width: original.width * scale, height: original.height * scale)
        let result = NSImage(size: newSize)
        result.lockFocus()
        image.draw(in: NSRect(origin: .zero, size: newSize),
                   from: NSRect(origin: .zero, size: original),
                   operation: .copy, fraction: 1.0)
        result.unlockFocus()
        return result
    }

    private func jpegData(from image: NSImage, quality: CGFloat) -> Data? {
        guard let tiff   = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff) else { return nil }
        return bitmap.representation(
            using: .jpeg,
            properties: [.compressionFactor: quality]
        )
    }
}

public enum CompressionError: Error {
    case encodingFailed
}
