// Sources/FMSYSCore/Features/StrategyLab/Views/StrategyInspectorPanel.swift
import SwiftUI

public struct StrategyInspectorPanel: View {
    @Bindable var viewModel: StrategyViewModel
    @Environment(LanguageManager.self) private var lang

    public var body: some View {
        if let strategy = viewModel.selectedStrategy {
            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: 24) {
                    logicSection(strategy: strategy)
                    parametersSection(strategy: strategy)
                    Button {
                        viewModel.update(strategy)
                        // TODO: trigger real backtest in future phase
                    } label: {
                        Text("strategy.inspector.run_backtest", bundle: lang.bundle)
                            .font(.system(size: 13, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.blue, in: RoundedRectangle(cornerRadius: 8))
                            .foregroundStyle(Color.white)
                    }
                    .buttonStyle(.plain)
                }
                .padding(16)
            }
        } else {
            ContentUnavailableView(
                String(localized: "strategy.inspector.empty.title", bundle: lang.bundle),
                systemImage: "flask",
                description: Text("strategy.inspector.empty.description", bundle: lang.bundle)
            )
        }
    }

    @ViewBuilder
    private func logicSection(strategy: Strategy) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(
                String(localized: "strategy.inspector.logic.title", bundle: lang.bundle),
                systemImage: "chevron.left.forwardslash.chevron.right"
            )
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(Color.fmsMuted)
            .textCase(.uppercase)

            TextEditor(text: Binding(
                get: { strategy.logicCode },
                set: { strategy.logicCode = $0 }
            ))
            .font(.system(size: 11, design: .monospaced))
            .foregroundStyle(Color(red: 0.788, green: 0.820, blue: 0.855))
            .scrollContentBackground(.hidden)
            .padding(10)
            .frame(minHeight: 140)
            .background(Color(hex: "#1e1e1e"), in: RoundedRectangle(cornerRadius: 8))
        }
    }

    @ViewBuilder
    private func parametersSection(strategy: Strategy) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(
                String(localized: "strategy.inspector.parameters.title", bundle: lang.bundle),
                systemImage: "slider.horizontal.3"
            )
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(Color.fmsMuted)
            .textCase(.uppercase)

            parameterSlider(
                label: String(localized: "strategy.inspector.parameters.ema_fast", bundle: lang.bundle),
                value: Binding(
                    get: { Double(strategy.emaFastPeriod) },
                    set: { strategy.emaFastPeriod = Int($0) }
                ),
                range: 1...50
            )
            parameterSlider(
                label: String(localized: "strategy.inspector.parameters.ema_slow", bundle: lang.bundle),
                value: Binding(
                    get: { Double(strategy.emaSlowPeriod) },
                    set: { strategy.emaSlowPeriod = Int($0) }
                ),
                range: 1...100
            )

            Divider().overlay(Color.fmsMuted.opacity(0.1))

            Toggle(isOn: Binding(
                get: { strategy.riskMgmtEnabled },
                set: { strategy.riskMgmtEnabled = $0 }
            )) {
                Text("strategy.inspector.parameters.risk_management", bundle: lang.bundle)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.fmsOnSurface.opacity(0.7))
            }
            .tint(Color.fmsPrimary)

            Toggle(isOn: Binding(
                get: { strategy.trailingStopEnabled },
                set: { strategy.trailingStopEnabled = $0 }
            )) {
                Text("strategy.inspector.parameters.trailing_stop", bundle: lang.bundle)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.fmsOnSurface.opacity(0.7))
            }
            .tint(Color.fmsPrimary)
        }
    }

    @ViewBuilder
    private func parameterSlider(label: String, value: Binding<Double>, range: ClosedRange<Double>) -> some View {
        VStack(spacing: 6) {
            HStack {
                Text(label)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.fmsOnSurface.opacity(0.7))
                Spacer()
                Text(String(Int(value.wrappedValue)))
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.fmsOnSurface)
            }
            Slider(value: value, in: range, step: 1)
                .tint(Color.fmsPrimary)
        }
    }
}
