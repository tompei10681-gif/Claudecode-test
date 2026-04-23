import SwiftUI

struct EntryListView: View {
    @EnvironmentObject var store: DiaryStore
    let date: Date
    @Binding var selectedEntry: DiaryEntry?

    var entries: [DiaryEntry] { store.entries(for: date) }

    var body: some View {
        Group {
            if entries.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "book.pages")
                        .font(.system(size: 56))
                        .foregroundStyle(.tertiary)

                    VStack(spacing: 6) {
                        Text(formattedDate)
                            .font(.headline).foregroundStyle(.secondary)
                        Text("この日の日記はありません")
                            .font(.subheadline).foregroundStyle(.tertiary)
                    }

                    Button {
                        selectedEntry = store.createEntry(for: date)
                    } label: {
                        Label("新しい日記を書く", systemImage: "plus.circle.fill")
                            .font(.headline)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemGroupedBackground))
            } else {
                List(entries, id: \.id, selection: $selectedEntry) { entry in
                    EntryCardRow(entry: entry).tag(entry)
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle(formattedDate)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    selectedEntry = store.createEntry(for: date)
                } label: {
                    Image(systemName: "square.and.pencil")
                }
            }
        }
    }

    private var formattedDate: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ja_JP")
        f.dateFormat = "M月d日（E）"
        return f.string(from: date)
    }
}

struct EntryCardRow: View {
    let entry: DiaryEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(entry.mood.emoji).font(.title2)
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.title.isEmpty ? "タイトルなし" : entry.title)
                        .font(.headline)
                        .foregroundStyle(entry.title.isEmpty ? .tertiary : .primary)
                    HStack(spacing: 6) {
                        Label(entry.weather.label, systemImage: entry.weather.icon)
                            .font(.caption).foregroundStyle(.secondary)
                        Text("·").foregroundStyle(.tertiary)
                        Text(timeString).font(.caption).foregroundStyle(.secondary)
                    }
                }
                Spacer()
                if entry.drawingData != nil {
                    Image(systemName: "pencil.tip")
                        .font(.caption).foregroundStyle(.accentColor)
                }
            }

            if !entry.typedText.isEmpty {
                Text(entry.typedText)
                    .font(.subheadline).foregroundStyle(.secondary).lineLimit(3)
            }

            if !entry.tags.isEmpty {
                HStack(spacing: 4) {
                    ForEach(entry.tags, id: \.self) { tag in
                        Text("#\(tag)")
                            .font(.caption2)
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(Color.accentColor.opacity(0.12))
                            .foregroundStyle(.accentColor)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(.vertical, 6)
    }

    private var timeString: String {
        let f = DateFormatter()
        f.timeStyle = .short
        f.locale = Locale(identifier: "ja_JP")
        return f.string(from: entry.createdAt)
    }
}
