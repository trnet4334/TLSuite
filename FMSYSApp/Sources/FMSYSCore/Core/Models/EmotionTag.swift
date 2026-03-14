import Foundation

public enum EmotionTag: String, Codable, CaseIterable {
    case fearful    = "fearful"
    case greedy     = "greedy"
    case frustrated = "frustrated"
    case calm       = "calm"
    case confident  = "confident"
    case neutral    = "neutral"

    /// Human-readable label used in heatmap column headers
    public var displayName: String {
        switch self {
        case .fearful:    return "Fear"
        case .greedy:     return "Greed"
        case .frustrated: return "Bored"
        case .calm:       return "Calm"
        case .confident:  return "Focus"
        case .neutral:    return "Tired"
        }
    }
}
