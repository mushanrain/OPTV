import Foundation
import AppKit

final class HistoryStore: ObservableObject {
    static let shared = HistoryStore()

    @Published private(set) var items: [ClipItem] = []

    private let fm = FileManager.default
    private let baseDir: URL
    private let imagesDir: URL
    private let iconsDir: URL
    private let dataFile: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    var maxItems = 200

    private init() {
        let appSupport = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        baseDir = appSupport.appendingPathComponent("OptV", isDirectory: true)
        imagesDir = baseDir.appendingPathComponent("images", isDirectory: true)
        iconsDir = baseDir.appendingPathComponent("icons", isDirectory: true)
        dataFile = baseDir.appendingPathComponent("history.json")
        try? fm.createDirectory(at: imagesDir, withIntermediateDirectories: true)
        try? fm.createDirectory(at: iconsDir, withIntermediateDirectories: true)
        load()
    }

    private func load() {
        guard let data = try? Data(contentsOf: dataFile) else { return }
        if let arr = try? decoder.decode([ClipItem].self, from: data) {
            self.items = arr
        }
    }

    private func save() {
        while items.count > maxItems { _ = items.popLast() }
        if let data = try? encoder.encode(items) {
            try? data.write(to: dataFile)
        }
    }

    func clearAll() {
        items.removeAll()
        save()
    }

    func pushText(_ text: String) {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return }
        let id = "T:" + Digest.sha256(t)
        guard !items.contains(where: { $0.id == id }) else { return }
        var item = ClipItem(id: id, kind: Classifier.classify(text: t), text: t, imagePath: nil, ts: Date().timeIntervalSince1970, pinned: false, sourceAppName: nil, sourceBundleID: nil, sourceIconPath: nil, useCount: 0)
        enrichWithSourceInfo(&item)
        items.insert(item, at: 0)
        save()
    }

    func pushImage(_ image: NSImage) {
        guard let tiff = image.tiffRepresentation, let rep = NSBitmapImageRep(data: tiff), let png = rep.representation(using: .png, properties: [:]) else { return }
        let id = "I:" + Digest.sha256(png)
        guard !items.contains(where: { $0.id == id }) else { return }
        let name = id.replacingOccurrences(of: ":", with: "_") + ".png"
        let path = imagesDir.appendingPathComponent(name)
        try? png.write(to: path)
        var item = ClipItem(id: id, kind: .image, text: nil, imagePath: path.path, ts: Date().timeIntervalSince1970, pinned: false, sourceAppName: nil, sourceBundleID: nil, sourceIconPath: nil, useCount: 0)
        enrichWithSourceInfo(&item)
        items.insert(item, at: 0)
        save()
    }

    func delete(id: String) {
        if let idx = items.firstIndex(where: { $0.id == id }) {
            items.remove(at: idx)
            save()
        }
    }

    func togglePin(id: String) {
        guard let idx = items.firstIndex(where: { $0.id == id }) else { return }
        let cur = items[idx]
        let newPin = !(cur.pinned ?? false)
        items[idx].pinned = newPin
        // 将置顶项移到顶部
        if newPin {
            let item = items.remove(at: idx)
            items.insert(item, at: 0)
        }
        save()
    }

    func incrementUseCount(id: String) {
        if let idx = items.firstIndex(where: { $0.id == id }) {
            let c = (items[idx].useCount ?? 0) + 1
            items[idx].useCount = c
            save()
        }
    }

    private func enrichWithSourceInfo(_ item: inout ClipItem) {
        if let app = NSWorkspace.shared.frontmostApplication {
            item.sourceAppName = app.localizedName
            item.sourceBundleID = app.bundleIdentifier
            if let bundleURL = app.bundleURL {
                let icon = NSWorkspace.shared.icon(forFile: bundleURL.path)
                if let tiff = icon.tiffRepresentation, let rep = NSBitmapImageRep(data: tiff), let png = rep.representation(using: .png, properties: [:]) {
                    let key = (item.sourceBundleID ?? "app")
                    let iconPath = iconsDir.appendingPathComponent("\(key).png")
                    if !fm.fileExists(atPath: iconPath.path) {
                        try? png.write(to: iconPath)
                    }
                    item.sourceIconPath = iconPath.path
                }
            }
        }
    }
}
