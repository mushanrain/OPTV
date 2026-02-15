import Foundation
import AppKit

final class ClipboardManager {
    static let shared = ClipboardManager()

    private let pb = NSPasteboard.general
    private var lastChange = NSPasteboard.general.changeCount
    private var timer: Timer?
    private var ignoreNext = false
    var ignoredBundleIDs: Set<String> = [
        // 借鉴：常见密码/安全类应用，默认不记录，可按需增删
        "com.apple.keychainaccess",
        "com.agilebits.onepassword7",
        "com.1password.1password",
        "org.keepassx.keepassxc"
    ]

    func start() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { [weak self] _ in
            self?.poll()
        }
    }

    func willProgrammaticPaste() {
        // Skip capturing our own pasteboard writes just before Cmd+V
        ignoreNext = true
    }

    private func poll() {
        let cc = pb.changeCount
        guard cc != lastChange else { return }
        lastChange = cc
        capture()
    }

    private func capture() {
        // 忽略特定应用的复制
        if let app = NSWorkspace.shared.frontmostApplication, let bid = app.bundleIdentifier, ignoredBundleIDs.contains(bid) {
            return
        }
        if ignoreNext {
            ignoreNext = false
            return
        }

        if let images = pb.readObjects(forClasses: [NSImage.self], options: nil) as? [NSImage], let img = images.first {
            HistoryStore.shared.pushImage(img)
            return
        }

        if let urls = pb.readObjects(forClasses: [NSURL.self], options: nil) as? [URL], let u = urls.first {
            HistoryStore.shared.pushText(u.absoluteString)
            return
        }

        if let strings = pb.readObjects(forClasses: [NSString.self], options: nil) as? [String], let s = strings.first, !s.isEmpty {
            HistoryStore.shared.pushText(s)
        }
    }
}
