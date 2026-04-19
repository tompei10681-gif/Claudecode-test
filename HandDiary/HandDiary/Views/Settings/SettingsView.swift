import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: DiaryStore
    @AppStorage("defaultMood") private var defaultMood = DiaryEntry.Mood.good.rawValue
    @AppStorage("defaultWeather") private var defaultWeather = DiaryEntry.Weather.sunny.rawValue
    @AppStorage("defaultBackground") private var defaultBackground = DiaryEntry.PageBackground.ruled.rawValue
    @AppStorage("accentColorName") private var accentColorName = "blue"

    @State private var showDeleteConfirm = false
    @Environment(\.dismiss) var dismiss

    private let accentOptions: [(name: String, color: Color)] = [
        ("blue", .blue), ("indigo", .indigo), ("purple", .purple),
        ("pink", .pink), ("red", .red), ("orange", .orange),
        ("green", .green), ("teal", .teal)
    ]

    var body: some View {
        NavigationView {
            List {
                // Default values
                Section("デフォルト設定") {
                    Picker("気分", selection: $defaultMood) {
                        ForEach(DiaryEntry.Mood.allCases, id: \.rawValue) { mood in
                            Text("\(mood.emoji) \(mood.label)").tag(mood.rawValue)
                        }
                    }

                    Picker("天気", selection: $defaultWeather) {
                        ForEach(DiaryEntry.Weather.allCases, id: \.rawValue) { w in
                            Label(w.label, systemImage: w.icon).tag(w.rawValue)
                        }
                    }

                    Picker("ページ背景", selection: $defaultBackground) {
                        ForEach(DiaryEntry.PageBackground.allCases, id: \.rawValue) { bg in
                            Label(bg.label, systemImage: bg.icon).tag(bg.rawValue)
                        }
                    }
                }

                // Statistics
                Section("統計") {
                    LabeledContent("総エントリ数", value: "\(store.entries.count) 件")
                    LabeledContent("タグ数", value: "\(store.allTags.count) 個")

                    if let earliest = store.entries.last {
                        LabeledContent("最初のエントリ", value: earliest.shortDate)
                    }
                }

                // Danger zone
                Section {
                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        Label("すべての日記を削除", systemImage: "trash")
                    }
                } footer: {
                    Text("この操作は元に戻せません。")
                }
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
            .confirmationDialog(
                "すべての日記を削除しますか？",
                isPresented: $showDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button("すべて削除", role: .destructive) {
                    store.entries.removeAll()
                }
            } message: {
                Text("この操作は元に戻せません。")
            }
        }
    }
}
