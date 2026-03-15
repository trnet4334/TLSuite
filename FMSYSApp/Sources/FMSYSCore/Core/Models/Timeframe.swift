// Sources/FMSYSCore/Core/Models/Timeframe.swift
import Foundation

public enum Timeframe: String, Codable, CaseIterable {
    case m1  = "1m"
    case m5  = "5m"
    case m15 = "15m"
    case h1  = "1h"
    case h4  = "4h"
    case d1  = "1d"
    case w1  = "1w"

    public var displayName: String {
        switch self {
        case .m1:  return "1 Min"
        case .m5:  return "5 Min"
        case .m15: return "15 Min"
        case .h1:  return "1 Hour"
        case .h4:  return "4 Hours"
        case .d1:  return "Daily"
        case .w1:  return "Weekly"
        }
    }
}
