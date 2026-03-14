// Sources/FMSYSCore/Features/StrategyLab/Views/StrategyLabView.swift
import SwiftUI
import SwiftData

public struct StrategyLabView: View {
    @State private var viewModel: StrategyViewModel

    public init(modelContainer: ModelContainer) {
        let repo = StrategyRepository(context: modelContainer.mainContext)
        self._viewModel = State(wrappedValue: StrategyViewModel(repository: repo))
    }

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    public var body: some View {
        HSplitView {
            mainContent
            inspectorPanel
        }
        .task { viewModel.load() }
    }

    private var mainContent: some View {
        VStack(spacing: 0) {
            header
            if viewModel.strategies.isEmpty {
                emptyState
            } else {
                ScrollView(.vertical) {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(viewModel.strategies) { strategy in
                            StrategyCard(
                                strategy: strategy,
                                isSelected: viewModel.selectedStrategy?.id == strategy.id,
                                onTap: { viewModel.selectedStrategy = strategy }
                            )
                        }
                    }
                    .padding(24)
                }
            }
        }
        .frame(minWidth: 400)
        .background(Color.fmsBackground)
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Strategy Lab")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Color.fmsOnSurface)
                Text("Develop, test, and optimize algorithmic models")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.fmsMuted)
            }
            Spacer()
            Button {
                viewModel.add()
            } label: {
                Label("New Strategy", systemImage: "plus")
                    .font(.system(size: 13, weight: .bold))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(Color.fmsOnSurface, in: RoundedRectangle(cornerRadius: 8))
                    .foregroundStyle(Color.fmsBackground)
            }
            .buttonStyle(.plain)
        }
        .padding(24)
    }

    private var inspectorPanel: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Inspector")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.fmsOnSurface)
                Spacer()
                Image(systemName: "info.circle")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.fmsMuted)
            }
            .padding(16)
            Divider().overlay(Color.fmsMuted.opacity(0.1))
            StrategyInspectorPanel(viewModel: viewModel)
        }
        .frame(width: 320)
        .background(Color.fmsSurface.opacity(0.5))
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "flask.fill")
                .font(.system(size: 48))
                .foregroundStyle(Color.fmsMuted.opacity(0.4))
            Text("Create Your First Strategy")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.fmsOnSurface)
            Text("Build, test, and optimize your algorithmic trading strategies.")
                .font(.system(size: 13))
                .foregroundStyle(Color.fmsMuted)
                .multilineTextAlignment(.center)
            Button("New Strategy") { viewModel.add() }
                .buttonStyle(.borderedProminent)
                .tint(Color.fmsPrimary)
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
