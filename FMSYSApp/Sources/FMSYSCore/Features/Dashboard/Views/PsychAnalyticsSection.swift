import SwiftUI

public struct PsychAnalyticsSection: View {
    let analytics: PsychAnalytics

    private let emotionColumns = EmotionTag.allCases.map { $0.displayName }

    public init(analytics: PsychAnalytics) {
        self.analytics = analytics
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.fmsPrimary)
                Text("PSYCHOLOGICAL ANALYTICS")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color.fmsOnSurface)
                    .kerning(0.5)
                Spacer()
                Text("LAST 30 SESSIONS")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color.fmsMuted)
                    .kerning(0.5)
            }

            GeometryReader { geo in
                HStack(alignment: .top, spacing: 24) {
                    VStack(spacing: 12) {
                        ScoreBar(label: "Discipline Score", value: analytics.disciplineScore, color: Color.fmsPrimary)
                        ScoreBar(label: "Patience Index", value: analytics.patienceIndex, color: Color(red: 0.345, green: 0.651, blue: 1.0))
                    }
                    .frame(width: (geo.size.width - 24) / 3)

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Emotion vs. P/L Heatmap")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(Color.fmsMuted)
                            Spacer()
                            legend
                        }
                        heatmapGrid
                    }
                    .frame(width: (geo.size.width - 24) * 2 / 3)
                }
            }
            .frame(minHeight: 120)
        }
        .padding(20)
        .background(Color.fmsSurface, in: RoundedRectangle(cornerRadius: 12))
    }

    private var legend: some View {
        HStack(spacing: 8) {
            legendSwatch(color: Color.fmsLoss, label: "Loss")
            legendSwatch(color: Color.fmsMuted.opacity(0.5), label: "Neutral")
            legendSwatch(color: Color.fmsPrimary, label: "Profit")
        }
    }

    private func legendSwatch(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.system(size: 9))
                .foregroundStyle(Color.fmsMuted)
        }
    }

    private var heatmapGrid: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: emotionColumns.count),
            spacing: 4
        ) {
            ForEach(emotionColumns, id: \.self) { col in
                Text(col)
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(Color.fmsMuted.opacity(0.6))
                    .frame(maxWidth: .infinity)
            }
            ForEach([PLBucket.profit, .neutral, .loss], id: \.rawValue) { bucket in
                ForEach(emotionColumns, id: \.self) { col in
                    let count = analytics.heatmapCells
                        .first { $0.emotion == col && $0.plBucket == bucket }?.count ?? 0
                    HeatmapCellView(bucket: bucket, count: count)
                }
            }
        }
    }
}

private struct ScoreBar: View {
    let label: String
    let value: Double
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color.fmsMuted)
                Spacer()
                Text("\(Int(value * 100))%")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(color)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.fmsBackground)
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geo.size.width * max(0, min(value, 1)), height: 6)
                }
            }
            .frame(height: 6)
        }
        .padding(16)
        .background(Color.fmsBackground.opacity(0.5), in: RoundedRectangle(cornerRadius: 10))
    }
}

private struct HeatmapCellView: View {
    let bucket: PLBucket
    let count: Int

    private var opacity: Double {
        guard count > 0 else { return 0.04 }
        return min(0.2 + Double(count) * 0.15, 0.9)
    }

    private var color: Color {
        switch bucket {
        case .profit:  return Color.fmsPrimary
        case .loss:    return Color.fmsLoss
        case .neutral: return Color.fmsMuted
        }
    }

    var body: some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(color.opacity(opacity))
            .aspectRatio(1, contentMode: .fit)
    }
}
