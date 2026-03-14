import Foundation
import Testing
@testable import FMSYSCore

extension FMSYSTests {
    @Suite
    struct ChecklistViewModelTests {

        private func makeDefaults() -> UserDefaults {
            UserDefaults(suiteName: "test.checklist.\(UUID().uuidString)")!
        }

        @Test func defaultItemsSeededOnFirstLaunch() {
            let sut = ChecklistViewModel(defaults: makeDefaults())
            #expect(sut.items.count == 3)
            #expect(sut.items[0].title == "Pre-market prep finished")
            #expect(sut.items[1].title == "Economic calendar checked")
            #expect(sut.items[2].title == "Identify key HTF levels")
            #expect(sut.items.allSatisfy { !$0.isChecked })
        }

        @Test func addItemAppendsToList() {
            let sut = ChecklistViewModel(defaults: makeDefaults())
            sut.add(title: "Review trade plan")
            #expect(sut.items.count == 4)
            #expect(sut.items.last?.title == "Review trade plan")
        }

        @Test func toggleFlipsIsChecked() {
            let sut = ChecklistViewModel(defaults: makeDefaults())
            let id = sut.items[0].id
            sut.toggle(id: id)
            #expect(sut.items[0].isChecked == true)
            sut.toggle(id: id)
            #expect(sut.items[0].isChecked == false)
        }

        @Test func deleteRemovesItem() {
            let sut = ChecklistViewModel(defaults: makeDefaults())
            let id = sut.items[1].id
            sut.delete(id: id)
            #expect(sut.items.count == 2)
            #expect(sut.items.allSatisfy { $0.id != id })
        }

        @Test func renameUpdatesTitle() {
            let sut = ChecklistViewModel(defaults: makeDefaults())
            let id = sut.items[0].id
            sut.rename(id: id, title: "Updated title")
            #expect(sut.items[0].title == "Updated title")
        }

        @Test func persistsAcrossInstances() {
            let sharedDefaults = UserDefaults(suiteName: "test.checklist.persist.\(UUID().uuidString)")!
            let sut1 = ChecklistViewModel(defaults: sharedDefaults)
            sut1.add(title: "Persisted item")
            sut1.toggle(id: sut1.items[0].id)

            let sut2 = ChecklistViewModel(defaults: sharedDefaults)
            #expect(sut2.items.count == 4)
            #expect(sut2.items.last?.title == "Persisted item")
            #expect(sut2.items[0].isChecked == true)
        }

        @Test func renameWithBlankTitleIsIgnored() {
            let sut = ChecklistViewModel(defaults: makeDefaults())
            let originalTitle = sut.items[0].title
            sut.rename(id: sut.items[0].id, title: "   ")
            #expect(sut.items[0].title == originalTitle)
        }

        @Test func addEmptyTitleIsIgnored() {
            let sut = ChecklistViewModel(defaults: makeDefaults())
            sut.add(title: "")
            sut.add(title: "   ")
            #expect(sut.items.count == 3)
        }
    }
}
