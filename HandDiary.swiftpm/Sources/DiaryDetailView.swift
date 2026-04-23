import SwiftUI

struct DiaryDetailView: View {
    @EnvironmentObject var store: DiaryStore
    @Binding var entry: DiaryEntry

    @State private var inputMode: InputMode = .typing
    @State private var showTagEditor = false
    @State private var showExportSheet = false
    @State private var exportText = ""
    @State private var showClearConfirm = false

    enum InputMode: String, CaseIterable {
        case typing = "文字入力"
        case drawing = "手書き"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Metadata bar
            MetadataBar(entry: $entry)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(.secondarySystemGroupedBackground))

            Divider()

            // Title
            TextField("タイトル（任意）", text: $entry.title)
                .font(.title2.weight(.semibold))
                .padding(.horizontal, 20)
                .padding(.top, 14)
                .padding(.bottom, 8)
                .onChange(of: entry.title) { _ in store.update(entry) }

            // Mode selector
            Picker("モード", selection: $inputMode) {
                ForEach(InputMode.allCases, id: \.self) { mode in
                    Label(mode.rawValue,
                          systemImage: mode == .typing ? "keyboard" : "pencil.tip")
                    .tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.bottom, 8)

            // Content
            ZStack(alignment: .topLeading) {
                PageRulingView(background: entry.pageBackground)

                if inputMode == .typing {
                    TextEditor(text: $entry.typedText)
                        .font(.body)
                        .scrollContentBackground(.hidden)
                        .background(.clear)
                        .padding(.horizontal, 16)
                        .onChange(of: entry.typedText) { _ in store.update(entry) }
                } else {
                    HandwritingCanvasView(drawingData: $entry.drawingData, isEditable: true)
                        .onChange(of: entry.drawingData) { _ in store.update(entry) }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground))
            .clipped()
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                // Background menu
                Menu {
                    ForEach(DiaryEntry.PageBackground.allCases, id: \.self) { bg in
                        Button {
                            entry.pageBackground = bg
                            store.update(entry)
                        } label: {
                            Label(bg.label, systemImage: bg.icon)
                        }
                    }
                } label: {
                    Image(systemName: "doc.text")
                }

                // Tag editor
                Button { showTagEditor = true } label: {
                    Image(systemName: "tag")
                }

                // More menu
                Menu {
                    Button {
                        exportText = store.exportText(for: entry)
                        showExportSheet = true
                    } label: {
                        Label("テキストを共有", systemImage: "square.and.arrow.up")
                    }

                    Button(role: .destructive) {
                        showClearConfirm = true
                    } label: {
                        Label("手書きをクリア", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showTagEditor) {
            TagEditorView(tags: $entry.tags, allTags: store.allTags) {
                store.update(entry)
            }
        }
        .sheet(isPresented: $showExportSheet) {
            ShareSheet(text: exportText)
        }
        .confirmationDialog("手書きをすべて削除しますか？",
                            isPresented: $showClearConfirm,
                            titleVisibility: .visible) {
            Button("削除", role: .destructive) {
                entry.drawingData = nil
                store.update(entry)
            }
        }
    }
}

struct MetadataBar: View {
    @Binding var entry: DiaryEntry

    var body: some View {
        HStack(spacing: 12) {
            Text(entry.formattedDate)
                .font(.subheadline).foregroundStyle(.secondary)

            Spacer()

            // Mood
            Menu {
                ForEach(DiaryEntry.Mood.allCases, id: \.self) { mood in
                    Button { entry.mood = mood } label: {
                        Text("\(mood.emoji) \(mood.label)")
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(entry.mood.emoji)
                    Text(entry.mood.label).font(.caption).foregroundStyle(.secondary)
                }
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(Color(.systemGray5)).clipShape(Capsule())
            }

            // Weather
            Menu {
                ForEach(DiaryEntry.Weather.allCases, id: \.self) { w in
                    Button { entry.weather = w } label: {
                        Label(w.label, systemImage: w.icon)
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: entry.weather.icon)
                    Text(entry.weather.label).font(.caption).foregroundStyle(.secondary)
                }
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(Color(.systemGray5)).clipShape(Capsule())
            }
        }
    }
}
