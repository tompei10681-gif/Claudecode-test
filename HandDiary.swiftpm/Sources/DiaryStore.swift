import Foundation
import Combine

class DiaryStore: ObservableObject {
    @Published var entries: [DiaryEntry] = []
    @Published var allTags: [String] = []

    private let saveKey = "diary_entries_v1"
    private var cancellables = Set<AnyCancellable>()

    init() {
        load()
        $entries
            .map { Array(Set($0.flatMap { $0.tags })).sorted() }
            .assign(to: \.allTags, on: self)
            .store(in: &cancellables)
    }

    @discardableResult
    func createEntry(for date: Date) -> DiaryEntry {
        let cal = Calendar.current
        if let existing = entries.first(where: { cal.isDate($0.date, inSameDayAs: date) }) {
            return existing
        }
        let entry = DiaryEntry.new(for: date)
        entries.insert(entry, at: 0)
        entries.sort { $0.date > $1.date }
        save()
        return entry
    }

    func update(_ entry: DiaryEntry) {
        if let idx = entries.firstIndex(where: { $0.id == entry.id }) {
            var e = entry; e.updatedAt = Date()
            entries[idx] = e
        } else {
            entries.append(entry)
            entries.sort { $0.date > $1.date }
        }
        save()
    }

    func delete(_ entry: DiaryEntry) {
        entries.removeAll { $0.id == entry.id }
        save()
    }

    func delete(at offsets: IndexSet, in list: [DiaryEntry]) {
        let ids = offsets.map { list[$0].id }
        entries.removeAll { ids.contains($0.id) }
        save()
    }

    func entries(for date: Date) -> [DiaryEntry] {
        let cal = Calendar.current
        return entries
            .filter { cal.isDate($0.date, inSameDayAs: date) }
            .sorted { $0.createdAt < $1.createdAt }
    }

    func entries(for month: Date) -> [DiaryEntry] {
        let cal = Calendar.current
        let mc = cal.dateComponents([.year, .month], from: month)
        return entries.filter {
            let c = cal.dateComponents([.year, .month], from: $0.date)
            return c.year == mc.year && c.month == mc.month
        }
    }

    func hasEntry(on date: Date) -> Bool {
        entries.contains { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }

    func search(query: String) -> [DiaryEntry] {
        guard !query.isEmpty else { return entries }
        let q = query.lowercased()
        return entries.filter {
            $0.title.lowercased().contains(q) ||
            $0.typedText.lowercased().contains(q) ||
            $0.tags.contains { $0.lowercased().contains(q) }
        }
    }

    func exportText(for entry: DiaryEntry) -> String {
        var lines = ["【\(entry.formattedDate)】"]
        if !entry.title.isEmpty { lines.append("タイトル: \(entry.title)") }
        lines.append("気分: \(entry.mood.emoji) \(entry.mood.label)")
        lines.append("天気: \(entry.weather.label)")
        if !entry.tags.isEmpty { lines.append("タグ: \(entry.tags.joined(separator: ", "))") }
        lines.append("")
        lines.append(entry.typedText)
        return lines.joined(separator: "\n")
    }

    private func save() {
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: saveKey)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: saveKey),
              let decoded = try? JSONDecoder().decode([DiaryEntry].self, from: data)
        else { return }
        entries = decoded.sorted { $0.date > $1.date }
    }
}
