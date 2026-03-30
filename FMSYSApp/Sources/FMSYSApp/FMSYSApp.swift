import SwiftUI
import SwiftData
import AppKit
import FMSYSCore

private final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.activate(ignoringOtherApps: true)
    }
}

@main
struct FMSYSApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    private let modelContainer: ModelContainer = {
        do {
            let config = ModelConfiguration("fmsys", isStoredInMemoryOnly: false)
            return try ModelContainer(for: Trade.self, Strategy.self, BacktestResult.self, JournalAttachment.self, configurations: config)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()

    private let authService: LocalAuthService = LocalAuthService()

    init() {
        NSApplication.shared.setActivationPolicy(.regular)
    }

    var body: some Scene {
        WindowGroup {
            MainAppView(
                store: AppStore(modelContainer: modelContainer),
                authService: authService
            )
            .frame(minWidth: 1000, minHeight: 640)
        }
        .defaultSize(width: 1280, height: 800)
    }
}
