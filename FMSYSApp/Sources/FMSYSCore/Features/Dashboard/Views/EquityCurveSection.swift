import SwiftUI
import Charts

public struct EquityCurveSection: View {
    @Binding var selectedRange: DashboardRange
    let curve: [EquityPoint]
    @Environment(LanguageManager.self) private var lang

    public init(selectedRange: Binding<DashboardRange>, curve: [EquityPoint]) {
        self._selectedRange = selectedRange
        self.curve = curve
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("dashboard.equity_curve.title", bundle: lang.bundle)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.fmsOnSurface)
                    Text("dashboard.equity_curve.subtitle", bundle: lang.bundle)
                        .font(.system(size: 11))
                        .foregroundStyle(Color.fmsMuted)
                }
                Spacer()
                rangePicker
            }
            if curve.isEmpty {
                emptyState
            } else {
                equityChart
            }
        }
        .padding(20)
        .background(Color.fmsSurface, in: RoundedRectangle(cornerRadius: 12))
    }

    private var rangePicker: some View {
        HStack(spacing: 2) {
            ForEach(DashboardRange.allCases, id: \.self) { range in
                Button {
                    selectedRange = range
                } label: {
                    Text(range.label)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(selectedRange == range ? Color.fmsBackground : Color.fmsOnSurface)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            selectedRange == range ? Color.fmsOnSurface : Color.clear,
                            in: RoundedRectangle(cornerRadius: 6)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Color.fmsBackground.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
    }

    private var equityChart: some View {
        Chart(curve) { point in
            AreaMark(
                x: .value("Date", point.date),
                y: .value("P&L", point.value)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [Color.fmsPrimary.opacity(0.2), Color.fmsPrimary.opacity(0)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            LineMark(
                x: .value("Date", point.date),
                y: .value("P&L", point.value)
            )
            .foregroundStyle(Color.fmsPrimary)
            .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))
        }
        .frame(height: 180)
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Color.fmsMuted)
            }
        }
        .chartYAxis {
            AxisMarks { _ in
                AxisValueLabel()
                    .font(.system(size: 9))
                    .foregroundStyle(Color.fmsMuted)
            }
        }
    }

    private var emptyState: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.fmsBackground.opacity(0.5))
                .frame(height: 180)
            Text("dashboard.equity_curve.empty", bundle: lang.bundle)
                .font(.system(size: 12))
                .foregroundStyle(Color.fmsMuted)
        }
    }
}
