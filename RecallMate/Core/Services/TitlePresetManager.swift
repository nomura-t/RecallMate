// TitlePresetManager.swift - タイトルプリセット管理（UserDefaults）
import Foundation
import SwiftUI

class TitlePresetManager: ObservableObject {
    static let shared = TitlePresetManager()

    private let key = "titlePresets"
    private let maxPresets = 20

    @Published var presets: [String] {
        didSet {
            save()
        }
    }

    private init() {
        self.presets = UserDefaults.standard.stringArray(forKey: key) ?? []
    }

    func addPreset(_ title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !presets.contains(trimmed) else { return }
        if presets.count >= maxPresets {
            presets.removeLast()
        }
        presets.insert(trimmed, at: 0)
    }

    func removePreset(at index: Int) {
        guard presets.indices.contains(index) else { return }
        presets.remove(at: index)
    }

    func removePreset(_ title: String) {
        presets.removeAll { $0 == title }
    }

    func reorderPreset(from source: IndexSet, to destination: Int) {
        presets.move(fromOffsets: source, toOffset: destination)
    }

    private func save() {
        UserDefaults.standard.set(presets, forKey: key)
    }
}
