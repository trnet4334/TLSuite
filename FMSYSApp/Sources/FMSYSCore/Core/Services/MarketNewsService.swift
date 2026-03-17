// Sources/FMSYSCore/Core/Services/MarketNewsService.swift
import Foundation
import Observation

// MARK: - Service

@MainActor
@Observable
public final class MarketNewsService {

    public private(set) var articles: [NewsArticle] = []
    public private(set) var isLoading = false
    public private(set) var lastError: String?
    public var selectedCategory: NewsCategory = .all

    private struct FeedConfig: Sendable {
        let url: URL
        let category: NewsCategory
        let sourceName: String
    }

    private let feeds: [FeedConfig] = [
        .init(url: URL(string: "https://feeds.reuters.com/reuters/businessNews")!,
              category: .general, sourceName: "Reuters"),
        .init(url: URL(string: "https://feeds.marketwatch.com/marketwatch/topstories")!,
              category: .stocks, sourceName: "MarketWatch"),
        .init(url: URL(string: "https://www.forexlive.com/feed/news")!,
              category: .forex, sourceName: "ForexLive"),
        .init(url: URL(string: "https://cointelegraph.com/rss")!,
              category: .crypto, sourceName: "CoinTelegraph"),
    ]

    public var filteredArticles: [NewsArticle] {
        selectedCategory == .all ? articles : articles.filter { $0.category == selectedCategory }
    }

    // MARK: - Fetch

    public func refresh() async {
        isLoading = true
        lastError = nil
        let feeds = self.feeds
        var all: [NewsArticle] = []

        await withTaskGroup(of: [NewsArticle].self) { group in
            for feed in feeds {
                group.addTask { await Self.fetchFeed(feed) }
            }
            for await batch in group {
                all.append(contentsOf: batch)
            }
        }

        articles = all
            .filter { !$0.title.isEmpty }
            .sorted { $0.publishedAt > $1.publishedAt }
        isLoading = false
    }

    private static func fetchFeed(_ feed: FeedConfig) async -> [NewsArticle] {
        guard let (data, _) = try? await URLSession.shared.data(from: feed.url) else { return [] }
        return RSSParser.parse(data: data, category: feed.category, sourceName: feed.sourceName)
    }
}

// MARK: - RSS Parser

private final class RSSParser: NSObject, XMLParserDelegate, @unchecked Sendable {

    private var articles: [NewsArticle] = []
    private var inItem = false
    private var currentElement = ""
    private var currentText = ""
    private var itemTitle = ""
    private var itemLink = ""
    private var itemDescription = ""
    private var itemPubDate = ""
    private let category: NewsCategory
    private let sourceName: String

    private static let rfc822Formatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
        return f
    }()

    private static let iso8601Formatter = ISO8601DateFormatter()

    init(category: NewsCategory, sourceName: String) {
        self.category = category
        self.sourceName = sourceName
    }

    static func parse(data: Data, category: NewsCategory, sourceName: String) -> [NewsArticle] {
        let handler = RSSParser(category: category, sourceName: sourceName)
        let parser = XMLParser(data: data)
        parser.delegate = handler
        parser.parse()
        return handler.articles
    }

    // MARK: XMLParserDelegate

    func parser(_ parser: XMLParser, didStartElement name: String,
                namespaceURI: String?, qualifiedName: String?,
                attributes: [String: String] = [:]) {
        currentElement = name
        currentText = ""
        if name == "item" || name == "entry" {
            inItem = true
            itemTitle = ""; itemLink = ""; itemDescription = ""; itemPubDate = ""
        }
        // Atom <link href="…"> — grab from attribute
        if inItem, name == "link", let href = attributes["href"], itemLink.isEmpty {
            itemLink = href
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentText += string
    }

    func parser(_ parser: XMLParser, didEndElement name: String,
                namespaceURI: String?, qualifiedName: String?) {
        guard inItem else { return }
        let text = currentText.trimmingCharacters(in: .whitespacesAndNewlines)

        switch name {
        case "title":
            itemTitle = text
        case "link":
            if itemLink.isEmpty { itemLink = text }
        case "description", "summary", "content:encoded":
            if itemDescription.isEmpty { itemDescription = Self.stripHTML(text) }
        case "pubDate", "published", "updated", "dc:date":
            if itemPubDate.isEmpty { itemPubDate = text }
        case "item", "entry":
            guard !itemTitle.isEmpty, let url = URL(string: itemLink) else {
                inItem = false; return
            }
            let summary = itemDescription.isEmpty ? nil
                : String(itemDescription.prefix(200))
            articles.append(NewsArticle(
                id: itemLink,
                title: itemTitle,
                source: sourceName,
                summary: summary,
                url: url,
                publishedAt: Self.parseDate(itemPubDate),
                category: category
            ))
            inItem = false
        default:
            break
        }
    }

    // MARK: Helpers

    private static func parseDate(_ string: String) -> Date {
        if let d = rfc822Formatter.date(from: string) { return d }
        if let d = iso8601Formatter.date(from: string) { return d }
        return Date()
    }

    private static func stripHTML(_ html: String) -> String {
        html.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&#[0-9]+;", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
