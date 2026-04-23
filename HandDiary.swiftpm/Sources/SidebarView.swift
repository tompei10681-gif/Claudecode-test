import SwiftUI

struct SidebarView: View {
    @EnvironmentObject var store: DiaryStore
    @Binding var selectedDate: Date
    @Binding var selectedEntry: DiaryEntry?

    @State private var searchQuery = ""
    @State private var selectedTag: String? = nil
    @State private var displayMonth: Date = Date()

    var body: some View {
        List(selection: $selectedEntry) {
            Section {
                MiniCalendarView(
                    displayMonth: $displayMonth,
                    selectedDate: $selectedDate,
                    markedDates: markedDates
                )
                .listRowInsets(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
                .listRowBackground(Color.clear)
            }

            if !store.allTags.isEmpty {
                Section("タグ") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            TagChip(label: "すべて", isSelected: selectedTag == nil) {
                                selectedTag = nil
                            }
                            ForEach(store.allTags, id: \.self) { tag in
                                TagChip(label: "#\(tag)", isSelected: selectedTag == tag) {
                                    selectedTag = selectedTag == tag ? nil : tag
                                }
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                    .listRowInsets(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
                    .listRowBackground(Color.clear)
                }
            }

            ForEach(groupedKeys, id: \.self) { key in
                Section(header: Text(key).font(.caption).foregroundStyle(.secondary)) {
                    ForEach(grouped[key] ?? []) { entry in
                        EntryRowView(entry: entry).tag(entry)
                    }
                    .onDelete { offsets in
                        store.delete(at: offsets, in: grouped[key] ?? [])
                        if let sel = selectedEntry,
                           !store.entries.contains(where: { $0.id == sel.id }) {
                            selectedEntry = nil
                        }
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .searchable(text: $searchQuery, prompt: "日記を検索")
        .navigationTitle("てがきダイアリー")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    let entry = store.createEntry(for: selectedDate)
                    selectedEntry = entry
                } label: {
                    Image(systemName: "square.and.pencil")
                }
            }
        }
    }

    private var filtered: [DiaryEntry] {
        var base = searchQuery.isEmpty ? store.entries : store.search(query: searchQuery)
        if let tag = selectedTag { base = base.filter { $0.tags.contains(tag) } }
        return base
    }

    private var grouped: [String: [DiaryEntry]] {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ja_JP")
        f.dateFormat = "yyyy年M月"
        return Dictionary(grouping: filtered) { f.string(from: $0.date) }
    }

    private var groupedKeys: [String] {
        grouped.keys.sorted(by: >)
    }

    private var markedDates: Set<Date> {
        let cal = Calendar.current
        return Set(store.entries(for: displayMonth).map { cal.startOfDay(for: $0.date) })
    }
}

struct EntryRowView: View {
    let entry: DiaryEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(entry.mood.emoji)
                Text(entry.formattedDate)
                    .font(.caption).foregroundStyle(.secondary)
                Spacer()
                Image(systemName: entry.weather.icon)
                    .font(.caption).foregroundStyle(.secondary)
            }
            if !entry.title.isEmpty {
                Text(entry.title).font(.headline).lineLimit(1)
            }
            if !entry.typedText.isEmpty {
                Text(entry.typedText)
                    .font(.caption).foregroundStyle(.secondary).lineLimit(2)
            }
            if !entry.tags.isEmpty {
                HStack(spacing: 4) {
                    ForEach(entry.tags.prefix(3), id: \.self) { tag in
                        Text("#\(tag)")
                            .font(.caption2)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Color.accentColor.opacity(0.15))
                            .foregroundStyle(Color.accentColor)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct TagChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(isSelected ? Color.accentColor : Color(.systemGray5))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
