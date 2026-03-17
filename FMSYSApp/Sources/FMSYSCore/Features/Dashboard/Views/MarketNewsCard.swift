// Sources/FMSYSCore/Features/Dashboard/Views/MarketNewsCard.swift
import SwiftUI

public struct MarketNewsCard: View {

    @State private var service = MarketNewsService()
    @State private var isSpinning = false

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            if service.isLoading && service.articles.isEmpty {
                loadingState
            } else if service.filteredArticles.isEmpty {
                emptyState
            } else {
                articleList
            }
        }
        .background(Color.fmsSurface, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.fmsMuted.opacity(0.1), lineWidth: 1))
        .task { await service.refresh() }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Market News", systemImage: "newspaper")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.fmsOnSurface)
                Spacer()
                Button {
                    Task {
                        withAnimation(.linear(duration: 0.6).repeatCount(1, autoreverses: false)) {
                            isSpinning = true
                        }
                        await service.refresh()
                        isSpinning = false
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 13))
                        .foregroundStyle(service.isLoading ? Color.fmsPrimary : Color.fmsMuted)
                        .rotationEffect(.degrees(isSpinning ? 360 : 0))
                }
                .buttonStyle(.plain)
                .disabled(service.isLoading)
            }

            categoryTabs
        }
        .padding(20)
        .overlay(alignment: .bottom) {
            Divider().overlay(Color.fmsMuted.opacity(0.08))
        }
    }

    private var categoryTabs: some View {
        HStack(spacing: 6) {
            ForEach(NewsCategory.allCases, id: \.self) { cat in
                Button { service.selectedCategory = cat } label: {
                    Text(cat.rawValue)
                        .font(.system(size: 11, weight: service.selectedCategory == cat ? .bold : .medium))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            service.selectedCategory == cat
                                ? Color.fmsPrimary.opacity(0.15) : Color.clear,
                            in: Capsule()
                        )
                        .foregroundStyle(
                            service.selectedCategory == cat ? Color.fmsPrimary : Color.fmsMuted
                        )
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
    }

    // MARK: - Article List

    private var articleList: some View {
        LazyVStack(spacing: 0) {
            ForEach(service.filteredArticles.prefix(20)) { article in
                articleRow(article)
                if article.id != service.filteredArticles.prefix(20).last?.id {
                    Divider().overlay(Color.fmsMuted.opacity(0.06)).padding(.leading, 64)
                }
            }
        }
    }

    private func articleRow(_ article: NewsArticle) -> some View {
        Link(destination: article.url) {
            HStack(alignment: .top, spacing: 12) {
                // Source badge
                sourceBadge(article)

                VStack(alignment: .leading, spacing: 4) {
                    Text(article.title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.fmsOnSurface)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    if let summary = article.summary {
                        Text(summary)
                            .font(.system(size: 11))
                            .foregroundStyle(Color.fmsMuted)
                            .lineLimit(2)
                    }

                    HStack(spacing: 6) {
                        Text(article.source)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(categoryColor(article.category))
                        Text("·")
                            .foregroundStyle(Color.fmsMuted.opacity(0.5))
                        Text(timeAgo(article.publishedAt))
                            .font(.system(size: 10))
                            .foregroundStyle(Color.fmsMuted)
                    }
                }

                Spacer()

                Image(systemName: "arrow.up.right")
                    .font(.system(size: 10))
                    .foregroundStyle(Color.fmsMuted.opacity(0.4))
                    .padding(.top, 2)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func sourceBadge(_ article: NewsArticle) -> some View {
        let color = categoryColor(article.category)
        return Text(String(article.source.prefix(3)).uppercased())
            .font(.system(size: 8, weight: .black))
            .foregroundStyle(color)
            .frame(width: 36, height: 36)
            .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Loading / Empty States

    private var loadingState: some View {
        HStack(spacing: 10) {
            ProgressView().scaleEffect(0.7)
            Text("Fetching latest news…")
                .font(.system(size: 12))
                .foregroundStyle(Color.fmsMuted)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 100)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "newspaper")
                .font(.system(size: 28))
                .foregroundStyle(Color.fmsMuted.opacity(0.25))
            Text("No news available")
                .font(.system(size: 12))
                .foregroundStyle(Color.fmsMuted)
            Button("Retry") { Task { await service.refresh() } }
                .buttonStyle(.plain)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.fmsPrimary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 100)
    }

    // MARK: - Helpers

    private func categoryColor(_ category: NewsCategory) -> Color {
        switch category {
        case .all, .general: return Color.fmsPrimary
        case .stocks:        return Color(red: 0.231, green: 0.510, blue: 0.965)
        case .forex:         return Color(red: 0.663, green: 0.329, blue: 1.0)
        case .crypto:        return Color(red: 1.0,   green: 0.584, blue: 0.0)
        }
    }

    private func timeAgo(_ date: Date) -> String {
        let s = Int(-date.timeIntervalSinceNow)
        if s < 60    { return "Just now" }
        if s < 3600  { return "\(s / 60)m ago" }
        if s < 86400 { return "\(s / 3600)h ago" }
        return "\(s / 86400)d ago"
    }
}
