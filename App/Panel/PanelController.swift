import Foundation
import AppKit
import SwiftUI

final class PanelController: NSObject, NSWindowDelegate {
    static let shared = PanelController()

    private var panel: NSPanel!
    private var hosting: NSHostingView<ContentView>!
    private var previousApp: NSRunningApplication?
    private var escMonitor: Any?
    private var escGlobalMonitor: Any?

    private let width: CGFloat = 480
    private let rowHeight: CGFloat = 82
    private let rows: CGFloat = 7

    override init() {
        super.init()
        setupPanel()
    }

    private func setupPanel() {
        let style: NSWindow.StyleMask = [.nonactivatingPanel, .titled, .fullSizeContentView]
        let rect = NSRect(x: 0, y: 0, width: width, height: rowHeight * rows + 8)
        panel = NSPanel(contentRect: rect, styleMask: style, backing: .buffered, defer: true)
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = false
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.isMovableByWindowBackground = true
        panel.appearance = NSAppearance(named: .vibrantLight)
        panel.level = .statusBar
        panel.collectionBehavior = [.fullScreenAuxiliary, .canJoinAllSpaces]
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.becomesKeyOnlyIfNeeded = false
        // 显示标准关闭按钮（遵循 macOS 样式）
        panel.standardWindowButton(.closeButton)?.isHidden = false
        panel.standardWindowButton(.miniaturizeButton)?.isHidden = true
        panel.standardWindowButton(.zoomButton)?.isHidden = true
        panel.delegate = self

        hosting = NSHostingView(rootView: ContentView(onClose: { [weak self] in
            self?.hide()
        }, onSelect: { [weak self] item in
            self?.performPaste(item: item)
        }, onSelectPlain: { [weak self] item in
            self?.performPastePlain(item: item)
        }))

        let blur = NSVisualEffectView(frame: rect)
        blur.material = .hudWindow
        blur.blendingMode = .behindWindow
        blur.state = .active
        if #available(macOS 10.14, *) {
            blur.isEmphasized = true
        }
        blur.translatesAutoresizingMaskIntoConstraints = false

        let container = NSView(frame: rect)
        container.wantsLayer = true
        container.layer?.cornerRadius = 26
        if #available(macOS 12.0, *) {
            container.layer?.cornerCurve = .continuous
        }
        container.layer?.masksToBounds = true
        container.layer?.borderWidth = 1.0
        container.layer?.borderColor = NSColor.white.withAlphaComponent(0.22).cgColor
        container.layer?.backgroundColor = NSColor.windowBackgroundColor.withAlphaComponent(0.08).cgColor

        panel.contentView = container

        container.addSubview(blur)
        let tintView = NSView(frame: rect)
        tintView.translatesAutoresizingMaskIntoConstraints = false
        tintView.wantsLayer = true
        if let layer = tintView.layer {
            let gradient = CAGradientLayer()
            gradient.colors = [
                NSColor(calibratedRed: 0.35, green: 0.56, blue: 0.98, alpha: 0.38).cgColor,
                NSColor(calibratedRed: 0.15, green: 0.20, blue: 0.35, alpha: 0.45).cgColor
            ]
            gradient.locations = [0.0, 1.0]
            gradient.startPoint = CGPoint(x: 0.0, y: 0.0)
            gradient.endPoint = CGPoint(x: 1.0, y: 1.0)
            gradient.frame = layer.bounds
            gradient.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
            layer.insertSublayer(gradient, at: 0)
            layer.opacity = 0.8
            layer.masksToBounds = true
            layer.cornerRadius = container.layer?.cornerRadius ?? 26
        }
        container.addSubview(tintView)
        container.addSubview(hosting)

        NSLayoutConstraint.activate([
            blur.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            blur.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            blur.topAnchor.constraint(equalTo: container.topAnchor),
            blur.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])

        NSLayoutConstraint.activate([
            tintView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            tintView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            tintView.topAnchor.constraint(equalTo: container.topAnchor),
            tintView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        hosting.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hosting.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            hosting.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            hosting.topAnchor.constraint(equalTo: container.topAnchor),
            hosting.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
    }

    func show() {
        previousApp = NSWorkspace.shared.frontmostApplication
        positionNearMouse()
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)

        // 监听 ESC 关闭（本地 + 全局，确保可拦截 TextField 焦点场景）
        escMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 { // ESC
                self?.hide()
                return nil
            }
            return event
        }
        escGlobalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 {
                self?.hide()
            }
        }
    }

    func hide() {
        panel.orderOut(nil)
        if let m = escMonitor { NSEvent.removeMonitor(m); escMonitor = nil }
        if let gm = escGlobalMonitor { NSEvent.removeMonitor(gm); escGlobalMonitor = nil }
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        // 左上角红色关闭仅隐藏面板
        hide()
        return false
    }

    private func positionNearMouse() {
        let mouse = NSEvent.mouseLocation
        let screens = NSScreen.screens
        let screen = screens.first(where: { NSMouseInRect(mouse, $0.frame, false) }) ?? NSScreen.main
        guard let scr = screen else { return }
        let size = panel.frame.size
        let margin: CGFloat = 12
        var x = mouse.x - size.width/2
        var y = mouse.y - size.height - margin
        x = max(scr.frame.minX + margin, min(x, scr.frame.maxX - size.width - margin))
        y = max(scr.frame.minY + margin, min(y, scr.frame.maxY - size.height - margin))
        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }

    private func performPaste(item: ClipItem) {
        hide()
        guard let targetApp = previousApp else { return }

        // Write pasteboard
        let pb = NSPasteboard.general
        pb.clearContents()
        switch item.kind {
        case .image:
            if let path = item.imagePath, let img = NSImage(contentsOfFile: path) {
                ClipboardManager.shared.willProgrammaticPaste()
                pb.writeObjects([img])
            }
        default:
            if let text = item.text { ClipboardManager.shared.willProgrammaticPaste(); pb.setString(text, forType: .string) }
        }

        // Reactivate and then send Cmd+V with a slight delay to ensure focus
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) {
            targetApp.activate(options: [.activateIgnoringOtherApps])
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                sendCmdV()
            }
        }
        HistoryStore.shared.incrementUseCount(id: item.id)
    }

    private func performPastePlain(item: ClipItem) {
        hide()
        guard let targetApp = previousApp else { return }
        let pb = NSPasteboard.general
        pb.clearContents()
        if let text = item.text {
            ClipboardManager.shared.willProgrammaticPaste()
            pb.setString(text, forType: .string) // 强制纯文本
        } else if item.kind == .image, let path = item.imagePath, let img = NSImage(contentsOfFile: path) {
            ClipboardManager.shared.willProgrammaticPaste()
            pb.writeObjects([img])
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) {
            targetApp.activate(options: [.activateIgnoringOtherApps])
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                sendCmdV()
            }
        }
        HistoryStore.shared.incrementUseCount(id: item.id)
    }
}

private func sendCmdV() {
    // 发送 ⌘V
    let src = CGEventSource(stateID: .hidSystemState)
    let keyV: CGKeyCode = 9 // kVK_ANSI_V
    let keyDown = CGEvent(keyboardEventSource: src, virtualKey: keyV, keyDown: true)
    keyDown?.flags = .maskCommand
    let keyUp = CGEvent(keyboardEventSource: src, virtualKey: keyV, keyDown: false)
    keyUp?.flags = .maskCommand
    keyDown?.post(tap: .cghidEventTap)
    keyUp?.post(tap: .cghidEventTap)
}
