// Sources/FMSYSCore/App/SidebarRail.swift
import SwiftUI

public struct SidebarRail: View {
    @Binding var selection: AppScreen

    private let items: [(AppScreen, String)] = [
        (.dashboard,   "chart.bar.fill"),
        (.journal,     "book.fill"),
        (.backtesting, "arrow.clockwise.circle"),
        (.strategyLab, "flask.fill"),
        (.portfolio,   "dollarsign.circle.fill"),
    ]

    public init(selection: Binding<AppScreen>) {
        self._selection = selection
    }

    public var body: some View {
        VStack(spacing: 4) {
            ForEach(items, id: \.0) { screen, icon in
                Button {
                    selection = screen
                } label: {
                    Image(systemName: icon)
                        .font(.system(size: 19))
                        .foregroundStyle(selection == screen ? Color.fmsPrimary : Color.fmsMuted)
                        .frame(width: 44, height: 44)
                        .background(
                            selection == screen ? Color.fmsPrimary.opacity(0.12) : Color.clear,
                            in: RoundedRectangle(cornerRadius: 10)
                        )
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
        .padding(.top, 12)
        .frame(width: 64)
        .background(Color.fmsSurface)
    }
}
