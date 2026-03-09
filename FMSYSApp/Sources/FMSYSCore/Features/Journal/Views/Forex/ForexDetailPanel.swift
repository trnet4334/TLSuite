import SwiftUI

public struct ForexDetailPanel: View {
    @Bindable var trade: Trade
    let onSave: () -> Void

    public init(trade: Trade, onSave: @escaping () -> Void) {
        self.trade = trade
        self.onSave = onSave
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                detailHeader
                metricsRow1
                metricsRow2
                sessionNotesSection
                notesSection
                screenshotSection
            }
            .padding(24)
        }
        .background(Color.fmsBackground)
    }

    private var detailHeader: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(trade.asset)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Color.fmsOnSurface)
                Text("ID: #\(trade.id.uuidString.prefix(8).uppercased())")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.fmsMuted)
            }
            Spacer()
            Button("Save") { onSave() }
                .buttonStyle(.plain)
                .font(.system(size: 13, weight: .semibold))
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(Color.fmsPrimary, in: RoundedRectangle(cornerRadius: 8))
                .foregroundStyle(Color.fmsBackground)
        }
    }

    private var metricsRow1: some View {
        HStack(spacing: 12) {
            metricField(label: "ENTRY PRICE") {
                TextField("0.0000", value: $trade.entryPrice, format: .number)
            }
            metricField(label: "ENTRY TIME") {
                DatePicker("", selection: Binding(
                    get: { trade.entryAt },
                    set: { trade.entryAt = $0 }
                ), displayedComponents: .hourAndMinute)
                .labelsHidden()
            }
            metricField(label: "EXIT PRICE") {
                TextField("0.0000", value: Binding(
                    get: { trade.exitPrice ?? 0 },
                    set: { trade.exitPrice = $0 }
                ), format: .number)
            }
            metricField(label: "EXIT TIME") {
                DatePicker("", selection: Binding(
                    get: { trade.exitAt ?? Date() },
                    set: { trade.exitAt = $0 }
                ), displayedComponents: .hourAndMinute)
                .labelsHidden()
            }
        }
    }

    private var metricsRow2: some View {
        HStack(spacing: 12) {
            metricField(label: "PIP VALUE") {
                TextField("0.00", value: Binding(
                    get: { trade.pipValue ?? 0 },
                    set: { trade.pipValue = $0 }
                ), format: .number)
            }
            metricField(label: "LOT SIZE") {
                TextField("0.00", value: Binding(
                    get: { trade.lotSize ?? 0 },
                    set: { trade.lotSize = $0 }
                ), format: .number)
            }
            metricField(label: "EXPOSURE") {
                TextField("0.00", value: Binding(
                    get: { trade.exposure ?? 0 },
                    set: { trade.exposure = $0 }
                ), format: .number)
            }
            Spacer()
        }
    }

    private var sessionNotesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("SESSION NOTES")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Color.fmsMuted)
            TextEditor(text: Binding(
                get: { trade.sessionNotes ?? "" },
                set: { trade.sessionNotes = $0 }
            ))
            .font(.system(size: 13))
            .foregroundStyle(Color.fmsOnSurface)
            .frame(minHeight: 80)
            .padding(12)
            .background(Color.fmsSurface, in: RoundedRectangle(cornerRadius: 10))
            .scrollContentBackground(.hidden)
        }
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("TRADE REFLECTION & ANALYSIS")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Color.fmsMuted)
            TextEditor(text: Binding(
                get: { trade.notes ?? "" },
                set: { trade.notes = $0 }
            ))
            .font(.system(size: 13))
            .foregroundStyle(Color.fmsOnSurface)
            .frame(minHeight: 250)
            .padding(12)
            .background(Color.fmsSurface, in: RoundedRectangle(cornerRadius: 10))
            .scrollContentBackground(.hidden)
        }
    }

    private var screenshotSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("CHART SCREENSHOTS")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Color.fmsMuted)
            HStack(spacing: 12) {
                uploadArea(label: "Entry Chart")
                uploadArea(label: "Exit Chart")
            }
        }
    }

    private func uploadArea(label: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "icloud.and.arrow.up")
                .font(.system(size: 24))
                .foregroundStyle(Color.fmsMuted)
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(Color.fmsMuted)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 120)
        .background(Color.fmsSurface, in: RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [6]))
                .foregroundStyle(Color.fmsMuted.opacity(0.4))
        )
    }

    @ViewBuilder
    private func metricField<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Color.fmsMuted)
            content()
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .foregroundStyle(Color.fmsOnSurface)
                .padding(10)
                .background(Color.fmsSurface, in: RoundedRectangle(cornerRadius: 8))
        }
        .frame(maxWidth: .infinity)
    }
}
