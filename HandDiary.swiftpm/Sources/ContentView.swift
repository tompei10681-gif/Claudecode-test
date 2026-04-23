import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: DiaryStore
    @State private var selectedEntry: DiaryEntry?
    @State private var selectedDate: Date = Date()
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView(selectedDate: $selectedDate, selectedEntry: $selectedEntry)
        } content: {
            EntryListView(date: selectedDate, selectedEntry: $selectedEntry)
        } detail: {
            if let entry = selectedEntry {
                DiaryDetailView(entry: Binding(
                    get: { entry },
                    set: { updated in
                        store.update(updated)
                        selectedEntry = updated
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
    @EnvironmentObject var store: DiaryStore

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "book.closed.fill")
                .font(.system(size: 72))
                .foregroundStyle(.tertiary)

            VStack(spacing: 8) {
                Text("てがきダイアリー")
                    .font(.title.bold())

                Text("左のカレンダーから日付を選んで\n✏️ボタンで新しいページを作成しましょう")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}
