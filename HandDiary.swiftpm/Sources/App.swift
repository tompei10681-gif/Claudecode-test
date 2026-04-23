import SwiftUI
import PencilKit

// MARK: - Model

struct DiaryEntry: Identifiable, Codable, Hashable {
    var id = UUID()
    var date: Date
    var title: String = ""
    var text: String = ""
    var drawingData: Data? = nil
    var mood: Mood = .good
    var weather: Weather = .sunny
    var tags: [String] = []
    var createdAt: Date = Date()

    enum Mood: String, Codable, CaseIterable {
        case great, good, neutral, bad, terrible
        var emoji: String {
            switch self {
            case .great: return "😄"
            case .good: return "🙂"
            case .neutral: return "😐"
            case .bad: return "😔"
            case .terrible: return "😢"
            }
        }
        var label: String {
            switch self {
            case .great: return "最高"
            case .good: return "良い"
            case .neutral: return "普通"
            case .bad: return "悪い"
            case .terrible: return "最悪"
            }
        }
    }

    enum Weather: String, Codable, CaseIterable {
        case sunny, cloudy, rainy, snowy, windy
        var icon: String {
            switch self {
            case .sunny:  return "sun.max.fill"
            case .cloudy: return "cloud.fill"
            case .rainy:  return "cloud.rain.fill"
            case .snowy:  return "snowflake"
            case .windy:  return "wind"
            }
        }
        var label: String {
            switch self {
            case .sunny:  return "晴れ"
            case .cloudy: return "曇り"
            case .rainy:  return "雨"
            case .snowy:  return "雪"
            case .windy:  return "風"
            }
        }
    }

    var dateLabel: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ja_JP")
        f.dateFormat = "yyyy年M月d日（E）"
        return f.string(from: date)
    }
}

// MARK: - Store

final class DiaryStore: ObservableObject {
    @Published var entries: [DiaryEntry] = []

    private let key = "diary_v1"

    init() { load() }

    var tags: [String] { Array(Set(entries.flatMap { $0.tags })).sorted() }

    func save(_ entry: DiaryEntry) {
        if let i = entries.firstIndex(where: { $0.id == entry.id }) {
            entries[i] = entry
        } else {
            entries.append(entry)
            entries.sort { $0.date > $1.date }
        }
        persist()
    }

    func delete(_ entry: DiaryEntry) {
        entries.removeAll { $0.id == entry.id }
        persist()
    }

    func entries(for date: Date) -> [DiaryEntry] {
        entries.filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }

    func hasEntry(on date: Date) -> Bool {
        entries.contains { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }

    func search(_ q: String) -> [DiaryEntry] {
        guard !q.isEmpty else { return entries }
        let l = q.lowercased()
        return entries.filter {
            $0.title.lowercased().contains(l) ||
            $0.text.lowercased().contains(l) ||
            $0.tags.contains { $0.lowercased().contains(l) }
        }
    }

    private func persist() {
        if let d = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(d, forKey: key)
        }
    }
    private func load() {
        guard let d = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([DiaryEntry].self, from: d)
        else { return }
        entries = decoded.sorted { $0.date > $1.date }
    }
}

// MARK: - PencilKit canvas

struct CanvasView: UIViewRepresentable {
    @Binding var data: Data?
    let editable: Bool

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> PKCanvasView {
        let cv = PKCanvasView()
        cv.delegate = context.coordinator
        cv.drawingPolicy = .anyInput
        cv.backgroundColor = .clear
        cv.isOpaque = false
        if let d = data, let drawing = try? PKDrawing(data: d) {
            cv.drawing = drawing
        }
        if editable {
            let picker = PKToolPicker()
            context.coordinator.picker = picker
            picker.addObserver(cv)
            DispatchQueue.main.async {
                picker.setVisible(true, forFirstResponder: cv)
                cv.becomeFirstResponder()
            }
        }
        return cv
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        uiView.isUserInteractionEnabled = editable
    }

    class Coordinator: NSObject, PKCanvasViewDelegate {
        var parent: CanvasView
        var picker: PKToolPicker?
        init(_ p: CanvasView) { parent = p }
        func canvasViewDrawingDidChange(_ cv: PKCanvasView) {
            let d = cv.drawing.dataRepresentation()
            DispatchQueue.main.async { self.parent.data = d }
        }
    }
}

// MARK: - Ruling background

struct RulingView: View {
    enum Style { case plain, ruled, grid }
    let style: Style

    var body: some View {
        Canvas { ctx, size in
            let c = Color(.systemGray5)
            switch style {
            case .plain:
                break
            case .ruled:
                var i = 0
                while CGFloat(i) * 36 + 36 < size.height {
                    let y = CGFloat(i) * 36 + 36
                    var p = Path()
                    p.move(to: CGPoint(x: 16, y: y))
                    p.addLine(to: CGPoint(x: size.width - 16, y: y))
                    ctx.stroke(p, with: .color(c), lineWidth: 0.7)
                    i += 1
                }
            case .grid:
                let sp: CGFloat = 28
                var xi = 0
                while CGFloat(xi) * sp < size.width {
                    var p = Path()
                    p.move(to: CGPoint(x: CGFloat(xi) * sp, y: 0))
                    p.addLine(to: CGPoint(x: CGFloat(xi) * sp, y: size.height))
                    ctx.stroke(p, with: .color(c), lineWidth: 0.5)
                    xi += 1
                }
                var yi = 0
                while CGFloat(yi) * sp < size.height {
                    var p = Path()
                    p.move(to: CGPoint(x: 0, y: CGFloat(yi) * sp))
                    p.addLine(to: CGPoint(x: size.width, y: CGFloat(yi) * sp))
                    ctx.stroke(p, with: .color(c), lineWidth: 0.5)
                    yi += 1
                }
            }
        }
    }
}

// MARK: - Mini calendar

struct MiniCalendar: View {
    @Binding var month: Date
    @Binding var selected: Date
    let marked: Set<String>   // "yyyy-MM-dd" strings

    private let cal = Calendar.current
    private let days = ["日","月","火","水","木","金","土"]
    private let cols = Array(repeating: GridItem(.flexible()), count: 7)

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Button { shift(-1) } label: { Image(systemName: "chevron.left") }
                    .buttonStyle(.plain)
                Spacer()
                Text(title).font(.subheadline.weight(.semibold))
                Spacer()
                Button { shift(1) } label: { Image(systemName: "chevron.right") }
                    .buttonStyle(.plain)
            }
            LazyVGrid(columns: cols, spacing: 0) {
                ForEach(days.indices, id: \.self) { i in
                    Text(days[i]).font(.caption2)
                        .foregroundStyle(i == 0 ? Color.red : i == 6 ? Color.blue : Color.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            LazyVGrid(columns: cols, spacing: 2) {
                ForEach(cells, id: \.self) { item in
                    if item.isEmpty {
                        Color.clear.frame(height: 30)
                    } else {
                        let date = dateFrom(item)
                        let isSel = cal.isDate(date, inSameDayAs: selected)
                        let isToday = cal.isDateInToday(date)
                        let hasMark = marked.contains(item)
                        let wd = cal.component(.weekday, from: date)
                        Button { selected = date } label: {
                            VStack(spacing: 1) {
                                Text("\(cal.component(.day, from: date))")
                                    .font(.caption2.weight(isSel || isToday ? .bold : .regular))
                                    .foregroundStyle(
                                        isSel ? Color.white :
                                        isToday ? Color.accentColor :
                                        wd == 1 ? Color.red :
                                        wd == 7 ? Color.blue : Color.primary
                                    )
                                    .frame(width: 26, height: 26)
                                    .background(
                                        isSel ? Color.accentColor :
                                        isToday ? Color.accentColor.opacity(0.15) :
                                        Color.clear
                                    )
                                    .clipShape(Circle())
                                Circle().fill(hasMark ? Color.accentColor : Color.clear)
                                    .frame(width: 4, height: 4)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(10)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var title: String {
        let f = DateFormatter(); f.locale = Locale(identifier: "ja_JP"); f.dateFormat = "yyyy年M月"
        return f.string(from: month)
    }

    private var cells: [String] {
        guard let range = cal.range(of: .day, in: .month, for: month),
              let first = cal.date(from: cal.dateComponents([.year,.month], from: month))
        else { return [] }
        let offset = cal.component(.weekday, from: first) - 1
        var result = Array(repeating: "", count: offset)
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        for d in range {
            if let date = cal.date(byAdding: .day, value: d - 1, to: first) {
                result.append(f.string(from: date))
            }
        }
        while result.count % 7 != 0 { result.append("") }
        return result
    }

    private func dateFrom(_ s: String) -> Date {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        return f.date(from: s) ?? Date()
    }

    private func shift(_ v: Int) {
        month = cal.date(byAdding: .month, value: v, to: month) ?? month
    }
}

// MARK: - Entry row

struct EntryRow: View {
    let entry: DiaryEntry
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(entry.mood.emoji)
                Text(entry.dateLabel).font(.caption).foregroundStyle(.secondary)
                Spacer()
                Image(systemName: entry.weather.icon).font(.caption).foregroundStyle(.secondary)
                if entry.drawingData != nil {
                    Image(systemName: "pencil.tip").font(.caption).foregroundStyle(.accentColor)
                }
            }
            if !entry.title.isEmpty {
                Text(entry.title).font(.headline).lineLimit(1)
            }
            if !entry.text.isEmpty {
                Text(entry.text).font(.caption).foregroundStyle(.secondary).lineLimit(2)
            }
            if !entry.tags.isEmpty {
                HStack(spacing: 4) {
                    ForEach(entry.tags.prefix(3), id: \.self) { t in
                        Text("#\(t)").font(.caption2)
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

// MARK: - Tag editor

struct TagEditor: View {
    @Binding var tags: [String]
    let suggestions: [String]
    @State private var input = ""
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            List {
                Section("このエントリのタグ") {
                    if tags.isEmpty { Text("タグなし").foregroundStyle(.tertiary) }
                    ForEach(tags, id: \.self) { t in
                        HStack {
                            Text("#\(t)")
                            Spacer()
                            Button { tags.removeAll { $0 == t } } label: {
                                Image(systemName: "minus.circle.fill").foregroundStyle(.red)
                            }.buttonStyle(.plain)
                        }
                    }
                }
                Section("追加") {
                    HStack {
                        TextField("新しいタグ", text: $input).submitLabel(.done).onSubmit(add)
                        Button(action: add) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(input.isEmpty ? Color.secondary : Color.accentColor)
                        }.disabled(input.isEmpty).buttonStyle(.plain)
                    }
                }
                let sugg = suggestions.filter { !tags.contains($0) }
                if !sugg.isEmpty {
                    Section("候補") {
                        ForEach(sugg, id: \.self) { t in
                            Button { if !tags.contains(t) { tags.append(t) } } label: {
                                HStack {
                                    Text("#\(t)").foregroundStyle(.primary)
                                    Spacer()
                                    Image(systemName: "plus.circle").foregroundStyle(.accentColor)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("タグ編集").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") { dismiss() }.fontWeight(.semibold)
                }
            }
        }
    }
    private func add() {
        let t = input.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty, !tags.contains(t) else { return }
        tags.append(t); input = ""
    }
}

// MARK: - Share sheet

struct ShareSheet: UIViewControllerRepresentable {
    let text: String
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [text], applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}

// MARK: - Detail view

struct DetailView: View {
    @EnvironmentObject var store: DiaryStore
    @Binding var entry: DiaryEntry

    @State private var mode = 0   // 0: text, 1: draw
    @State private var showTags = false
    @State private var showShare = false
    @State private var showClear = false
    @State private var ruling = 1 // 0:plain 1:ruled 2:grid

    var body: some View {
        VStack(spacing: 0) {
            // Metadata bar
            HStack(spacing: 10) {
                Text(entry.dateLabel).font(.subheadline).foregroundStyle(.secondary)
                Spacer()
                moodMenu
                weatherMenu
            }
            .padding(.horizontal, 16).padding(.vertical, 10)
            .background(Color(.secondarySystemGroupedBackground))

            Divider()

            TextField("タイトル（任意）", text: $entry.title)
                .font(.title2.weight(.semibold))
                .padding(.horizontal, 20).padding(.top, 14).padding(.bottom, 8)
                .onChange(of: entry.title) { _ in store.save(entry) }

            Picker("", selection: $mode) {
                Label("文字入力", systemImage: "keyboard").tag(0)
                Label("手書き", systemImage: "pencil.tip").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16).padding(.bottom, 8)

            ZStack {
                let style: RulingView.Style = ruling == 0 ? .plain : ruling == 1 ? .ruled : .grid
                RulingView(style: style)

                if mode == 0 {
                    TextEditor(text: $entry.text)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                        .padding(.horizontal, 12)
                        .onChange(of: entry.text) { _ in store.save(entry) }
                } else {
                    CanvasView(data: $entry.drawingData, editable: true)
                        .onChange(of: entry.drawingData) { _ in store.save(entry) }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground))
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Menu {
                    Button { ruling = 0 } label: { Label("白紙", systemImage: "square") }
                    Button { ruling = 1 } label: { Label("横罫線", systemImage: "line.3.horizontal") }
                    Button { ruling = 2 } label: { Label("方眼", systemImage: "grid") }
                } label: { Image(systemName: "doc.text") }

                Button { showTags = true } label: { Image(systemName: "tag") }

                Menu {
                    Button { showShare = true } label: {
                        Label("テキストを共有", systemImage: "square.and.arrow.up")
                    }
                    Button(role: .destructive) { showClear = true } label: {
                        Label("手書きをクリア", systemImage: "trash")
                    }
                } label: { Image(systemName: "ellipsis.circle") }
            }
        }
        .sheet(isPresented: $showTags) {
            TagEditor(tags: $entry.tags, suggestions: store.tags)
                .onDisappear { store.save(entry) }
        }
        .sheet(isPresented: $showShare) {
            ShareSheet(text: exportText)
        }
        .confirmationDialog("手書きをすべて削除しますか？", isPresented: $showClear, titleVisibility: .visible) {
            Button("削除", role: .destructive) { entry.drawingData = nil; store.save(entry) }
        }
    }

    private var exportText: String {
        "【\(entry.dateLabel)】\n気分:\(entry.mood.label) 天気:\(entry.weather.label)\n\n\(entry.text)"
    }

    private var moodMenu: some View {
        Menu {
            ForEach(DiaryEntry.Mood.allCases, id: \.self) { m in
                Button { entry.mood = m; store.save(entry) } label: {
                    Text("\(m.emoji) \(m.label)")
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(entry.mood.emoji)
                Text(entry.mood.label).font(.caption).foregroundStyle(.secondary)
            }
            .padding(.horizontal, 10).padding(.vertical, 5)
            .background(Color(.systemGray5)).clipShape(Capsule())
        }
    }

    private var weatherMenu: some View {
        Menu {
            ForEach(DiaryEntry.Weather.allCases, id: \.self) { w in
                Button { entry.weather = w; store.save(entry) } label: {
                    Label(w.label, systemImage: w.icon)
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: entry.weather.icon)
                Text(entry.weather.label).font(.caption).foregroundStyle(.secondary)
            }
            .padding(.horizontal, 10).padding(.vertical, 5)
            .background(Color(.systemGray5)).clipShape(Capsule())
        }
    }
}

// MARK: - Main list / sidebar

struct MainView: View {
    @EnvironmentObject var store: DiaryStore
    @State private var selected: DiaryEntry? = nil
    @State private var selectedDate = Date()
    @State private var month = Date()
    @State private var search = ""
    @State private var filterTag: String? = nil

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            if let e = selected {
                DetailView(entry: Binding(
                    get: { e },
                    set: { updated in store.save(updated); selected = updated }
                ))
            } else {
                emptyDetail
            }
        }
    }

    private var markedDates: Set<String> {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        let cal = Calendar.current
        let mc = cal.dateComponents([.year, .month], from: month)
        return Set(store.entries.filter {
            let ec = cal.dateComponents([.year, .month], from: $0.date)
            return ec.year == mc.year && ec.month == mc.month
        }.map { df.string(from: $0.date) })
    }

    private var sidebar: some View {
        List(selection: $selected) {
            Section {
                MiniCalendar(
                    month: $month,
                    selected: $selectedDate,
                    marked: markedDates
                )
                .listRowInsets(EdgeInsets(top: 6, leading: 6, bottom: 6, trailing: 6))
                .listRowBackground(Color.clear)
            }

            if !store.tags.isEmpty {
                Section("タグ") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            chipButton(label: "すべて", active: filterTag == nil) { filterTag = nil }
                            ForEach(store.tags, id: \.self) { t in
                                chipButton(label: "#\(t)", active: filterTag == t) {
                                    filterTag = filterTag == t ? nil : t
                                }
                            }
                        }.padding(.horizontal, 4)
                    }
                    .listRowInsets(EdgeInsets(top: 4, leading: 6, bottom: 4, trailing: 6))
                    .listRowBackground(Color.clear)
                }
            }

            let list = filteredEntries
            if list.isEmpty {
                Text("エントリがありません").foregroundStyle(.tertiary).listRowBackground(Color.clear)
            } else {
                ForEach(groupKeys, id: \.self) { k in
                    Section(k) {
                        ForEach(grouped[k] ?? []) { e in
                            EntryRow(entry: e).tag(e)
                        }
                        .onDelete { offs in
                            (grouped[k] ?? []).enumerated().forEach { i, e in
                                if offs.contains(i) { store.delete(e) }
                            }
                            if let s = selected, !store.entries.contains(where: { $0.id == s.id }) {
                                selected = nil
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .searchable(text: $search, prompt: "検索")
        .navigationTitle("てがきダイアリー")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    var e = DiaryEntry(date: selectedDate)
                    store.save(e)
                    selected = store.entries.first { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) && $0.id == e.id }
                    ?? store.entries.first
                } label: { Image(systemName: "square.and.pencil") }
            }
        }
    }

    private var emptyDetail: some View {
        VStack(spacing: 20) {
            Image(systemName: "book.closed.fill").font(.system(size: 72)).foregroundStyle(.tertiary)
            VStack(spacing: 6) {
                Text("てがきダイアリー").font(.title.bold())
                Text("左のカレンダーから日付を選んで\n✏️ボタンで新しいページを作成").font(.subheadline)
                    .foregroundStyle(.secondary).multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }

    private var filteredEntries: [DiaryEntry] {
        var base = search.isEmpty ? store.entries : store.search(search)
        if let t = filterTag { base = base.filter { $0.tags.contains(t) } }
        return base
    }

    private var grouped: [String: [DiaryEntry]] {
        let f = DateFormatter(); f.locale = Locale(identifier: "ja_JP"); f.dateFormat = "yyyy年M月"
        return Dictionary(grouping: filteredEntries) { f.string(from: $0.date) }
    }

    private var groupKeys: [String] { grouped.keys.sorted(by: >) }

    private func chipButton(label: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label).font(.caption).fontWeight(active ? .semibold : .regular)
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(active ? Color.accentColor : Color(.systemGray5))
                .foregroundStyle(active ? Color.white : Color.primary)
                .clipShape(Capsule())
        }.buttonStyle(.plain)
    }
}

// MARK: - App entry point

@main
struct HandDiaryApp: App {
    @StateObject private var store = DiaryStore()
    var body: some Scene {
        WindowGroup {
            MainView().environmentObject(store)
        }
    }
}
