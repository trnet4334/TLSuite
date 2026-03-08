import SwiftUI

public struct StrategyLabView: View {
    public init() {}

    public var body: some View {
        ZStack {
            Color.fmsBackground.frame(maxWidth: .infinity, maxHeight: .infinity)
            VStack(spacing: 16) {
                Image(systemName: "flask.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.fmsMuted)
                Text("Strategy Lab")
                    .font(.title2.bold())
                    .foregroundStyle(Color.fmsOnSurface)
                Text("Coming soon")
                    .font(.subheadline)
                    .foregroundStyle(Color.fmsMuted)
            }
        }
    }
}
