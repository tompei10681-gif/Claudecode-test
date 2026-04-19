import Foundation
import Combine
import SwiftUI

class DiaryStore: ObservableObject {
    @Published var entries: [DiaryEntry] = []
    @Published var allTags: [String] = []

    private let saveKey = "diary_entries_v1"
    private var cancellables = Set<AnyCancellable>()

    init() {
        load()
        $entries
            .map { entries in
                Array(Set(entries.flatMap { $0.tags })).sorted()
            }
            .assign(to: \.allTags, on: self)
            .store(in: &cancellables)
    }

    // MARK: - CRUD

    @discardableResult
    func createEntry(for date: Date) -> DiaryEntry {
        let calendar = Calendar.current
        if let existing = entries.first(where: {
            calendar.isDate($0.date, inSameDayAs: date)
        }) {
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
            var updated = entry
            updated.updatedAt = Date()
            entries[idx] = updated
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

    func delete(at offsets: IndexSet, in dayEntries: [DiaryEntry]) {
        let idsToDelete = offsets.map { dayEntries[$0].id }
        entries.removeAll { idsToDelete.contains($0.id) }
        save()
    }

    // MARK: - Queries

    func entries(for date: Date) -> [DiaryEntry] {
        let cal = Calendar.current
        return entries.filter { cal.isDate($0.date, inSameDayAs: date) }
            .sorted { $0.createdAt < $1.createdAt }
    }

    func entries(for month: Date) -> [DiaryEntry] {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month], from: month)
        return entries.filter {
            let c = cal.dateComponents([.year, .month], from: $0.date)
            return c.year == comps.year && c.month == comps.month
        }
    }

    func hasEntry(on date: Date) -> Bool {
        let cal = Calendar.current
        return entries.contains { cal.isDate($0.date, inSameDayAs: date) }
    }

    func search(query: String) -> [DiaryEntry] {
        guard !query.isEmpty else { return entries }
        let q = query.lowercased()
        return entries.filter {
            $0.title.lowercased().contains(q) ||
            $0.typedText.lowercased().contains(q) ||
            $0.tags.contains(where: { $0.lowercased().contains(q) })
        }
    }

    func entries(withTag tag: String) -> [DiaryEntry] {
        entries.filter { $0.tags.contains(tag) }
    }

    // MARK: - Persistence

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

    // MARK: - Export

    func exportText(for entry: DiaryEntry) -> String {
        var lines: [String] = []
        lines.append("【\(entry.formattedDate)】")
        if !entry.title.isEmpty { lines.append("タイトル: \(entry.title)") }
        lines.append("気分: \(entry.mood.emoji) \(entry.mood.label)")
        lines.append("天気: \(entry.weather.label)")
        if !entry.tags.isEmpty { lines.append("タグ: \(entry.tags.joined(separator: ", "))") }
        lines.append("")
        lines.append(entry.typedText)
        return lines.joined(separator: "\n")
    }
}
