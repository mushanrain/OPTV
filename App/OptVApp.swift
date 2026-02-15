import SwiftUI
import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ notification: Notification) {
        // 启动剪贴板监听与全局热键
        ClipboardManager.shared.start()
        HotKeyManager.shared.onPressed = {
            PanelController.shared.show()
        }
        HotKeyManager.shared.registerOptionV()
        // 可选：隐藏 Dock 图标
        // NSApp.setActivationPolicy(.accessory)

        // 设置运行时应用图标
        NSApp.applicationIconImage = AppIconFactory.makeIcon()
        // 隐藏 Dock 图标但保留在“强制退出”列表（LSUIElement 关闭）
        NSApp.setActivationPolicy(.accessory)
        // 开机自启时在后台运行：不自动弹出设置窗口
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        // 再次打开应用时，保持隐藏 Dock，并弹出设置窗口
        NSApp.setActivationPolicy(.accessory)
        SettingsWindowController.shared.show()
        return true
    }
}

@main
struct OptVApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // 仍保留 Settings 场景（供 Cmd+, 等系统入口）
        Settings { SettingsView() }
            .commands { CommandGroup(replacing: .newItem) {} }
    }
}
