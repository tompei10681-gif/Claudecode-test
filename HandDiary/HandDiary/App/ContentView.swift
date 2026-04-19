import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: DiaryStore
    @State private var selectedEntry: DiaryEntry?
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var selectedDate: Date = Date()

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView(selectedDate: $selectedDate, selectedEntry: $selectedEntry)
        } content: {
            EntryListView(date: selectedDate, selectedEntry: $selectedEntry)
        } detail: {
            if let entry = selectedEntry {
                DiaryDetailView(entry: Binding(
                    get: { entry },
                    set: { newEntry in
                        store.update(newEntry)
                        selectedEntry = newEntry
                    }
                ))
            } else {
                EmptyDetailView()
            }
        }
        .navigationSplitViewStyle(.balanced)
    }
}

struct EmptyDetailView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "book.closed.fill")
                .font(.system(size: 80))
                .foregroundStyle(.tertiary)

            VStack(spacing: 8) {
                Text("日記を選択してください")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)

                Text("左側のリストからエントリを選ぶか、\n＋ボタンで新しいページを追加しましょう")
                    .font(.body)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}
