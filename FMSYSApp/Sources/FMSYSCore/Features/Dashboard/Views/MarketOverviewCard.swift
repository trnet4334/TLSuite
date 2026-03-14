import SwiftUI
import Charts

public struct MarketOverviewCard: View {
    let quotes: [MarketQuote]

    public init(quotes: [MarketQuote]) {
        self.quotes = quotes
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.fmsPrimary)
                Text("Market Overview")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.fmsOnSurface)
            }
            VStack(spacing: 8) {
                ForEach(quotes) { quote in
                    QuoteRow(quote: quote)
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.fmsSurface, in: RoundedRectangle(cornerRadius: 12))
    }
}

private struct QuoteRow: View {
    let quote: MarketQuote

    var body: some View {
        HStack(spacing: 12) {
            Text(quote.id)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(iconColor)
                .frame(width: 32, height: 32)
                .background(iconColor.opacity(0.15), in: RoundedRectangle(cornerRadius: 6))

            VStack(alignment: .leading, spacing: 1) {
                Text(quote.name)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.fmsOnSurface)
                Text(priceFormatted)
                    .font(.system(size: 10))
                    .foregroundStyle(Color.fmsMuted)
            }

            Spacer()

            Chart {
                ForEach(Array(quote.sparkline.enumerated()), id: \.offset) { idx, val in
                    LineMark(
                        x: .value("i", idx),
                        y: .value("p", val)
                    )
                    .foregroundStyle(changeColor)
                    .lineStyle(StrokeStyle(lineWidth: 1.5))
                }
            }
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .frame(width: 64, height: 24)

            Text(changeFormatted)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(changeColor)
                .frame(width: 46, alignment: .trailing)
        }
        .padding(10)
        .background(Color.fmsBackground.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
    }

    private var iconColor: Color {
        quote.id == "BTC" ? Color.orange : Color.blue
    }
    private var changeColor: Color {
        quote.changePercent >= 0 ? Color.fmsPrimary : Color.fmsLoss
    }
    private var priceFormatted: String { "$\(String(format: "%.2f", quote.price))" }
    private var changeFormatted: String {
        let sign = quote.changePercent >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f", quote.changePercent))%"
    }
}
