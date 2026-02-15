import SwiftUI
import AppKit

struct ContentView: View {
    @ObservedObject var store = HistoryStore.shared
    @State private var query: String = ""
    @State private var selectedFilter: ClipKind? = nil

    let onClose: () -> Void
    let onSelect: (ClipItem) -> Void
    let onSelectPlain: (ClipItem) -> Void

    var body: some View {
        ZStack {
            backgroundLayer

            VStack(alignment: .leading, spacing: 16) {
                headerView
                searchField
                filterChips
                listView
                footerView
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
        }
        .padding(.bottom, 6)
        .onExitCommand(perform: onClose)
    }

    private var backgroundLayer: some View {
        ZStack {
            Color.clear
            RadialGradient(
                colors: [
                    Color.accentColor.opacity(0.06),
                    Color.clear
                ],
                center: .topLeading,
                startRadius: 16,
                endRadius: 420
            )
            .blur(radius: 60)
        }
        .ignoresSafeArea()
    }

    private var headerView: some View {
        HStack(spacing: 14) {
            LiquidSymbolIcon(
                symbolName: "rectangle.and.paperclip",
                gradient: [
                    Color(red: 0.56, green: 0.74, blue: 1.00),
                    Color(red: 0.33, green: 0.55, blue: 0.99)
                ],
                size: 46
            )

            VStack(alignment: .leading, spacing: 2) {
                Text("剪贴板历史")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                Text("Liquid Glass 面板，与你的复制保持同步")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }

            Spacer()

            if !store.items.isEmpty {
                LiquidChip(
                    text: "\(store.items.count) 条",
                    colors: [
                        Color(red: 0.56, green: 0.74, blue: 1.00),
                        Color(red: 0.40, green: 0.48, blue: 0.96)
                    ]
                )
            }
        }
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
            TextField("搜索…", text: $query)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .foregroundColor(.primary)

            if !query.isEmpty {
                Button {
                    query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white.opacity(0.55))
                }
                .buttonStyle(.plain)
            } else {
                Text("⌘F")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary.opacity(0.6))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(Color.primary.opacity(0.06))
                    )
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.thinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
                        .blendMode(.overlay)
                )
        )
    }

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(title: "All", isSelected: selectedFilter == nil) {
                    selectedFilter = nil
                }
                ForEach(ClipKind.allCases, id: \.self) { kind in
                    FilterChip(
                        title: kind.labelCN,
                        icon: kind.liquidSymbolName,
                        isSelected: selectedFilter == kind
                    ) {
                        selectedFilter = (selectedFilter == kind) ? nil : kind
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var listView: some View {
        if filteredItems.isEmpty {
            emptyState
        } else {
            ScrollView {
                LazyVStack(spacing: 14) {
                    ForEach(Array(filteredItems.enumerated()), id: \.element.id) { index, item in
                        RowView(item: item, onSelect: onSelect, onSelectPlain: onSelectPlain)
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .move(edge: .top)),
                                removal: .opacity
                            ))
                            .animation(
                                .spring(response: 0.35, dampingFraction: 0.8)
                                .delay(Double(min(index, 10)) * 0.03),
                                value: filteredItems.count
                            )
                    }
                }
                .padding(.vertical, 6)
            }
            .hideScrollIndicatorsIfAvailable()
            .frame(minHeight: 280, maxHeight: 400)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            LiquidSymbolIcon(
                symbolName: "square.and.arrow.down.on.square.fill",
                gradient: [
                    Color(red: 0.63, green: 0.78, blue: 1.00),
                    Color(red: 0.33, green: 0.55, blue: 0.99)
                ],
                size: 52
            )
            Text("尚无剪贴板记录")
                .font(.system(size: 14, weight: .medium))
            Text("复制内容后将在此显示，支持文本、图片、文件与代码片段。")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 280)
        .padding(.vertical, 28)
        .liquidGlass(cornerRadius: 24, elevation: 12)
    }

    private var footerView: some View {
        HStack {
            Label {
                Text("⌥V 呼出 · 单击即粘贴")
            } icon: {
                Image(systemName: "sparkles")
            }
            .font(.system(size: 11))
            .foregroundColor(.secondary)

            Spacer()

            Button {
                store.clearAll()
            } label: {
                Label("清空历史", systemImage: "trash")
                    .font(.system(size: 11, weight: .semibold))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(
                        Capsule(style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 1.00, green: 0.46, blue: 0.54),
                                        Color(red: 0.90, green: 0.20, blue: 0.31)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                                Capsule(style: .continuous)
                                    .stroke(Color.white.opacity(0.25), lineWidth: 0.9)
                                    .blendMode(.overlay)
                            )
                    )
                    .foregroundColor(.white.opacity(0.92))
            }
            .buttonStyle(.plain)
        }
    }

    private var filteredItems: [ClipItem] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        var base = store.items
            .sorted { a, b in
                let ap = a.pinned ?? false
                let bp = b.pinned ?? false
                if ap != bp { return ap && !bp }
                return a.ts > b.ts
            }

        // Apply type filter
        if let filter = selectedFilter {
            base = base.filter { $0.kind == filter }
        }

        if q.isEmpty { return base }
        return base.filter { item in
            switch item.kind {
            case .image:
                return "image 图片".contains(q) || timeAgoCN(from: item.date).contains(q)
            default:
                let t = (item.text ?? "").lowercased()
                return t.contains(q) || timeAgoCN(from: item.date).contains(q)
            }
        }
    }
}

private struct RowView: View {
    let item: ClipItem
    let onSelect: (ClipItem) -> Void
    let onSelectPlain: (ClipItem) -> Void

    @State private var isHovering = false

    private var isPinned: Bool { item.pinned ?? false }

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            LiquidSymbolIcon(
                symbolName: leadingSymbol,
                gradient: leadingGradient,
                size: 36
            )

            mainContent
                .frame(maxWidth: .infinity, alignment: .leading)

            if let appImage = appIconImage {
                Image(nsImage: appImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 24, height: 24)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .stroke(Color.white.opacity(0.25), lineWidth: 0.8)
                            .blendMode(.overlay)
                    )
                    .shadow(color: Color.black.opacity(0.12), radius: 4, x: 0, y: 2)
            }

            if isPinned {
                LiquidChip(
                    text: "置顶",
                    colors: [
                        Color(red: 1.00, green: 0.85, blue: 0.40),
                        Color(red: 1.00, green: 0.58, blue: 0.28)
                    ]
                )
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        .liquidGlass(cornerRadius: 20, elevation: isHovering ? 16 : 10)
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.accentColor.opacity(isHovering ? 0.25 : 0), lineWidth: 1)
        )
        .scaleEffect(isHovering ? 1.01 : 1.0)
        .onTapGesture { onSelect(item) }
        .onDrag {
            provideDragItem()
        }
        .onHover { hovering in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isHovering = hovering
            }
        }
        .contextMenu {
            Button("粘贴") { onSelect(item) }
            if item.text != nil {
                Button("以纯文本粘贴") { onSelectPlain(item) }
            }
            Button(isPinned ? "取消置顶" : "置顶") {
                HistoryStore.shared.togglePin(id: item.id)
            }
            Divider()
            Button("删除", role: .destructive) {
                HistoryStore.shared.delete(id: item.id)
            }
        }
    }

    @ViewBuilder
    private var mainContent: some View {
        switch item.kind {
        case .image:
            imagePreview
        case .link:
            linkPreview
        case .code:
            codePreview
        case .file:
            filePreview
        case .text:
            textPreview
        }
    }

    private var imagePreview: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let nsImage = previewImage {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
                    )
                HStack(spacing: 4) {
                    Text("\(Int(nsImage.size.width))×\(Int(nsImage.size.height))")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(.secondary)
                    Text("·")
                        .foregroundColor(.secondary)
                    Text(subText)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private var linkPreview: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: "globe")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                Text(linkDomain)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            Text(item.text ?? "")
                .font(.system(size: 13, weight: .medium))
                .lineLimit(2)
                .foregroundColor(.primary)
            Text(subText)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
    }

    private var codePreview: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(detectedLanguageBadge)
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule().fill(Color.orange.opacity(0.15))
                    )
                    .foregroundColor(.orange)
                Spacer()
                Text("\(item.text?.components(separatedBy: "\n").count ?? 0) lines")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            Text(item.text?.prefix(200) ?? "")
                .font(.system(size: 11, weight: .regular, design: .monospaced))
                .lineLimit(3)
                .foregroundColor(.primary.opacity(0.85))
            Text(subText)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
    }

    private var filePreview: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(fileName)
                .font(.system(size: 13, weight: .medium))
                .lineLimit(1)
            Text(item.text ?? "")
                .font(.system(size: 11, design: .monospaced))
                .lineLimit(1)
                .foregroundColor(.secondary)
            Text(subText)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
    }

    private var textPreview: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(titleText)
                .font(.system(size: 13, weight: .medium))
                .lineLimit(2)
            HStack(spacing: 4) {
                Text(characterCountText)
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(.secondary)
                Text("·")
                    .foregroundColor(.secondary)
                Text(subText)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
        }
    }

    private var linkDomain: String {
        guard let text = item.text,
              let url = URL(string: text),
              let host = url.host else {
            return item.text?.components(separatedBy: "/").dropFirst(2).first ?? ""
        }
        return host.replacingOccurrences(of: "www.", with: "")
    }

    private var detectedLanguageBadge: String {
        guard let text = item.text else { return "Code" }
        if text.contains("import Swift") || text.contains("struct ") && text.contains("var ") { return "Swift" }
        if text.contains("function ") || text.contains("const ") || text.contains("=>") { return "JS" }
        if text.contains("def ") || text.contains("import ") && !text.contains(";") { return "Python" }
        if text.contains("#include") { return "C/C++" }
        if text.contains("class ") && text.contains("{") { return "Code" }
        return "Code"
    }

    private var fileName: String {
        guard let text = item.text else { return "File" }
        return URL(string: text)?.lastPathComponent ?? text.components(separatedBy: "/").last ?? "File"
    }

    private var characterCountText: String {
        guard let text = item.text else { return "" }
        let chars = text.count
        let words = text.split(separator: " ").count
        if chars > 100 {
            return "\(chars) chars"
        }
        return "\(words) words"
    }

    private var titleText: String {
        switch item.kind {
        case .image:
            return "图片"
        default:
            return item.text?.replacingOccurrences(of: "\n", with: " ") ?? ""
        }
    }

    private var subText: String {
        let t = timeAgoCN(from: item.date)
        var tail = item.kind.labelCN + " · " + t
        if let app = item.sourceAppName, !app.isEmpty {
            tail += " · 来自 " + app
        }
        if let c = item.useCount, c > 0 {
            tail += " · 使用 \(c) 次"
        }
        return tail
    }

    private var leadingSymbol: String {
        isPinned ? "star.circle.fill" : item.kind.liquidSymbolName
    }

    private var leadingGradient: [Color] {
        if isPinned {
            return [
                Color(red: 1.00, green: 0.85, blue: 0.40),
                Color(red: 1.00, green: 0.58, blue: 0.28)
            ]
        }
        return item.kind.liquidGradientColors
    }

    private var previewImage: NSImage? {
        guard let path = item.imagePath else { return nil }
        return NSImage(contentsOfFile: path)
    }

    private var appIconImage: NSImage? {
        guard let iconPath = item.sourceIconPath else { return nil }
        return NSImage(contentsOfFile: iconPath)
    }

    private func provideDragItem() -> NSItemProvider {
        switch item.kind {
        case .image:
            // 拖拽图片
            if let path = item.imagePath, let image = NSImage(contentsOfFile: path) {
                return NSItemProvider(object: image)
            }
        default:
            // 拖拽文本（包括链接、代码、文件路径）
            if let text = item.text {
                return NSItemProvider(object: text as NSString)
            }
        }
        // 降级方案：空文本
        return NSItemProvider(object: "" as NSString)
    }
}

private struct FilterChip: View {
    let title: String
    var icon: String? = nil
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 10))
                }
                Text(title)
                    .font(.system(size: 11, weight: isSelected ? .semibold : .regular))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule(style: .continuous)
                    .fill(isSelected ? Color.accentColor.opacity(0.2) : Color.primary.opacity(0.06))
            )
            .foregroundColor(isSelected ? .accentColor : .secondary)
        }
        .buttonStyle(.plain)
    }
}
