import SwiftUI

@main
struct HandDiaryApp: App {
    @StateObject private var store = DiaryStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
    }
}
