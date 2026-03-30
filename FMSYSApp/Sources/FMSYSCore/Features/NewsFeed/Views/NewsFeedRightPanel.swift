// Sources/FMSYSCore/Features/NewsFeed/Views/NewsFeedRightPanel.swift
import SwiftUI

struct NewsFeedRightPanel: View {

    let articles: [NewsArticle]
    let panelService: MarketPanelService
    @Environment(LanguageManager.self) private var lang


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
            HStack {
                sectionTitle(String(localized: "newsfeed.panel.trending_tickers", bundle: lang.bundle))
                Spacer()
                if panelService.isLoadingTickers {
                    ProgressView().scaleEffect(0.5)
                }
            }

            if panelService.tickers.isEmpty {
                ForEach(0..<4, id: \.self) { _ in skeletonRow }
            } else {
                ForEach(panelService.tickers) { ticker in
                    tickerRow(ticker)
                }
            }
        }
        .padding(16)
    }

    private var skeletonRow: some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.fmsMuted.opacity(0.1))
                .frame(width: 32, height: 32)
            VStack(alignment: .leading, spacing: 4) {
                RoundedRectangle(cornerRadius: 3).fill(Color.fmsMuted.opacity(0.12)).frame(width: 40, height: 9)
                RoundedRectangle(cornerRadius: 3).fill(Color.fmsMuted.opacity(0.07)).frame(width: 70, height: 8)
            }
            Spacer()
            RoundedRectangle(cornerRadius: 3).fill(Color.fmsMuted.opacity(0.07)).frame(width: 44, height: 22)
            VStack(alignment: .trailing, spacing: 4) {
                RoundedRectangle(cornerRadius: 3).fill(Color.fmsMuted.opacity(0.12)).frame(width: 48, height: 9)
                RoundedRectangle(cornerRadius: 3).fill(Color.fmsMuted.opacity(0.08)).frame(width: 36, height: 8)
            }
        }
        .padding(10)
        .background(Color.fmsBackground.opacity(0.5), in: RoundedRectangle(cornerRadius: 9))
    }

    private func tickerRow(_ ticker: LiveTicker) -> some View {
        let color: Color = ticker.isPositive
            ? Color(red: 0.074, green: 0.925, blue: 0.502)
            : Color(red: 1.0, green: 0.373, blue: 0.341)

        return HStack(spacing: 10) {
            Text(String(ticker.symbol.prefix(2)))
                .font(.system(size: 9, weight: .black))
                .foregroundStyle(color)
                .frame(width: 32, height: 32)
                .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))

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

            sparkline(points: ticker.sparkline, color: color)
                .frame(width: 44, height: 22)

            VStack(alignment: .trailing, spacing: 2) {
                Text(ticker.formattedPrice)
                    .font(.system(size: 11.5, weight: .bold).monospacedDigit())
                    .foregroundStyle(Color.fmsOnSurface)
                Text(ticker.formattedChange)
                    .font(.system(size: 10.5, weight: .bold).monospacedDigit())
                    .foregroundStyle(ticker.isPositive ? Color.fmsPrimary : Color.fmsLoss)
            }
        }
        .padding(10)
        .background(Color.fmsBackground.opacity(0.5), in: RoundedRectangle(cornerRadius: 9))
        .overlay(RoundedRectangle(cornerRadius: 9).stroke(Color.fmsMuted.opacity(0.07)))
    }

    private func sparkline(points: [Double], color: Color) -> some View {
        Canvas { ctx, size in
            guard points.count > 1 else { return }
            let step = size.width / CGFloat(points.count - 1)
            var path = Path()
            for (i, p) in points.enumerated() {
                let x = CGFloat(i) * step
                let y = CGFloat(p) * size.height
                if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                else       { path.addLine(to: CGPoint(x: x, y: y)) }
            }
            ctx.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
        }
    }

    // MARK: - Market Sentiment Gauge

    private var sentimentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                sectionTitle(String(localized: "newsfeed.panel.market_sentiment", bundle: lang.bundle))
                Spacer()
                if panelService.isLoadingSentiment {
                    ProgressView().scaleEffect(0.5)
                }
            }

            VStack(spacing: 6) {
                let value = panelService.fearGreed?.value ?? 0
                let label = panelService.fearGreed?.classification ?? "—"

                gaugeView(value: value, label: label)
                    .frame(height: 90)

                if let fg = panelService.fearGreed {
                    Text(fg.classification)
                        .font(.system(size: 10.5))
                        .foregroundStyle(Color.fmsMuted)
                        .multilineTextAlignment(.center)
                } else if !panelService.isLoadingSentiment {
                    Text("newsfeed.panel.sentiment.description", bundle: lang.bundle)
                        .font(.system(size: 10.5))
                        .foregroundStyle(Color.fmsMuted)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                }
            }
        }
        .padding(16)
    }

    private func gaugeView(value: Int, label: String) -> some View {
        let fraction = Double(value) / 100.0
        let gaugeColor: Color = value < 30 ? Color.fmsLoss
                              : value < 50 ? Color.fmsWarning
                              : Color.fmsPrimary

        return ZStack {
            GaugeArc(startAngle: .degrees(180), endAngle: .degrees(360), fraction: 1.0)
                .stroke(Color.fmsMuted.opacity(0.1), style: StrokeStyle(lineWidth: 12, lineCap: .round))

            GaugeArc(startAngle: .degrees(180), endAngle: .degrees(360), fraction: 0.30)
                .stroke(Color.fmsLoss.opacity(0.7), style: StrokeStyle(lineWidth: 12, lineCap: .round))

            GaugeArc(startAngle: .degrees(180 + 0.30 * 180), endAngle: .degrees(360), fraction: (0.50 - 0.30) / 0.70)
                .stroke(Color.fmsWarning.opacity(0.7), style: StrokeStyle(lineWidth: 12, lineCap: .round))

            if fraction > 0.50 {
                GaugeArc(startAngle: .degrees(180 + 0.50 * 180), endAngle: .degrees(360),
                         fraction: (fraction - 0.50) / 0.50)
                    .stroke(Color.fmsPrimary.opacity(0.9), style: StrokeStyle(lineWidth: 12, lineCap: .round))
            }

            VStack(spacing: 2) {
                if panelService.fearGreed == nil && panelService.isLoadingSentiment {
                    ProgressView().scaleEffect(0.6)
                } else {
                    Text(value > 0 ? "\(value)" : "—")
                        .font(.system(size: 26, weight: .heavy).monospacedDigit())
                        .foregroundStyle(gaugeColor)
                    Text(label)
                        .font(.system(size: 9.5, weight: .bold))
                        .foregroundStyle(gaugeColor)
                        .textCase(.uppercase)
                        .tracking(1)
                }
            }
            .offset(y: 10)

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
            HStack {
                sectionTitle(String(localized: "newsfeed.panel.upcoming_events", bundle: lang.bundle))
                Spacer()
                if panelService.isLoadingCalendar {
                    ProgressView().scaleEffect(0.5)
                }
            }

            if panelService.calendarEvents.isEmpty && !panelService.isLoadingCalendar {
                // Skeleton while loading or no events
                ForEach(0..<3, id: \.self) { _ in skeletonEventRow }
            } else {
                VStack(spacing: 6) {
                    ForEach(panelService.calendarEvents) { event in
                        eventRow(event)
                    }
                }
            }

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

    private var skeletonEventRow: some View {
        HStack(alignment: .top, spacing: 10) {
            Circle().fill(Color.fmsMuted.opacity(0.12)).frame(width: 7, height: 7).padding(.top, 5)
            VStack(alignment: .leading, spacing: 5) {
                RoundedRectangle(cornerRadius: 3).fill(Color.fmsMuted.opacity(0.12)).frame(width: 110, height: 9)
                RoundedRectangle(cornerRadius: 3).fill(Color.fmsMuted.opacity(0.07)).frame(width: 70, height: 8)
            }
            Spacer()
            RoundedRectangle(cornerRadius: 4).fill(Color.fmsMuted.opacity(0.08)).frame(width: 36, height: 20)
        }
        .padding(10)
        .background(Color.fmsBackground.opacity(0.4), in: RoundedRectangle(cornerRadius: 8))
    }

    private func eventRow(_ event: LiveEconEvent) -> some View {
        HStack(alignment: .top, spacing: 10) {
            impactDot(event.impact).padding(.top, 5)

            VStack(alignment: .leading, spacing: 2) {
                Text(event.name)
                    .font(.system(size: 11.5, weight: .bold))
                    .foregroundStyle(Color.fmsOnSurface)
                    .lineLimit(2)
                HStack(spacing: 6) {
                    Text(event.currency).font(.system(size: 10)).foregroundStyle(Color.fmsMuted)
                    if !event.detail.isEmpty {
                        Text(event.detail).font(.system(size: 10)).foregroundStyle(Color.fmsMuted)
                    }
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

    private func impactDot(_ impact: LiveEconEvent.Impact) -> some View {
        let color: Color = switch impact {
        case .high:   Color.fmsLoss
        case .medium: Color.fmsWarning
        case .low:    Color.fmsMuted.opacity(0.5)
        }
        return Circle().fill(color).frame(width: 7, height: 7)
            .shadow(color: impact == .high ? color.opacity(0.6) : .clear, radius: 3)
    }

    private func legendDot(_ color: Color, label: String) -> some View {
        HStack(spacing: 5) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(label).font(.system(size: 9.5, weight: .semibold)).foregroundStyle(Color.fmsMuted)
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
                Text(name).font(.system(size: 11, weight: .semibold)).foregroundStyle(Color.fmsOnSurface)
                Spacer()
                Text("\(count)").font(.system(size: 10.5, weight: .bold).monospacedDigit()).foregroundStyle(Color.fmsMuted)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2).fill(Color.fmsMuted.opacity(0.08))
                    RoundedRectangle(cornerRadius: 2).fill(color.opacity(0.55))
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
        p.addArc(center: CGPoint(x: cx, y: cy), radius: r,
                 startAngle: startAngle, endAngle: startAngle + .degrees(span), clockwise: false)
        return p
    }
}
