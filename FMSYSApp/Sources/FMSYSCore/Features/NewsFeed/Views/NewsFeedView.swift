// Sources/FMSYSCore/Features/NewsFeed/Views/NewsFeedView.swift
import SwiftUI

public struct NewsFeedView: View {

    @State private var service = MarketNewsService()
    @State private var isSpinning = false

    public init() {}

    public var body: some View {
        HStack(spacing: 0) {
            feedColumn
            Divider()
            NewsFeedRightPanel(articles: service.articles)
        }
        .background(Color.fmsBackground)
        .task { await service.refresh() }
    }

    // MARK: - Left feed column

    private var feedColumn: some View {
        VStack(spacing: 0) {
            filterBar
            Divider().overlay(Color.fmsMuted.opacity(0.08))

            if service.isLoading && service.articles.isEmpty {
                loadingState
            } else if service.filteredArticles.isEmpty {
                emptyState
            } else {
                articleFeed
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Filter bar

    private var filterBar: some View {
        HStack(spacing: 6) {
            ForEach(NewsCategory.allCases, id: \.self) { cat in
                Button { service.selectedCategory = cat } label: {
                    Text(cat.rawValue)
                        .font(.system(size: 12, weight: service.selectedCategory == cat ? .bold : .semibold))
                        .padding(.horizontal, 13)
                        .padding(.vertical, 5)
                        .background(
                            service.selectedCategory == cat
                                ? Color.fmsPrimary.opacity(0.14)
                                : Color.clear,
                            in: Capsule()
                        )
                        .overlay(
                            Capsule().stroke(
                                service.selectedCategory == cat
                                    ? Color.fmsPrimary.opacity(0.3)
                                    : Color.fmsMuted.opacity(0.15)
                            )
                        )
                        .foregroundStyle(
                            service.selectedCategory == cat ? Color.fmsPrimary : Color.fmsMuted
                        )
                }
                .buttonStyle(.plain)
            }

            Spacer()

            // Refresh button
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
                    .font(.system(size: 12))
                    .foregroundStyle(service.isLoading ? Color.fmsPrimary : Color.fmsMuted)
                    .rotationEffect(.degrees(isSpinning ? 360 : 0))
            }
            .buttonStyle(.plain)
            .disabled(service.isLoading)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    // MARK: - Article feed

    private var articleFeed: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 0) {
                let articles = service.filteredArticles.prefix(30)
                // Featured card — first article
                if let featured = articles.first {
                    featuredCard(featured)
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 12)
                }

                // Section divider
                if articles.count > 1 {
                    HStack {
                        Text("Latest Stories")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Color.fmsMuted)
                            .textCase(.uppercase)
                            .tracking(1)
                        Rectangle()
                            .fill(Color.fmsMuted.opacity(0.1))
                            .frame(height: 1)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)

                    // Remaining articles
                    ForEach(articles.dropFirst()) { article in
                        articleRow(article)
                        if article.id != articles.last?.id {
                            Divider()
                                .overlay(Color.fmsMuted.opacity(0.06))
                                .padding(.leading, 76)
                        }
                    }
                    .padding(.bottom, 20)
                }
            }
        }
    }

    // MARK: - Featured card

    private func featuredCard(_ article: NewsArticle) -> some View {
        Link(destination: article.url) {
            VStack(alignment: .leading, spacing: 0) {
                // Coloured accent bar + meta row
                HStack(spacing: 0) {
                    Rectangle()
                        .fill(categoryColor(article.category))
                        .frame(width: 3)

                    VStack(alignment: .leading, spacing: 10) {
                        // Source + sentiment
                        HStack(spacing: 8) {
                            sourceBadge(article, size: 24)
                            Text(article.source)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(Color.fmsMuted)
                                .textCase(.uppercase)
                                .tracking(0.7)
                            Text("·")
                                .foregroundStyle(Color.fmsMuted.opacity(0.4))
                            Text(timeAgo(article.publishedAt))
                                .font(.system(size: 10))
                                .foregroundStyle(Color.fmsMuted)
                            Spacer()
                            sentimentChip(article.category)
                        }

                        // Headline
                        Text(article.title)
                            .font(.system(size: 17, weight: .heavy))
                            .foregroundStyle(Color.fmsOnSurface)
                            .lineLimit(3)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineSpacing(2)

                        // Summary
                        if let summary = article.summary {
                            Text(summary)
                                .font(.system(size: 12.5))
                                .foregroundStyle(Color.fmsMuted)
                                .lineLimit(3)
                                .fixedSize(horizontal: false, vertical: true)
                                .lineSpacing(2)
                        }

                        // Footer
                        HStack {
                            tagView(article.category)
                            Spacer()
                            HStack(spacing: 4) {
                                Text("Read full story")
                                    .font(.system(size: 11, weight: .bold))
                                Image(systemName: "arrow.up.right")
                                    .font(.system(size: 10))
                            }
                            .foregroundStyle(Color.fmsPrimary)
                        }
                    }
                    .padding(16)
                }
            }
            .background(Color.fmsSurface, in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.fmsMuted.opacity(0.1), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Article row

    private func articleRow(_ article: NewsArticle) -> some View {
        Link(destination: article.url) {
            HStack(alignment: .top, spacing: 12) {
                sourceBadge(article, size: 40)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(article.source)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Color.fmsMuted)
                            .textCase(.uppercase)
                            .tracking(0.5)
                        Text("·")
                            .foregroundStyle(Color.fmsMuted.opacity(0.4))
                            .font(.system(size: 10))
                        Text(timeAgo(article.publishedAt))
                            .font(.system(size: 10))
                            .foregroundStyle(Color.fmsMuted)
                        Spacer()
                        sentimentChip(article.category)
                    }

                    Text(article.title)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color.fmsOnSurface)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    if let summary = article.summary {
                        Text(summary)
                            .font(.system(size: 11.5))
                            .foregroundStyle(Color.fmsMuted)
                            .lineLimit(2)
                    }

                    tagView(article.category)
                }

                Image(systemName: "arrow.up.right")
                    .font(.system(size: 10))
                    .foregroundStyle(Color.fmsMuted.opacity(0.35))
                    .padding(.top, 3)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 13)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Loading / Empty

    private var loadingState: some View {
        VStack(spacing: 10) {
            ProgressView().scaleEffect(0.8)
            Text("Fetching latest news…")
                .font(.system(size: 12))
                .foregroundStyle(Color.fmsMuted)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "newspaper")
                .font(.system(size: 32))
                .foregroundStyle(Color.fmsMuted.opacity(0.2))
            Text("No articles available")
                .font(.system(size: 13))
                .foregroundStyle(Color.fmsMuted)
            Button("Retry") { Task { await service.refresh() } }
                .buttonStyle(.plain)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.fmsPrimary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Sub-components

    private func sourceBadge(_ article: NewsArticle, size: CGFloat) -> some View {
        let color = categoryColor(article.category)
        return Text(String(article.source.prefix(3)).uppercased())
            .font(.system(size: size * 0.22, weight: .black))
            .foregroundStyle(color)
            .frame(width: size, height: size)
            .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: size * 0.22))
    }

    private func sentimentChip(_ category: NewsCategory) -> some View {
        let (label, color): (String, Color) = switch category {
        case .stocks:  ("Stocks", Color(red: 0.231, green: 0.510, blue: 0.965))
        case .forex:   ("Forex",  Color(red: 0.663, green: 0.329, blue: 1.0))
        case .crypto:  ("Crypto", Color(red: 1.0,   green: 0.584, blue: 0.0))
        default:       ("General", Color.fmsPrimary)
        }
        return Text(label)
            .font(.system(size: 9, weight: .bold))
            .foregroundStyle(color)
            .padding(.horizontal, 7)
            .padding(.vertical, 2)
            .background(color.opacity(0.12), in: Capsule())
    }

    private func tagView(_ category: NewsCategory) -> some View {
        let label: String = switch category {
        case .stocks:  "#Stocks"
        case .forex:   "#Forex"
        case .crypto:  "#Crypto"
        case .general: "#General"
        case .all:     "#Markets"
        }
        return Text(label)
            .font(.system(size: 9.5, weight: .bold))
            .foregroundStyle(Color.fmsMuted)
            .padding(.horizontal, 7)
            .padding(.vertical, 2)
            .background(Color.fmsMuted.opacity(0.08), in: RoundedRectangle(cornerRadius: 4))
    }

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
