import SwiftUI

extension ClipKind {
    var liquidSymbolName: String {
        switch self {
        case .text: return "doc.on.doc.fill"
        case .link: return "link.badge.plus"
        case .code: return "chevron.left.forwardslash.chevron.right"
        case .image: return "photo.on.rectangle.angled"
        case .file: return "doc.richtext.fill"
        }
    }

    var liquidGradientColors: [Color] {
        switch self {
        case .text:
            return [
                Color(red: 0.56, green: 0.71, blue: 1.00),
                Color(red: 0.39, green: 0.43, blue: 0.98)
            ]
        case .link:
            return [
                Color(red: 0.38, green: 0.79, blue: 0.99),
                Color(red: 0.00, green: 0.54, blue: 0.96)
            ]
        case .code:
            return [
                Color(red: 0.99, green: 0.71, blue: 0.53),
                Color(red: 0.86, green: 0.34, blue: 0.60)
            ]
        case .image:
            return [
                Color(red: 0.77, green: 0.91, blue: 0.73),
                Color(red: 0.34, green: 0.70, blue: 0.56)
            ]
        case .file:
            return [
                Color(red: 0.84, green: 0.86, blue: 0.93),
                Color(red: 0.56, green: 0.59, blue: 0.65)
            ]
        }
    }

    var chipColor: Color {
        switch self {
        case .text: return .blue
        case .link: return .cyan
        case .code: return .orange
        case .image: return .green
        case .file: return .gray
        }
    }
}
