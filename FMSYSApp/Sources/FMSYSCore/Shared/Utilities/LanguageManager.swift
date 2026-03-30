// Sources/FMSYSCore/Shared/Utilities/LanguageManager.swift
import Foundation
import Observation

@Observable
public final class LanguageManager {

    /// The bundle corresponding to the currently selected language.
    public private(set) var bundle: Bundle = .module

    @ObservationIgnored
    private var _storedLanguage: String {
        didSet { UserDefaults.standard.set(_storedLanguage, forKey: "appLanguage") }
    }

    public static let shared = LanguageManager()

    /// Maps display names (shown in the picker) to BCP-47 locale folder names.
    public static let languageOptions: [String] = [
        "English (United States)",
        "English (United Kingdom)",
        "繁體中文",
        "Deutsch",
        "Français",
        "日本語",
    ]

    private static let codeMap: [String: String] = [
        "English (United States)": "en",
        "English (United Kingdom)": "en-GB",
        "繁體中文":                  "zh-Hant",
        "Deutsch":                  "de",
        "Français":                 "fr",
        "日本語":                    "ja",
    ]

    public init() {
        _storedLanguage = UserDefaults.standard.string(forKey: "appLanguage")
                          ?? "English (United States)"
        applyLanguage(_storedLanguage)
    }

    /// Call this when the user picks a new language in Settings.
    public func set(language: String) {
        _storedLanguage = language
        applyLanguage(language)
    }

    public var currentLanguage: String { _storedLanguage }

    // MARK: - Private

    private func applyLanguage(_ display: String) {
        let code = Self.codeMap[display] ?? "en"
        if let path = Bundle.module.path(forResource: code, ofType: "lproj"),
           let b    = Bundle(path: path) {
            bundle = b
        } else {
            // Fallback to en
            if let path = Bundle.module.path(forResource: "en", ofType: "lproj"),
               let b    = Bundle(path: path) {
                bundle = b
            }
        }
    }
}

// MARK: - Convenience

extension Bundle {
    /// Shorthand: `Text("key", bundle: .localized)` inside any view.
    public static var localized: Bundle { LanguageManager.shared.bundle }
}
