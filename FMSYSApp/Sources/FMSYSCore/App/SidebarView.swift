// Sources/FMSYSCore/App/SidebarView.swift
import SwiftUI

public struct SidebarView: View {
    @Binding var selection: AppScreen
    @Binding var journalCategory: JournalCategory
    @State private var journalExpanded = true

    public init(selection: Binding<AppScreen>, journalCategory: Binding<JournalCategory>) {
        self._selection = selection
        self._journalCategory = journalCategory
    }

    public var body: some View {
        VStack(spacing: 0) {
            List(selection: $selection) {
                navItem(.dashboard,   icon: "chart.bar.fill",         label: "Dashboard",    shortcut: Character("1"))
                journalSection
                navItem(.backtesting, icon: "arrow.clockwise.circle", label: "Backtesting",  shortcut: Character("3"))
                navItem(.strategyLab, icon: "flask.fill",             label: "Strategy Lab", shortcut: Character("4"))
                navItem(.portfolio,   icon: "dollarsign.circle.fill", label: "Portfolio",    shortcut: Character("5"))
            }
            .listStyle(.sidebar)
            .frame(maxHeight: .infinity)

            equityCard
        }
        .frame(minWidth: 256, maxWidth: 256)
        .background(Color.fmsSurface)
    }

    private func navItem(_ screen: AppScreen, icon: String, label: String, shortcut: Character) -> some View {
        Label(label, systemImage: icon)
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
                        .font(.system(size: 12))
                        .foregroundStyle(journalCategory == cat && selection == .journal
                            ? Color.fmsPrimary
                            : Color.fmsMuted)
                        .padding(.leading, 8)
                }
                .buttonStyle(.plain)
            }
        } label: {
            Label("Journal", systemImage: "book.fill")
                .tag(AppScreen.journal)
                .keyboardShortcut("2", modifiers: .command)
                .simultaneousGesture(TapGesture().onEnded {
                    journalCategory = .all
                })
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
}
