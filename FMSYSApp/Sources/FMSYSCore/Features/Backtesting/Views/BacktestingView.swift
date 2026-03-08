import SwiftUI

public struct BacktestingView: View {
    public init() {}

    public var body: some View {
        ZStack {
            Color.fmsBackground.frame(maxWidth: .infinity, maxHeight: .infinity)
            VStack(spacing: 16) {
                Image(systemName: "arrow.clockwise.circle")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.fmsMuted)
                Text("Backtesting")
                    .font(.title2.bold())
                    .foregroundStyle(Color.fmsOnSurface)
                Text("Coming soon")
                    .font(.subheadline)
                    .foregroundStyle(Color.fmsMuted)
            }
        }
    }
}
