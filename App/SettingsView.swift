import SwiftUI
import ServiceManagement
import ApplicationServices
import AppKit

struct SettingsView: View {
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @State private var launchStatusText: String = ""
    @State private var launchStatusColor: Color = .secondary
    @AppStorage("appearanceMode") private var appearanceMode = "system" // system|light|dark
    @AppStorage("maxHistoryItems") private var maxHistoryItems: Double = 200
    @AppStorage("maxHistoryDays") private var maxHistoryDays: Double = 30
    @AppStorage("hotkeyLetter") private var hotkeyLetter = "v"
    @AppStorage("hotkeyMods") private var hotkeyMods = "option" // comma-separated

    @State private var permissionStatus: String = ""

    var body: some View {
        ZStack {
            backgroundLayer

            ScrollView {
                VStack(spacing: 22) {
                    header

                    SettingsSection(
                        symbol: "gearshape.fill",
                        colors: [
                            Color(red: 0.52, green: 0.71, blue: 1.00),
                            Color(red: 0.31, green: 0.48, blue: 0.93)
                        ],
                        title: "启动与外观",
                        subtitle: "设定开机自启与主题风格"
                    ) {
                        VStack(alignment: .leading, spacing: 12) {
                            Toggle(isOn: Binding(get: {
                                launchAtLogin
                            }, set: { value in
                                launchAtLogin = value
                                toggleLoginItem(value)
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                    refreshLoginStatus()
                                }
                            })) {
                                Label("开机自启动", systemImage: "bolt.fill")
                                    .font(.system(size: 13, weight: .medium))
                            }
                            .toggleStyle(.switch)
                            .settingRow()

                            HStack(spacing: 10) {
                                Circle()
                                    .fill(launchStatusColor)
                                    .frame(width: 8, height: 8)
                                Text(launchStatusText)
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                            .settingRow()

                            HStack(spacing: 10) {
                                Image(systemName: "dock.rectangle")
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                                Text("Dock 图标：已隐藏（后台应用模式）")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                            .settingRow()

                            HStack {
                                Text("主题")
                                    .font(.system(size: 12, weight: .medium))
                                Spacer()
                                Picker("主题", selection: $appearanceMode) {
                                    Text("跟随系统").tag("system")
                                    Text("浅色").tag("light")
                                    Text("深色").tag("dark")
                                }
                                .pickerStyle(.segmented)
                                .frame(width: 200)
                                .onChange(of: appearanceMode) { applyAppearance($0) }
                            }
                            .settingRow()
                        }
                    }

                    SettingsSection(
                        symbol: "internaldrive.fill",
                        colors: [
                            Color(red: 0.62, green: 0.86, blue: 0.98),
                            Color(red: 0.25, green: 0.48, blue: 0.93)
                        ],
                        title: "历史与存储",
                        subtitle: "控制保留数量与空间"
                    ) {
                        VStack(alignment: .leading, spacing: 12) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("最大记录数量: \(Int(maxHistoryItems)) 条")
                                    .font(.system(size: 12, weight: .medium))
                                Slider(value: $maxHistoryItems, in: 50...500, step: 50) { _ in
                                    HistoryStore.shared.maxItems = Int(maxHistoryItems)
                                }
                            }
                            .settingRow()

                            VStack(alignment: .leading, spacing: 8) {
                                Text("保留天数: \(Int(maxHistoryDays)) 天")
                                    .font(.system(size: 12, weight: .medium))
                                Slider(value: $maxHistoryDays, in: 7...120, step: 1)
                            }
                            .settingRow()

                            HStack(spacing: 12) {
                                Button {
                                    pruneOld(days: Int(maxHistoryDays))
                                } label: {
                                    Label("清理过期记录", systemImage: "clock.arrow.circlepath")
                                }
                                .buttonStyle(LiquidCapsuleButtonStyle(colors: [
                                    Color(red: 0.50, green: 0.72, blue: 1.00),
                                    Color(red: 0.33, green: 0.52, blue: 0.95)
                                ]))

                                Spacer()

                                Button {
                                    HistoryStore.shared.clearAll()
                                } label: {
                                    Label("清空所有历史", systemImage: "trash.fill")
                                }
                                .buttonStyle(LiquidCapsuleButtonStyle(colors: [
                                    Color(red: 1.00, green: 0.46, blue: 0.54),
                                    Color(red: 0.90, green: 0.20, blue: 0.31)
                                ]))
                            }
                            .padding(.top, 4)
                        }
                    }

                    SettingsSection(
                        symbol: "command.circle.fill",
                        colors: [
                            Color(red: 0.87, green: 0.69, blue: 0.99),
                            Color(red: 0.53, green: 0.38, blue: 0.87)
                        ],
                        title: "全局快捷键",
                        subtitle: "设置呼出面板的组合键"
                    ) {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 10) {
                                Text("修饰键")
                                    .font(.system(size: 12, weight: .medium))
                                Spacer()
                                Toggle("⌘", isOn: bindingForModifier("command"))
                                    .toggleStyle(.switch)
                                Toggle("⌥", isOn: bindingForModifier("option"))
                                    .toggleStyle(.switch)
                                Toggle("⌃", isOn: bindingForModifier("control"))
                                    .toggleStyle(.switch)
                                Toggle("⇧", isOn: bindingForModifier("shift"))
                                    .toggleStyle(.switch)
                            }
                            .settingRow()

                            HStack(spacing: 10) {
                                Text("主键")
                                    .font(.system(size: 12, weight: .medium))
                                Spacer()
                                TextField("字母", text: $hotkeyLetter)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 60)
                            }
                            .settingRow()

                            Button {
                                applyHotkey()
                            } label: {
                                Label("应用快捷键", systemImage: "sparkles")
                            }
                            .buttonStyle(LiquidCapsuleButtonStyle(colors: [
                                Color(red: 0.56, green: 0.74, blue: 1.00),
                                Color(red: 0.33, green: 0.55, blue: 0.99)
                            ]))
                        }
                    }

                    SettingsSection(
                        symbol: "lock.shield",
                        colors: [
                            Color(red: 0.74, green: 0.92, blue: 0.78),
                            Color(red: 0.35, green: 0.70, blue: 0.54)
                        ],
                        title: "权限",
                        subtitle: "确保辅助功能权限已开启"
                    ) {
                        HStack(spacing: 12) {
                            Button {
                                checkAccessibility()
                            } label: {
                                Label("检查辅助功能权限", systemImage: "checkmark.shield")
                            }
                            .buttonStyle(LiquidCapsuleButtonStyle(colors: [
                                Color(red: 0.43, green: 0.78, blue: 0.82),
                                Color(red: 0.25, green: 0.58, blue: 0.74)
                            ]))

                            Text(permissionStatus)
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        .settingRow()
                    }

                    SettingsSection(
                        symbol: "power",
                        colors: [
                            Color(red: 1.00, green: 0.69, blue: 0.55),
                            Color(red: 0.94, green: 0.38, blue: 0.36)
                        ],
                        title: "其他",
                        subtitle: "快速管理应用生命周期"
                    ) {
                        HStack(spacing: 12) {
                            Button {
                                NSApp.terminate(nil)
                            } label: {
                                Label("退出应用", systemImage: "door.left.hand.open")
                            }
                            .buttonStyle(LiquidCapsuleButtonStyle(colors: [
                                Color(red: 1.00, green: 0.58, blue: 0.44),
                                Color(red: 0.91, green: 0.29, blue: 0.27)
                            ]))

                            Button {
                                let task = Process()
                                task.launchPath = "/usr/bin/open"
                                task.arguments = [Bundle.main.bundlePath]
                                try? task.run()
                                NSApp.terminate(nil)
                            } label: {
                                Label("重启应用", systemImage: "arrow.clockwise.circle")
                            }
                            .buttonStyle(LiquidCapsuleButtonStyle(colors: [
                                Color(red: 0.51, green: 0.74, blue: 1.00),
                                Color(red: 0.31, green: 0.52, blue: 0.93)
                            ]))

                            Spacer()
                        }
                        .settingRow()
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 32)
            }
            .hideScrollIndicatorsIfAvailable()
        }
        .onAppear {
            HistoryStore.shared.maxItems = Int(maxHistoryItems)
            applyAppearance(appearanceMode)
            refreshLoginStatus()
        }
    }

    private var backgroundLayer: some View {
        ZStack {
            Color(nsColor: .windowBackgroundColor)
                .ignoresSafeArea()

            RadialGradient(
                colors: [
                    Color.accentColor.opacity(0.08),
                    Color.clear
                ],
                center: .topTrailing,
                startRadius: 12,
                endRadius: 520
            )
            .blur(radius: 60)
        }
        .ignoresSafeArea()
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 18) {
            LiquidSymbolIcon(
                symbolName: "slider.horizontal.3",
                gradient: [
                    Color(red: 0.56, green: 0.74, blue: 1.00),
                    Color(red: 0.36, green: 0.54, blue: 0.96)
                ],
                size: 52
            )

            VStack(alignment: .leading, spacing: 4) {
                Text("设置中心")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                Text("升级为 Liquid Glass 风格，全面掌控粘贴体验。")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }

            Spacer()

            LiquidChip(
                text: hotkeySummary.isEmpty ? "快捷键未设置" : "当前快捷键 \(hotkeySummary)",
                colors: [
                    Color(red: 0.87, green: 0.69, blue: 0.99),
                    Color(red: 0.53, green: 0.38, blue: 0.87)
                ]
            )
        }
    }

    private var hotkeySummary: String {
        let symbols: [String: String] = [
            "command": "⌘",
            "option": "⌥",
            "control": "⌃",
            "shift": "⇧"
        ]
        let mods = hotkeyMods
            .split(separator: ",")
            .compactMap { symbols[String($0)] }
            .joined()
        let letter = hotkeyLetter.uppercased()
        return mods + letter
    }

    private func pruneOld(days: Int) {
        let cutoff = Date().addingTimeInterval(-Double(days) * 86400).timeIntervalSince1970
        let filtered = HistoryStore.shared.items.filter { $0.ts >= cutoff || ($0.pinned ?? false) }
        if filtered.count != HistoryStore.shared.items.count {
            HistoryStore.shared.clearAll()
            filtered.reversed().forEach { item in
                if item.kind == .image, let path = item.imagePath, let img = NSImage(contentsOfFile: path) {
                    HistoryStore.shared.pushImage(img)
                } else if let text = item.text {
                    HistoryStore.shared.pushText(text)
                }
            }
        }
    }

    private func bindingForModifier(_ mod: String) -> Binding<Bool> {
        Binding(get: {
            hotkeyMods.split(separator: ",").map { String($0) }.contains(mod)
        }, set: { newVal in
            var arr = Set(hotkeyMods.split(separator: ",").map { String($0) }.filter { !$0.isEmpty })
            if newVal { arr.insert(mod) } else { arr.remove(mod) }
            hotkeyMods = arr.sorted().joined(separator: ",")
        })
    }

    private func applyHotkey() {
        let mods = hotkeyMods.split(separator: ",").map { String($0) }
        HotKeyManager.shared.updateHotKey(letter: hotkeyLetter, mods: mods)
    }

    private func applyAppearance(_ mode: String) {
        switch mode {
        case "light": NSApp.appearance = NSAppearance(named: .aqua)
        case "dark": NSApp.appearance = NSAppearance(named: .darkAqua)
        default: NSApp.appearance = nil
        }
    }

    private func toggleLoginItem(_ on: Bool) {
        // 首选使用 SMAppService（10.15+，13.0 推荐）
        var success = false
        if #available(macOS 13.0, *) {
            do {
                if on {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
                success = true
                print("✅ SMAppService: launch at login = \(on)")
            } catch {
                print("⚠️ SMAppService failed: \(error). Will fall back to LaunchAgent.")
            }
        }

        // 回退方案：用户 LaunchAgent（~/Library/LaunchAgents）
        if !success {
            if on {
                success = enableLaunchAgent()
            } else {
                success = disableLaunchAgent()
            }
            print("\(success ? "✅" : "❌") LaunchAgent: launch at login = \(on)")
        }
    }

    private func launchAgentPlistURL() -> URL {
        let fm = FileManager.default
        let dir = fm.homeDirectoryForCurrentUser.appendingPathComponent("Library/LaunchAgents", isDirectory: true)
        try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        let bid = Bundle.main.bundleIdentifier ?? "com.example.OptV"
        return dir.appendingPathComponent("\(bid).launchagent.plist")
    }

    private func enableLaunchAgent() -> Bool {
        guard let exe = Bundle.main.executableURL?.path else { return false }
        let bid = Bundle.main.bundleIdentifier ?? "com.example.OptV"
        let dict: [String: Any] = [
            "Label": bid,
            "RunAtLoad": true,
            "KeepAlive": false,
            "Program": exe,
            "ProcessType": "Interactive"
        ]
        let url = launchAgentPlistURL()
        do {
            let data = try PropertyListSerialization.data(fromPropertyList: dict, format: .xml, options: 0)
            try data.write(to: url)
        } catch {
            print("Write LaunchAgent failed: \(error)")
            return false
        }
        return runLaunchctl(args: ["load", "-w", url.path])
    }

    private func disableLaunchAgent() -> Bool {
        let url = launchAgentPlistURL()
        _ = runLaunchctl(args: ["unload", "-w", url.path])
        try? FileManager.default.removeItem(at: url)
        return true
    }

    @discardableResult
    private func runLaunchctl(args: [String]) -> Bool {
        let task = Process()
        task.launchPath = "/bin/launchctl"
        task.arguments = args
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        do { try task.run() } catch { print("launchctl run error: \(error)"); return false }
        task.waitUntilExit()
        let status = task.terminationStatus
        if status != 0 {
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let s = String(data: data, encoding: .utf8), !s.isEmpty {
                print("launchctl output: \n\(s)")
            }
        }
        return status == 0
    }

    private func checkAccessibility() {
        let opts = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true as CFBoolean] as CFDictionary
        let granted = AXIsProcessTrustedWithOptions(opts)
        permissionStatus = granted ? "✅ 已授权" : "❌ 未授权（已弹出系统提示）"
    }

    private func refreshLoginStatus() {
        // 简化：根据开关状态或 LaunchAgent 是否存在来展示
        let exists = FileManager.default.fileExists(atPath: launchAgentPlistURL().path)
        let enabled = launchAtLogin || exists
        launchStatusText = enabled ? "已启用（下次登录自动启动）" : "未启用"
        launchStatusColor = enabled ? .green : .secondary
    }
}

private struct SettingsSection<Content: View>: View {
    let symbol: String
    let colors: [Color]
    let title: String
    let subtitle: String?
    let content: Content

    init(symbol: String, colors: [Color], title: String, subtitle: String? = nil, @ViewBuilder content: () -> Content) {
        self.symbol = symbol
        self.colors = colors
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center, spacing: 12) {
                LiquidSymbolIcon(symbolName: symbol, gradient: colors, size: 40)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                    if let subtitle {
                        Text(subtitle)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
            }
            content
        }
        .padding(20)
        .liquidGlass(cornerRadius: 26, elevation: 18)
    }
}

private struct LiquidCapsuleButtonStyle: ButtonStyle {
    let colors: [Color]

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .semibold))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule(style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: colors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(Color.white.opacity(0.28), lineWidth: 0.8)
                            .blendMode(.overlay)
                    )
            )
            .foregroundColor(.white.opacity(0.94))
            .opacity(configuration.isPressed ? 0.86 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

private struct SettingRowModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.primary.opacity(0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.primary.opacity(0.08), lineWidth: 0.7)
                            .blendMode(.overlay)
                    )
            )
    }
}

private extension View {
    func settingRow() -> some View {
        modifier(SettingRowModifier())
    }
}
