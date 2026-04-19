import SwiftUI

@main
struct HandDiaryApp: App {
    @StateObject private var store = DiaryStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("新しい日記エントリ") {
                    store.createEntry(for: Date())
                }
                .keyboardShortcut("n", modifiers: .command)
            }
        }
    }
}
