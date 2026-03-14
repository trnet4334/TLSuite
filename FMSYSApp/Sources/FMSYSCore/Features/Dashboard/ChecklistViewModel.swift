import Foundation
import Observation

// MARK: - ChecklistItem

public struct ChecklistItem: Codable, Identifiable {
    public var id: UUID
    public var title: String
    public var isChecked: Bool

    public init(id: UUID = UUID(), title: String, isChecked: Bool = false) {
        self.id = id
        self.title = title
        self.isChecked = isChecked
    }
}

// MARK: - ChecklistViewModel

@Observable
public final class ChecklistViewModel {

    public private(set) var items: [ChecklistItem]

    private let defaults: UserDefaults
    private let storageKey = "fmsys.dailyChecklist"

    private static let defaultItems: [ChecklistItem] = [
        ChecklistItem(title: "Pre-market prep finished"),
        ChecklistItem(title: "Economic calendar checked"),
        ChecklistItem(title: "Identify key HTF levels")
    ]

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: "fmsys.dailyChecklist"),
           let decoded = try? JSONDecoder().decode([ChecklistItem].self, from: data),
           !decoded.isEmpty {
            self.items = decoded
        } else {
            self.items = Self.defaultItems
        }
    }

    public func add(title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        items.append(ChecklistItem(title: trimmed))
        persist()
    }

    public func toggle(id: UUID) {
        guard let idx = items.firstIndex(where: { $0.id == id }) else { return }
        items[idx].isChecked.toggle()
        persist()
    }

    public func delete(id: UUID) {
        items.removeAll { $0.id == id }
        persist()
    }

    public func rename(id: UUID, title: String) {
        guard let idx = items.firstIndex(where: { $0.id == id }) else { return }
        items[idx].title = title
        persist()
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(items) else { return }
        defaults.set(data, forKey: storageKey)
    }
}
