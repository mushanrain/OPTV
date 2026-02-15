import SwiftUI
import AppKit

struct ContentView: View {
    @ObservedObject var store = HistoryStore.shared
    @State private var query: String = ""

    let onClose: () -> Void
    let onSelect: (ClipItem) -> Void
    let onSelectPlain: (ClipItem) -> Void

    var body: some View {
        ZStack {
            backgroundLayer

            VStack(alignment: .leading, spacing: 18) {
                headerView
                searchField
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
            RadialGradient(
                colors: [
                    Color.white.opacity(0.24),
                    Color.clear
                ],
                center: .topLeading,
                startRadius: 16,
                endRadius: 420
            )
            .blur(radius: 60)
            .offset(x: -120, y: -150)
            .blendMode(.plusLighter)

            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.10, blue: 0.22).opacity(0.65),
                    Color(red: 0.12, green: 0.15, blue: 0.28).opacity(0.55)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
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
                .foregroundColor(.white.opacity(0.65))
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
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.thinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.18), lineWidth: 0.9)
                        .blendMode(.overlay)
                )
        )
    }

    @ViewBuilder
    private var listView: some View {
        if filteredItems.isEmpty {
            emptyState
        } else {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(filteredItems) { item in
                        RowView(item: item, onSelect: onSelect, onSelectPlain: onSelectPlain)
                    }
                }
                .padding(.vertical, 6)
            }
            .hideScrollIndicatorsIfAvailable()
            .frame(minHeight: 280, maxHeight: 360)
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
        let base = store.items
            .sorted { a, b in
                let ap = a.pinned ?? false
                let bp = b.pinned ?? false
                if ap != bp { return ap && !bp }
                return a.ts > b.ts
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
        .onTapGesture { onSelect(item) }
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.18)) {
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
        if item.kind == .image, let nsImage = previewImage {
            VStack(alignment: .leading, spacing: 6) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 132, height: 74)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.white.opacity(0.26), lineWidth: 0.8)
                            .blendMode(.overlay)
                    )
                    .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 4)

                Text(subText)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
        } else {
            VStack(alignment: .leading, spacing: 4) {
                Text(titleText)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(2)
                Text(subText)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
        }
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
}
