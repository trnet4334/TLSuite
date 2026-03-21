// Sources/FMSYSCore/Features/NewsFeed/Views/NewsFeedRightPanel.swift
import SwiftUI

struct NewsFeedRightPanel: View {

    let articles: [NewsArticle]
    @Environment(LanguageManager.self) private var lang

    // MARK: - Stub ticker data

    private struct TickerItem {
        let symbol: String
        let name: String
        let price: String
        let change: String
        let isPositive: Bool
        let sparkPoints: [CGFloat] // normalised 0–1, top→bottom = low→high
        let color: Color
    }

    private let tickers: [TickerItem] = [
        TickerItem(symbol: "SPX",     name: "S&P 500",       price: "5,628",  change: "+1.46%", isPositive: true,
                   sparkPoints: [0.7, 0.65, 0.6, 0.5, 0.42, 0.35, 0.22, 0.1],
                   color: Color(red: 0.074, green: 0.925, blue: 0.502)),
        TickerItem(symbol: "NVDA",    name: "NVIDIA Corp.",  price: "$924",   change: "+6.20%", isPositive: true,
                   sparkPoints: [0.85, 0.78, 0.7, 0.58, 0.45, 0.3, 0.15, 0.05],
                   color: Color(red: 0.074, green: 0.925, blue: 0.502)),
        TickerItem(symbol: "BTC",     name: "Bitcoin",       price: "$62.4K", change: "−3.40%", isPositive: false,
                   sparkPoints: [0.2, 0.25, 0.22, 0.32, 0.42, 0.52, 0.6, 0.72],
                   color: Color(red: 1.0, green: 0.373, blue: 0.341)),
        TickerItem(symbol: "EUR/USD", name: "Euro / Dollar", price: "1.0918", change: "+0.08%", isPositive: true,
                   sparkPoints: [0.5, 0.48, 0.52, 0.5, 0.46, 0.49, 0.5, 0.47],
                   color: Color(red: 0.231, green: 0.510, blue: 0.965)),
    ]

    // MARK: - Stub calendar events

    private struct EconEvent {
        enum Impact { case high, medium, low }
        let name: String
        let currency: String
        let detail: String
        let time: String
        let impact: Impact
    }

    private let events: [EconEvent] = [
        EconEvent(name: "US CPI (MoM)",         currency: "USD", detail: "Est: 0.1%",        time: "14:30", impact: .high),
        EconEvent(name: "Powell Speech",         currency: "USD", detail: "Jackson Hole",     time: "16:00", impact: .high),
        EconEvent(name: "ECB Meeting Minutes",   currency: "EUR", detail: "Rate guidance",    time: "Tomorrow", impact: .medium),
        EconEvent(name: "UK Retail Sales (MoM)", currency: "GBP", detail: "Est: 0.4%",       time: "Tomorrow", impact: .low),
    ]

    // MARK: - Source counts

    private var sourceCounts: [(name: String, count: Int, color: Color)] {
        let palette: [(String, Color)] = [
            ("CoinTelegraph", NewsCategory.crypto.color),
            ("MarketWatch",   Color(red: 0.074, green: 0.925, blue: 0.502)),
            ("Reuters",       NewsCategory.forex.color),
            ("ForexLive",     NewsCategory.stocks.color),
        ]
        let grouped = Dictionary(grouping: articles, by: \.source)
        return palette
            .map { (name, color) in (name, grouped[name]?.count ?? 0, color) }
            .sorted { $0.count > $1.count }
    }

    // MARK: - Body

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                trendingSection
                Divider().overlay(Color.fmsMuted.opacity(0.08))
                sentimentSection
                Divider().overlay(Color.fmsMuted.opacity(0.08))
                calendarSection
                Divider().overlay(Color.fmsMuted.opacity(0.08))
                sourcesSection
            }
        }
        .frame(width: 280)
        .background(Color.fmsSurface)
    }

    // MARK: - Trending Tickers

    private var trendingSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle(String(localized: "newsfeed.panel.trending_tickers", bundle: lang.bundle))

            ForEach(tickers, id: \.symbol) { ticker in
                tickerRow(ticker)
            }
        }
        .padding(16)
    }

    private func tickerRow(_ ticker: TickerItem) -> some View {
        HStack(spacing: 10) {
            // Icon
            Text(String(ticker.symbol.prefix(2)))
                .font(.system(size: 9, weight: .black))
                .foregroundStyle(ticker.color)
                .frame(width: 32, height: 32)
                .background(ticker.color.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))

            // Name
            VStack(alignment: .leading, spacing: 2) {
                Text(ticker.symbol)
                    .font(.system(size: 12, weight: .bold).monospacedDigit())
                    .foregroundStyle(Color.fmsOnSurface)
                Text(ticker.name)
                    .font(.system(size: 10))
                    .foregroundStyle(Color.fmsMuted)
                    .lineLimit(1)
            }

            Spacer()

            // Sparkline
            sparkline(points: ticker.sparkPoints, color: ticker.color)
                .frame(width: 44, height: 22)

            // Price + change
            VStack(alignment: .trailing, spacing: 2) {
                Text(ticker.price)
                    .font(.system(size: 11.5, weight: .bold).monospacedDigit())
                    .foregroundStyle(Color.fmsOnSurface)
                Text(ticker.change)
                    .font(.system(size: 10.5, weight: .bold).monospacedDigit())
                    .foregroundStyle(ticker.isPositive ? Color.fmsPrimary : Color.fmsLoss)
            }
        }
        .padding(10)
        .background(Color.fmsBackground.opacity(0.5), in: RoundedRectangle(cornerRadius: 9))
        .overlay(RoundedRectangle(cornerRadius: 9).stroke(Color.fmsMuted.opacity(0.07)))
    }

    private func sparkline(points: [CGFloat], color: Color) -> some View {
        Canvas { ctx, size in
            guard points.count > 1 else { return }
            let step = size.width / CGFloat(points.count - 1)
            var path = Path()
            for (i, p) in points.enumerated() {
                let x = CGFloat(i) * step
                let y = p * size.height
                if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                else       { path.addLine(to: CGPoint(x: x, y: y)) }
            }
            ctx.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
        }
    }

    // MARK: - Market Sentiment Gauge

    private var sentimentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle(String(localized: "newsfeed.panel.market_sentiment", bundle: lang.bundle))

            VStack(spacing: 6) {
                // Gauge arc
                gaugeView(value: 74)
                    .frame(height: 90)

                Text("newsfeed.panel.sentiment.description", bundle: lang.bundle)
                    .font(.system(size: 10.5))
                    .foregroundStyle(Color.fmsMuted)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }
        }
        .padding(16)
    }

    private func gaugeView(value: Int) -> some View {
        ZStack {
            // Track arc
            GaugeArc(startAngle: .degrees(180), endAngle: .degrees(360), fraction: 1.0)
                .stroke(Color.fmsMuted.opacity(0.1), style: StrokeStyle(lineWidth: 12, lineCap: .round))

            // Fear zone (red) — first 30%
            GaugeArc(startAngle: .degrees(180), endAngle: .degrees(360), fraction: 0.30)
                .stroke(Color.fmsLoss.opacity(0.7),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round))

            // Neutral zone (yellow) — 30–50%
            GaugeArc(startAngle: .degrees(180 + 0.30 * 180), endAngle: .degrees(360), fraction: (0.50 - 0.30) / 0.70)
                .stroke(Color.fmsWarning.opacity(0.7),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round))

            // Greed zone (green) — 50–100%
            let greedFraction = min(Double(value) / 100.0, 1.0)
            if greedFraction > 0.50 {
                GaugeArc(startAngle: .degrees(180 + 0.50 * 180), endAngle: .degrees(360),
                         fraction: (greedFraction - 0.50) / 0.50)
                    .stroke(Color.fmsPrimary.opacity(0.9),
                            style: StrokeStyle(lineWidth: 12, lineCap: .round))
            }

            // Score + label
            VStack(spacing: 2) {
                Text("\(value)")
                    .font(.system(size: 26, weight: .heavy).monospacedDigit())
                    .foregroundStyle(Color.fmsPrimary)
                Text("newsfeed.panel.sentiment.greed", bundle: lang.bundle)
                    .font(.system(size: 9.5, weight: .bold))
                    .foregroundStyle(Color.fmsPrimary)
                    .textCase(.uppercase)
                    .tracking(1)
            }
            .offset(y: 10)

            // Labels
            HStack {
                Text("newsfeed.panel.sentiment.fear", bundle: lang.bundle)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Color.fmsMuted)
                Spacer()
                Text("newsfeed.panel.sentiment.greed", bundle: lang.bundle)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Color.fmsMuted)
            }
            .frame(maxHeight: .infinity, alignment: .bottom)
        }
    }

    // MARK: - Economic Calendar

    private var calendarSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle(String(localized: "newsfeed.panel.upcoming_events", bundle: lang.bundle))

            VStack(spacing: 6) {
                ForEach(events, id: \.name) { event in
                    eventRow(event)
                }
            }

            // Impact legend
            HStack(spacing: 14) {
                legendDot(Color.fmsLoss,
                          label: String(localized: "newsfeed.panel.impact.high",   bundle: lang.bundle))
                legendDot(Color.fmsWarning,
                          label: String(localized: "newsfeed.panel.impact.medium", bundle: lang.bundle))
                legendDot(Color.fmsMuted.opacity(0.5),
                          label: String(localized: "newsfeed.panel.impact.low",    bundle: lang.bundle))
            }
            .padding(.top, 2)
        }
        .padding(16)
    }

    private func eventRow(_ event: EconEvent) -> some View {
        HStack(alignment: .top, spacing: 10) {
            impactDot(event.impact)
                .padding(.top, 5)

            VStack(alignment: .leading, spacing: 2) {
                Text(event.name)
                    .font(.system(size: 11.5, weight: .bold))
                    .foregroundStyle(Color.fmsOnSurface)
                HStack(spacing: 6) {
                    Text(event.currency)
                        .font(.system(size: 10))
                        .foregroundStyle(Color.fmsMuted)
                    Text(event.detail)
                        .font(.system(size: 10))
                        .foregroundStyle(Color.fmsMuted)
                }
            }

            Spacer()

            Text(event.time)
                .font(.system(size: 10, weight: .bold).monospacedDigit())
                .foregroundStyle(Color.fmsMuted)
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(Color.fmsBackground.opacity(0.8), in: RoundedRectangle(cornerRadius: 4))
        }
        .padding(10)
        .background(Color.fmsBackground.opacity(0.4), in: RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.fmsMuted.opacity(0.07)))
    }

    private func impactDot(_ impact: EconEvent.Impact) -> some View {
        let color: Color = switch impact {
        case .high:   Color.fmsLoss
        case .medium: Color.fmsWarning
        case .low:    Color.fmsMuted.opacity(0.5)
        }
        return Circle()
            .fill(color)
            .frame(width: 7, height: 7)
            .shadow(color: impact == .high ? color.opacity(0.6) : .clear, radius: 3)
    }

    private func legendDot(_ color: Color, label: String) -> some View {
        HStack(spacing: 5) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(label)
                .font(.system(size: 9.5, weight: .semibold))
                .foregroundStyle(Color.fmsMuted)
        }
    }

    // MARK: - Source Breakdown

    private var sourcesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle(String(localized: "newsfeed.panel.articles_by_source", bundle: lang.bundle))

            let counts = sourceCounts
            let topCount = counts.map(\.count).max() ?? 1

            VStack(spacing: 8) {
                ForEach(counts, id: \.name) { item in
                    sourceBar(name: item.name, count: item.count, maxCount: topCount, color: item.color)
                }
            }
        }
        .padding(16)
    }

    private func sourceBar(name: String, count: Int, maxCount: Int, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Circle().fill(color).frame(width: 7, height: 7)
                Text(name)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.fmsOnSurface)
                Spacer()
                Text("\(count)")
                    .font(.system(size: 10.5, weight: .bold).monospacedDigit())
                    .foregroundStyle(Color.fmsMuted)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.fmsMuted.opacity(0.08))
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color.opacity(0.55))
                        .frame(width: maxCount > 0 ? geo.size.width * CGFloat(count) / CGFloat(maxCount) : 0)
                }
            }
            .frame(height: 3)
        }
    }

    // MARK: - Helpers

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 9.5, weight: .bold))
            .foregroundStyle(Color.fmsMuted)
            .textCase(.uppercase)
            .tracking(1.2)
    }
}

// MARK: - Gauge arc shape

private struct GaugeArc: Shape {
    let startAngle: Angle
    let endAngle: Angle
    let fraction: Double

    func path(in rect: CGRect) -> Path {
        let cx = rect.midX
        let cy = rect.maxY
        let r  = min(rect.width / 2, rect.height) * 0.88
        let span = (endAngle - startAngle).degrees * fraction
        var p = Path()
        p.addArc(center:     CGPoint(x: cx, y: cy),
                 radius:     r,
                 startAngle: startAngle,
                 endAngle:   startAngle + .degrees(span),
                 clockwise:  false)
        return p
    }
}
