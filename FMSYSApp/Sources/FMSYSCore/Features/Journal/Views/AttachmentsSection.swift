// Sources/FMSYSCore/Features/Journal/Views/AttachmentsSection.swift
import SwiftUI
import AppKit

public struct AttachmentsSection: View {
    @Environment(LanguageManager.self) private var lang
    let attachments: [JournalAttachment]
    let onAdd: () -> Void
    let onDelete: (JournalAttachment) -> Void

    @State private var selectedAttachment: JournalAttachment?
    @State private var showingFullImage = false

    public init(
        attachments: [JournalAttachment],
        onAdd: @escaping () -> Void,
        onDelete: @escaping (JournalAttachment) -> Void
    ) {
        self.attachments = attachments
        self.onAdd = onAdd
        self.onDelete = onDelete
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Section header
            HStack {
                Label(String(localized: "journal.attachments.title", bundle: lang.bundle), systemImage: "photo.on.rectangle")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.fmsOnSurface)
                Spacer()
                Button {
                    onAdd()
                } label: {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.fmsPrimary)
                }
                .buttonStyle(.plain)
                .help(String(localized: "journal.attachments.add_help", bundle: lang.bundle))
            }

            if attachments.isEmpty {
                // Drop zone / empty state
                VStack(spacing: 8) {
                    Image(systemName: "plus.viewfinder")
                        .font(.system(size: 28))
                        .foregroundStyle(Color.fmsMuted)
                    Text("journal.attachments.drop_hint", bundle: lang.bundle)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.fmsMuted)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 100)
                .background(Color.fmsSurface, in: RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [6]))
                        .foregroundStyle(Color.fmsMuted.opacity(0.35))
                )
                .onTapGesture { onAdd() }
            } else {
                // Thumbnail grid
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(attachments) { attachment in
                            thumbnailView(for: attachment)
                        }
                        // Add more button
                        Button { onAdd() } label: {
                            VStack(spacing: 6) {
                                Image(systemName: "plus")
                                    .font(.system(size: 20))
                                    .foregroundStyle(Color.fmsMuted)
                            }
                            .frame(width: 88, height: 88)
                            .background(Color.fmsSurface, in: RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [5]))
                                    .foregroundStyle(Color.fmsMuted.opacity(0.35))
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .sheet(isPresented: $showingFullImage) {
            if let attachment = selectedAttachment,
               let image = NSImage(data: attachment.imageData) {
                FullImageView(image: image, fileName: attachment.originalFileName) {
                    showingFullImage = false
                }
                .environment(LanguageManager.shared)
            }
        }
    }

    private func thumbnailView(for attachment: JournalAttachment) -> some View {
        ZStack(alignment: .topTrailing) {
            Group {
                if let img = NSImage(data: attachment.thumbnailData) {
                    Image(nsImage: img)
                        .resizable()
                        .scaledToFill()
                } else {
                    Color.fmsSurface
                }
            }
            .frame(width: 88, height: 88)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .onTapGesture {
                selectedAttachment = attachment
                showingFullImage = true
            }

            // Delete button
            Button {
                onDelete(attachment)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.fmsLoss)
                    .background(Color.fmsBackground, in: Circle())
            }
            .buttonStyle(.plain)
            .offset(x: 6, y: -6)
        }
    }
}

// MARK: - Full image lightbox

private struct FullImageView: View {
    @Environment(LanguageManager.self) private var lang
    let image: NSImage
    let fileName: String
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(fileName)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.fmsOnSurface)
                Spacer()
                Button(String(localized: "common.close", bundle: lang.bundle), action: onDismiss)
                    .buttonStyle(.plain)
                    .foregroundStyle(Color.fmsMuted)
            }
            .padding(16)
            Divider().overlay(Color.fmsBorder)
            Image(nsImage: image)
                .resizable()
                .scaledToFit()
                .padding(16)
        }
        .frame(minWidth: 600, minHeight: 400)
        .background(Color.fmsBackground)
    }
}
