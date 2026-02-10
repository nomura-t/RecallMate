// TitlePresetEditSheet.swift - プリセット管理シート
import SwiftUI

struct TitlePresetEditSheet: View {
    @ObservedObject var presetManager: TitlePresetManager
    @State private var newPresetText: String = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            List {
                Section {
                    HStack(spacing: 12) {
                        TextField("プリセット名を入力".localized, text: $newPresetText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())

                        Button(action: addPreset) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundColor(.blue)
                        }
                        .disabled(newPresetText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                } header: {
                    Text("新しいプリセット".localized)
                }

                Section {
                    if presetManager.presets.isEmpty {
                        Text("プリセットがありません".localized)
                            .foregroundColor(.secondary)
                            .font(.subheadline)
                    } else {
                        ForEach(presetManager.presets, id: \.self) { preset in
                            HStack {
                                Image(systemName: "book.fill")
                                    .foregroundColor(.blue)
                                    .font(.caption)
                                Text(preset)
                                    .font(.body)
                            }
                        }
                        .onDelete(perform: deletePresets)
                        .onMove(perform: movePresets)
                    }
                } header: {
                    Text("登録済みプリセット".localized)
                } footer: {
                    Text("最大20件まで登録できます".localized)
                        .font(.caption2)
                }
            }
            .navigationTitle("プリセット管理".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了".localized) {
                        dismiss()
                    }
                }
            }
        }
    }

    private func addPreset() {
        presetManager.addPreset(newPresetText)
        newPresetText = ""
    }

    private func deletePresets(at offsets: IndexSet) {
        for index in offsets {
            presetManager.removePreset(at: index)
        }
    }

    private func movePresets(from source: IndexSet, to destination: Int) {
        presetManager.reorderPreset(from: source, to: destination)
    }
}
