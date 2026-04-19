import SwiftUI
import PencilKit

struct DiaryDetailView: View {
    @EnvironmentObject var store: DiaryStore
    @Binding var entry: DiaryEntry

    @State private var editMode: EditMode = .typing
    @State private var showTagEditor = false
    @State private var showExportSheet = false
    @State private var exportText = ""
    @State private var showClearConfirm = false
    @State private var showBackgroundPicker = false

    enum EditMode { case typing, drawing, readonly }

    var body: some View {
        VStack(spacing: 0) {
            // Header metadata bar
            MetadataBar(entry: $entry)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(.secondarySystemGroupedBackground))

            Divider()

            // Title field
            TextField("タイトルを入力（任意）", text: $entry.title)
                .font(.title2.weight(.semibold))
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 8)
                .onChange(of: entry.title) { _ in save() }

            // Mode tabs
            Picker("入力モード", selection: $editMode) {
                Label("文字入力", systemImage: "keyboard").tag(EditMode.typing)
                Label("手書き", systemImage: "pencil.tip").tag(EditMode.drawing)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.bottom, 8)

            // Content area
            ZStack(alignment: .topLeading) {
                // Page background
                PageRulingView(background: entry.pageBackground)
                    .clipped()

                switch editMode {
                case .typing:
                    TextEditor(text: $entry.typedText)
                        .font(.body)
                        .padding(.horizontal, 16)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                        .onChange(of: entry.typedText) { _ in save() }

                case .drawing:
                    HandwritingCanvasView(
                        drawingData: $entry.drawingData,
                        background: entry.pageBackground,
                        isEditable: true
                    )
                    .onChange(of: entry.drawingData) { _ in save() }

                case .readonly:
                    ScrollView {
                        Text(entry.typedText)
                            .font(.body)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(16)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground))
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                // Background picker
                Menu {
                    ForEach(DiaryEntry.PageBackground.allCases, id: \.self) { bg in
                        Button {
                            entry.pageBackground = bg
                            save()
                        } label: {
                            Label(bg.label, systemImage: bg.icon)
                        }
                    }
                } label: {
                    Image(systemName: "doc.text")
                }

                // Tag editor
                Button {
                    showTagEditor = true
                } label: {
                    Image(systemName: "tag")
                }

                // Export / share
                Menu {
                    Button {
                        exportText = store.exportText(for: entry)
                        showExportSheet = true
                    } label: {
                        Label("テキストを共有", systemImage: "square.and.arrow.up")
                    }

                    Divider()

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
                save()
            }
        }
        .sheet(isPresented: $showExportSheet) {
            ShareSheet(text: exportText)
        }
        .confirmationDialog("手書きをすべて削除しますか？", isPresented: $showClearConfirm, titleVisibility: .visible) {
            Button("削除", role: .destructive) {
                entry.drawingData = nil
                save()
            }
        }
    }

    private func save() {
        store.update(entry)
    }
}

// MARK: - Metadata bar (mood + weather picker)

struct MetadataBar: View {
    @Binding var entry: DiaryEntry

    var body: some View {
        HStack(spacing: 16) {
            Text(entry.formattedDate)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            // Mood picker
            Menu {
                ForEach(DiaryEntry.Mood.allCases, id: \.self) { mood in
                    Button {
                        entry.mood = mood
                    } label: {
                        Text("\(mood.emoji) \(mood.label)")
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(entry.mood.emoji)
                    Text(entry.mood.label)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color(.systemGray5))
                .clipShape(Capsule())
            }

            // Weather picker
            Menu {
                ForEach(DiaryEntry.Weather.allCases, id: \.self) { weather in
                    Button {
                        entry.weather = weather
                    } label: {
                        Label(weather.label, systemImage: weather.icon)
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: entry.weather.icon)
                    Text(entry.weather.label)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color(.systemGray5))
                .clipShape(Capsule())
            }
        }
    }
}
