import Foundation
import AppKit

enum ClipKind: String, Codable, CaseIterable {
    case text
    case link
    case code
    case image
    case file
}

struct ClipItem: Identifiable, Codable, Equatable {
    var id: String
    var kind: ClipKind
    var text: String?
    var imagePath: String?
    var ts: TimeInterval
    var pinned: Bool? // 借鉴：置顶收藏
    var sourceAppName: String?
    var sourceBundleID: String?
    var sourceIconPath: String?
    var useCount: Int?
}

extension ClipItem {
    var date: Date { Date(timeIntervalSince1970: ts) }
}

enum Classifier {
    static func classify(text: String) -> ClipKind {
        let s = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if isFileURL(s) { return .file }
        if isLink(s) { return .link }
        if isCode(s) { return .code }
        return .text
    }

    static func isLink(_ s: String) -> Bool {
        if s.hasPrefix("http://") || s.hasPrefix("https://") { return true }
        if s.hasPrefix("www.") { return true }
        return false
    }

    static func isCode(_ s: String) -> Bool {
        if s.hasPrefix("```") { return true }
        if s.contains("\n"), (s.contains("{") || s.contains(";") || s.contains("=>") || s.contains("def ") || s.contains("class ") || s.contains("import ") || s.contains("#include")) {
            return true
        }
        return false
    }

    static func isFileURL(_ s: String) -> Bool {
        return s.hasPrefix("file://")
    }
}

extension ClipKind {
    var icon: String {
        switch self {
        case .image: return "🖼️"
        case .link: return "🔗"
        case .code: return "💻"
        case .file: return "📄"
        case .text: return "📝"
        }
    }

    var labelCN: String {
        switch self {
        case .image: return "图片"
        case .link: return "链接"
        case .code: return "代码"
        case .file: return "文件"
        case .text: return "文本"
        }
    }
}

func timeAgoCN(from date: Date) -> String {
    let seconds = Int(Date().timeIntervalSince(date))
    if seconds < 60 { return "\(seconds) 秒前" }
    if seconds < 3600 { return "\(seconds/60) 分钟前" }
    if seconds < 86400 { return "\(seconds/3600) 小时前" }
    if seconds < 86400 * 7 { return "\(seconds/86400) 天前" }
    let f = DateFormatter()
    f.dateFormat = "yyyy-MM-dd"
    return f.string(from: date)
}
