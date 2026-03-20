import Foundation

public enum AppScreen: String, Hashable, CaseIterable {
    case dashboard   = "Dashboard"
    case journal     = "Journal"
    case backtesting = "Backtesting"
    case strategyLab = "Strategy Lab"
    case portfolio   = "Portfolio"
    case newsFeed    = "News Feed"
}
