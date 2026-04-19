import SwiftUI

struct EntryListView: View {
    @EnvironmentObject var store: DiaryStore
    let date: Date
    @Binding var selectedEntry: DiaryEntry?

    var entries: [DiaryEntry] {
        store.entries(for: date)
    }

    var body: some View {
        Group {
            if entries.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "book.pages")
                        .font(.system(size: 56))
                        .foregroundStyle(.tertiary)

                    VStack(spacing: 6) {
                        Text(formattedDate)
                            .font(.headline)
                            .foregroundStyle(.secondary)

                        Text("この日の日記はありません")
                            .font(.subheadline)
                            .foregroundStyle(.tertiary)
                    }

                    Button {
                        let entry = store.createEntry(for: date)
                        selectedEntry = entry
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
                    EntryCardRow(entry: entry)
                        .tag(entry)
                }
                .listStyle(.insetGrouped)
                .navigationTitle(formattedDate)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            let entry = store.createEntry(for: date)
                            selectedEntry = entry
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
        }
        .navigationTitle(formattedDate)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    let entry = store.createEntry(for: date)
                    selectedEntry = entry
                } label: {
                    Image(systemName: "square.and.pencil")
                }
            }
        }
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M月d日（E）"
        return formatter.string(from: date)
    }
}

struct EntryCardRow: View {
    let entry: DiaryEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center) {
                Text(entry.mood.emoji)
                    .font(.title2)

                VStack(alignment: .leading, spacing: 2) {
                    if !entry.title.isEmpty {
                        Text(entry.title)
                            .font(.headline)
                    } else {
                        Text("タイトルなし")
                            .font(.headline)
                            .foregroundStyle(.tertiary)
                    }

                    HStack(spacing: 6) {
                        Label(entry.weather.label, systemImage: entry.weather.icon)
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text("·")
                            .foregroundStyle(.tertiary)

                        Text(timeString)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                if entry.drawingData != nil {
                    Image(systemName: "pencil.tip")
                        .font(.caption)
                        .foregroundStyle(Color.accentColor)
                }
            }

            if !entry.typedText.isEmpty {
                Text(entry.typedText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }

            if !entry.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(entry.tags, id: \.self) { tag in
                            Text("#\(tag)")
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.accentColor.opacity(0.12))
                                .foregroundStyle(Color.accentColor)
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
        .padding(.vertical, 6)
    }

    private var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: entry.createdAt)
    }
}
