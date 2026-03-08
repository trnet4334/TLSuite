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
            return try ModelContainer(for: Trade.self, configurations: config)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()

    private let authService: AuthService = {
        let baseURL = URL(string: "https://api.fmsys.io/v1")!
        return AuthService(
            client: APIClient(),
            keychain: KeychainManager(),
            baseURL: baseURL
        )
    }()

    init() {
        NSApplication.shared.setActivationPolicy(.regular)
    }

    var body: some Scene {
        WindowGroup {
            MainAppView(
                appState: AppState(),
                authService: authService,
                modelContainer: modelContainer
            )
            .frame(minWidth: 480, minHeight: 640)
        }
        .defaultSize(width: 480, height: 700)
    }
}
