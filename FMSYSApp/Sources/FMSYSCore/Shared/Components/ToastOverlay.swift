import SwiftUI

public enum ToastStyle {
    case info, success, warning, error

    var color: Color {
        switch self {
        case .info:    return .fmsMuted
        case .success: return .fmsPrimary
        case .warning: return .fmsWarning
        case .error:   return .fmsLoss
        }
    }

    var icon: String {
        switch self {
        case .info:    return "info.circle"
        case .success: return "checkmark.circle"
        case .warning: return "exclamationmark.triangle"
        case .error:   return "xmark.circle"
        }
    }
}

public struct ToastOverlay: View {
    let message: String
    let style: ToastStyle

    public init(message: String, style: ToastStyle = .error) {
        self.message = message
        self.style = style
    }

    public var body: some View {
        HStack(spacing: 8) {
            Image(systemName: style.icon)
                .foregroundStyle(style.color)
            Text(message)
                .font(.footnote)
                .foregroundStyle(Color.fmsOnSurface)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.fmsSurface, in: RoundedRectangle(cornerRadius: 10))
        .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
    }
}
