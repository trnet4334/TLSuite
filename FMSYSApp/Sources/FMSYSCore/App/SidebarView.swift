// Sources/FMSYSCore/App/SidebarView.swift
import SwiftUI

public struct SidebarView: View {
    @Binding var selection: AppScreen
    @Binding var journalCategory: JournalCategory
    @State private var journalExpanded = true

    public init(
        selection: Binding<AppScreen>,
        journalCategory: Binding<JournalCategory>
    ) {
        self._selection = selection
        self._journalCategory = journalCategory
    }

    public var body: some View {
        VStack(spacing: 0) {
            List(selection: $selection) {
                navItem(.dashboard,   icon: "chart.bar.fill",         label: "Dashboard",    shortcut: Character("1"))
                journalSection
                navItem(.portfolio,   icon: "dollarsign.circle.fill", label: "Portfolio",    shortcut: Character("3"))
                navItem(.newsFeed,    icon: "newspaper.fill",         label: "News Feed",    shortcut: Character("4"))
                // TODO: Backtesting (⌘5) — future release
                // TODO: Strategy Lab (⌘6) — future release
            }
            .listStyle(.sidebar)
            .scrollContentBackground(.hidden)
            .frame(maxHeight: .infinity)

            bottomCard(for: selection)
        }
        .frame(minWidth: 256, maxWidth: 256)
        .background(.thickMaterial)
    }

    private func navItem(_ screen: AppScreen, icon: String, label: String, shortcut: Character) -> some View {
        Label(label, systemImage: icon)
            .labelStyle(SidebarLabelStyle())
            .font(.system(size: 17, weight: .bold))
            .foregroundStyle(selection == screen ? Color.fmsPrimary : Color.fmsOnSurface)
            .tag(screen)
            .keyboardShortcut(KeyEquivalent(shortcut), modifiers: .command)
    }

    private var journalSection: some View {
        DisclosureGroup(isExpanded: $journalExpanded) {
            ForEach(JournalCategory.allCases.filter { $0 != .all }, id: \.self) { cat in
                Button {
                    selection = .journal
                    journalCategory = cat
                } label: {
                    Text(cat.rawValue)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(journalCategory == cat && selection == .journal
                            ? Color.fmsPrimary
                            : Color.fmsMuted)
                        .padding(.leading, 8)
                }
                .buttonStyle(.plain)
            }
        } label: {
            Label("Journal", systemImage: "book.fill")
                .labelStyle(SidebarLabelStyle())
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(selection == .journal ? Color.fmsPrimary : Color.fmsOnSurface)
                .tag(AppScreen.journal)
                .keyboardShortcut("2", modifiers: .command)
                .simultaneousGesture(TapGesture().onEnded {
                    journalCategory = .all
                })
        }
    }

    @ViewBuilder
    private func bottomCard(for screen: AppScreen) -> some View {
        switch screen {
        case .strategyLab:
            strategyLabCard
        case .portfolio:
            portfolioCard
        case .newsFeed:
            newsFeedCard
        default:
            equityCard
        }
    }

    private var equityCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Total Equity")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(Color.fmsMuted)
            Text("$0.00")
                .font(.system(size: 18, weight: .bold).monospacedDigit())
                .foregroundStyle(Color.fmsOnSurface)
            Text("MTD  —")
                .font(.system(size: 11))
                .foregroundStyle(Color.fmsMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.fmsPrimary.opacity(0.3), lineWidth: 1)
        )
        .padding(12)
    }

    private var strategyLabCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Active Labs")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(Color.fmsPrimary)
                .textCase(.uppercase)
                .tracking(0.5)
            Text("4 Running")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Color.fmsOnSurface)
            HStack(spacing: 4) {
                Image(systemName: "memorychip")
                    .font(.system(size: 10))
                Text("82% CPU Usage")
                    .font(.system(size: 11, weight: .bold))
            }
            .foregroundStyle(Color.fmsPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            LinearGradient(
                colors: [Color.fmsPrimary.opacity(0.1), Color.clear],
                startPoint: .topLeading, endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 12)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.fmsPrimary.opacity(0.2), lineWidth: 1)
        )
        .padding(12)
    }

    private var newsFeedCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Market News")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(Color.fmsPrimary)
                .textCase(.uppercase)
                .tracking(0.5)
            Text("Live Feed")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Color.fmsOnSurface)
            HStack(spacing: 4) {
                Image(systemName: "dot.radiowaves.left.and.right")
                    .font(.system(size: 10))
                Text("4 Sources Active")
                    .font(.system(size: 11, weight: .bold))
            }
            .foregroundStyle(Color.fmsPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            LinearGradient(
                colors: [Color.fmsPrimary.opacity(0.1), Color.clear],
                startPoint: .topLeading, endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 12)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.fmsPrimary.opacity(0.2), lineWidth: 1)
        )
        .padding(12)
    }

    private var portfolioCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Total Equity")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(Color.fmsPrimary)
                .textCase(.uppercase)
                .tracking(0.5)
            Text("$142,500.42")
                .font(.system(size: 18, weight: .bold).monospacedDigit())
                .foregroundStyle(Color.fmsOnSurface)
            HStack(spacing: 4) {
                Image(systemName: "arrow.up")
                    .font(.system(size: 10))
                Text("+12.5% MTD")
                    .font(.system(size: 11, weight: .bold))
            }
            .foregroundStyle(Color.fmsPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            LinearGradient(
                colors: [Color.fmsPrimary.opacity(0.1), Color.clear],
                startPoint: .topLeading, endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 12)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.fmsPrimary.opacity(0.2), lineWidth: 1)
        )
        .padding(12)
    }
}

private struct SidebarLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 5) {
            configuration.icon
            configuration.title
        }
    }
}
