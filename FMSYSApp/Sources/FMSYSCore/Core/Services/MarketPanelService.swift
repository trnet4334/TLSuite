// Sources/FMSYSCore/Core/Services/MarketPanelService.swift
import Foundation
import Observation

// MARK: - Models

public struct LiveTicker: Identifiable, Sendable {
    public let id: String
    public let symbol: String
    public let name: String
    public let price: Double
    public let changePercent: Double
    public let sparkline: [Double]  // normalised 0–1

    public var isPositive: Bool { changePercent >= 0 }
}

public struct FearGreedResult: Sendable {
    public let value: Int
    public let classification: String
}

public struct LiveEconEvent: Identifiable, Sendable {
    public enum Impact: String, Sendable { case high, medium, low }
    public let id: String
    public let name: String
    public let currency: String
    public let detail: String       // estimate string, e.g. "Est: 0.4%"
    public let time: String         // formatted local time or "Tomorrow"
    public let impact: Impact
    public let date: Date
}

// MARK: - Service

@MainActor
@Observable
public final class MarketPanelService {

    public private(set) var tickers: [LiveTicker] = []
    public private(set) var fearGreed: FearGreedResult? = nil
    public private(set) var calendarEvents: [LiveEconEvent] = []
    public private(set) var isLoadingTickers = false
    public private(set) var isLoadingSentiment = false
    public private(set) var isLoadingCalendar = false

    private let watchlist: [(yahoo: String, display: String, name: String)] = [
        ("^GSPC",    "SPX",     "S&P 500"),
        ("NVDA",     "NVDA",    "NVIDIA Corp."),
        ("BTC-USD",  "BTC",     "Bitcoin"),
        ("EURUSD=X", "EUR/USD", "Euro / Dollar"),
    ]

    public init() {}

    // MARK: - Public

    public func refresh() async {
        async let t: () = fetchTickers()
        async let s: () = fetchFearGreed()
        async let c: () = fetchCalendar()
        _ = await (t, s, c)
    }

    // MARK: - Tickers (Yahoo Finance)

    private func fetchTickers() async {
        isLoadingTickers = true
        defer { isLoadingTickers = false }

        var results: [LiveTicker] = []
        await withTaskGroup(of: LiveTicker?.self) { group in
            for item in watchlist {
                group.addTask { await Self.fetchQuote(item) }
            }
            for await result in group {
                if let r = result { results.append(r) }
            }
        }
        let order = watchlist.map(\.yahoo)
        tickers = results.sorted { order.firstIndex(of: $0.id) ?? 0 < order.firstIndex(of: $1.id) ?? 0 }
    }

    nonisolated private static func fetchQuote(
        _ item: (yahoo: String, display: String, name: String)
    ) async -> LiveTicker? {
        let encoded = item.yahoo.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? item.yahoo
        let urlString = "https://query2.finance.yahoo.com/v8/finance/chart/\(encoded)?interval=15m&range=1d"
        guard let url = URL(string: urlString) else { return nil }
        var request = URLRequest(url: url, timeoutInterval: 10)
        request.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")
        guard let (data, _) = try? await URLSession.shared.data(for: request) else { return nil }
        return parseYahooChart(data: data, yahoo: item.yahoo, display: item.display, name: item.name)
    }

    nonisolated private static func parseYahooChart(
        data: Data, yahoo: String, display: String, name: String
    ) -> LiveTicker? {
        guard
            let json      = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let chart     = json["chart"] as? [String: Any],
            let results   = chart["result"] as? [[String: Any]],
            let first     = results.first,
            let meta      = first["meta"] as? [String: Any],
            let price     = meta["regularMarketPrice"] as? Double,
            let prevClose = meta["previousClose"] as? Double
        else { return nil }

        let changePercent = prevClose > 0 ? (price - prevClose) / prevClose * 100 : 0

        var closes: [Double] = []
        if let indicators = first["indicators"] as? [String: Any],
           let quoteArr   = indicators["quote"] as? [[String: Any]],
           let quoteFirst = quoteArr.first,
           let rawCloses  = quoteFirst["close"] as? [Any] {
            closes = rawCloses.compactMap {
                if let d = $0 as? Double, !d.isNaN { return d }
                return nil
            }
        }

        return LiveTicker(id: yahoo, symbol: display, name: name,
                          price: price, changePercent: changePercent,
                          sparkline: normalised(closes))
    }

    nonisolated private static func normalised(_ values: [Double]) -> [Double] {
        guard values.count > 1,
              let lo = values.min(), let hi = values.max(), hi > lo else {
            return Array(repeating: 0.5, count: min(max(values.count, 1), 8))
        }
        let step = max(1, values.count / 16)
        let sampled = stride(from: 0, to: values.count, by: step).map { values[$0] }
        return sampled.map { 1.0 - ($0 - lo) / (hi - lo) }
    }

    // MARK: - Fear & Greed (Alternative.me)

    private func fetchFearGreed() async {
        isLoadingSentiment = true
        defer { isLoadingSentiment = false }

        guard
            let url = URL(string: "https://api.alternative.me/fng/?limit=1"),
            let (data, _) = try? await URLSession.shared.data(from: url),
            let json  = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let arr   = json["data"] as? [[String: Any]],
            let first = arr.first,
            let valueStr = first["value"] as? String,
            let value    = Int(valueStr),
            let label    = first["value_classification"] as? String
        else { return }

        fearGreed = FearGreedResult(value: value, classification: label)
    }

    // MARK: - Economic Calendar (ForexFactory)

    private func fetchCalendar() async {
        isLoadingCalendar = true
        defer { isLoadingCalendar = false }

        // Fetch this week + next week in parallel so we always have upcoming events
        async let thisWeek = Self.fetchFFCalendar(week: "thisweek")
        async let nextWeek = Self.fetchFFCalendar(week: "nextweek")
        let all = await thisWeek + nextWeek

        let today = Date()
        let cutoff = Calendar.current.date(byAdding: .day, value: 4, to: today) ?? today

        let upcoming = all
            .filter { $0.date >= today && $0.date <= cutoff && $0.impact != .low }
            .sorted { lhs, rhs in
                if lhs.impactRank != rhs.impactRank { return lhs.impactRank < rhs.impactRank }
                return lhs.date < rhs.date
            }

        calendarEvents = Array(upcoming.prefix(5))
    }

    nonisolated private static func fetchFFCalendar(week: String) async -> [LiveEconEvent] {
        guard
            let url = URL(string: "https://nfs.faireconomy.media/ff_calendar_\(week).json"),
            let (data, _) = try? await URLSession.shared.data(from: url),
            let rawArray  = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]
        else { return [] }

        return rawArray.compactMap { parseFFEvent($0) }
    }

    nonisolated private static func parseFFEvent(_ raw: [String: Any]) -> LiveEconEvent? {
        guard
            let name     = raw["title"]   as? String,
            let currency = raw["country"] as? String,
            let impactStr = raw["impact"] as? String,
            let dateStr  = raw["date"]    as? String
        else { return nil }

        // Skip holidays
        guard impactStr != "Holiday" else { return nil }

        let impactLevel: LiveEconEvent.Impact = switch impactStr {
        case "High":   .high
        case "Medium": .medium
        default:       .low
        }

        // Parse ISO8601 date with timezone offset
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime]
        guard let date = iso.date(from: dateStr) else { return nil }

        let detail: String
        if let forecast = raw["forecast"] as? String, !forecast.isEmpty {
            detail = "Est: \(forecast)"
        } else {
            detail = ""
        }

        let timeLabel = formatFFTime(date)
        let id = "\(name)-\(dateStr)"

        return LiveEconEvent(id: id, name: name, currency: currency,
                             detail: detail, time: timeLabel, impact: impactLevel,
                             date: date)
    }

    nonisolated private static func formatFFTime(_ date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) {
            let fmt = DateFormatter()
            fmt.timeZone = .current
            fmt.dateFormat = "HH:mm"
            return fmt.string(from: date)
        } else if cal.isDateInTomorrow(date) {
            return "Tomorrow"
        } else {
            let fmt = DateFormatter()
            fmt.dateFormat = "MMM d"
            return fmt.string(from: date)
        }
    }
}

// MARK: - Impact sort key

private extension LiveEconEvent {
    var impactRank: Int {
        switch impact {
        case .high:   return 0
        case .medium: return 1
        case .low:    return 2
        }
    }
}

// MARK: - Formatting helpers

public extension LiveTicker {
    var formattedPrice: String {
        if symbol == "BTC" {
            if price >= 1_000 { return String(format: "$%.1fK", price / 1_000) }
            return String(format: "$%.2f", price)
        }
        if symbol == "EUR/USD" { return String(format: "%.4f", price) }
        if price >= 1_000 { return String(format: "%.0f", price) }
        return String(format: "%.2f", price)
    }

    var formattedChange: String {
        String(format: "%+.2f%%", changePercent)
    }
}
