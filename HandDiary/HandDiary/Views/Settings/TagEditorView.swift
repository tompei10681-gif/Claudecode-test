import SwiftUI

struct TagEditorView: View {
    @Binding var tags: [String]
    let allTags: [String]
    let onSave: () -> Void

    @State private var newTag = ""
    @Environment(\.dismiss) var dismiss

    var suggestedTags: [String] {
        allTags.filter { !tags.contains($0) }
    }

    var body: some View {
        NavigationView {
            List {
                // Current tags
                Section("このエントリのタグ") {
                    if tags.isEmpty {
                        Text("タグなし")
                            .foregroundStyle(.tertiary)
                    } else {
                        ForEach(tags, id: \.self) { tag in
                            HStack {
                                Text("#\(tag)")
                                Spacer()
                                Button {
                                    tags.removeAll { $0 == tag }
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundStyle(.red)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                // Add new tag
                Section("タグを追加") {
                    HStack {
                        TextField("新しいタグ名", text: $newTag)
                            .submitLabel(.done)
                            .onSubmit { addTag() }

                        Button(action: addTag) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(newTag.isEmpty ? .tertiary : .accentColor)
                        }
                        .disabled(newTag.isEmpty)
                        .buttonStyle(.plain)
                    }
                }

                // Suggested tags from existing entries
                if !suggestedTags.isEmpty {
                    Section("よく使うタグ") {
                        ForEach(suggestedTags, id: \.self) { tag in
                            Button {
                                if !tags.contains(tag) {
                                    tags.append(tag)
                                }
                            } label: {
                                HStack {
                                    Text("#\(tag)")
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    Image(systemName: "plus.circle")
                                        .foregroundStyle(.accentColor)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("タグ編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        onSave()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func addTag() {
        let trimmed = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !tags.contains(trimmed) else { return }
        tags.append(trimmed)
        newTag = ""
    }
}
