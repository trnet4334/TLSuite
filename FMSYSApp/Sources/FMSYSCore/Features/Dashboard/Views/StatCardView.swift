import SwiftUI

struct StatCardView: View {
    let title: String
    let value: String
    var valueColor: Color = Color.fmsOnSurface
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(Color.fmsMuted)
            Text(value)
                .font(.title2.bold().monospacedDigit())
                .foregroundStyle(valueColor)
            if let subtitle {
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(Color.fmsMuted)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.fmsSurface, in: RoundedRectangle(cornerRadius: 12))
    }
}
