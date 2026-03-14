public enum EmotionTag: String, Codable, CaseIterable {
    case fearful    = "fearful"
    case greedy     = "greedy"
    case frustrated = "frustrated"  // heatmap column: "Bored"
    case calm       = "calm"
    case confident  = "confident"   // heatmap column: "Focus"
    case neutral    = "neutral"     // heatmap column: "Tired"

    /// Human-readable label used in heatmap column headers.
    /// Note: some case names differ from their display label —
    /// raw values are fixed by the SwiftData storage contract.
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
