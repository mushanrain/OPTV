import AppKit

enum AppIconFactory {
    static func makeIcon(size: CGFloat = 512) -> NSImage {
        let img = NSImage(size: NSSize(width: size, height: size))
        img.lockFocus()

        let rect = NSRect(x: 0, y: 0, width: size, height: size)
        let cornerRadius = size * 0.22
        let path = NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius)

        NSGraphicsContext.current?.shouldAntialias = true

        NSGraphicsContext.current?.saveGraphicsState()
        path.addClip()

        // 主背景：多段渐变，呈现液态玻璃色彩
        let baseGradient = NSGradient(colorsAndLocations:
            (NSColor(calibratedRed: 0.26, green: 0.56, blue: 0.99, alpha: 1.0), 0.0),
            (NSColor(calibratedRed: 0.37, green: 0.30, blue: 0.94, alpha: 1.0), 0.55),
            (NSColor(calibratedRed: 0.18, green: 0.09, blue: 0.38, alpha: 1.0), 1.0)
        )
        baseGradient?.draw(in: rect, angle: -90)

        // 顶部高光
        let glossRect = NSRect(x: rect.minX, y: rect.midY, width: rect.width, height: rect.height * 0.55)
        let glossPath = NSBezierPath(roundedRect: glossRect, xRadius: cornerRadius, yRadius: cornerRadius)
        let glossGradient = NSGradient(colors: [
            NSColor.white.withAlphaComponent(0.42),
            NSColor.white.withAlphaComponent(0.04)
        ])
        glossGradient?.draw(in: glossPath, angle: -90)

        // 底部浅色辉光
        let glowRect = NSRect(x: rect.width * 0.18, y: rect.height * 0.05, width: rect.width * 0.64, height: rect.height * 0.35)
        let glowPath = NSBezierPath(ovalIn: glowRect)
        let glowGradient = NSGradient(colors: [
            NSColor(calibratedRed: 0.64, green: 0.87, blue: 1.0, alpha: 0.55),
            NSColor.white.withAlphaComponent(0.0)
        ])
        glowGradient?.draw(in: glowPath, relativeCenterPosition: NSPoint(x: 0.0, y: -0.3))

        // 内层玻璃板
        let innerRect = rect.insetBy(dx: size * 0.12, dy: size * 0.12)
        let innerPath = NSBezierPath(roundedRect: innerRect, xRadius: size * 0.20, yRadius: size * 0.20)
        let innerGradient = NSGradient(colors: [
            NSColor.white.withAlphaComponent(0.20),
            NSColor.white.withAlphaComponent(0.05)
        ])
        innerGradient?.draw(in: innerPath, angle: -90)

        // 内层描边，增加层次
        NSColor.white.withAlphaComponent(0.22).setStroke()
        innerPath.lineWidth = size * 0.018
        innerPath.stroke()

        // 中心标志背板
        let symbolScale: CGFloat = 0.48
        let symSize = NSSize(width: size * symbolScale, height: size * symbolScale)
        let symOrigin = NSPoint(x: (size - symSize.width) / 2, y: (size - symSize.height) / 2)
        let symRect = NSRect(origin: symOrigin, size: symSize)
        let plateRect = symRect.insetBy(dx: -size * 0.08, dy: -size * 0.08)
        let platePath = NSBezierPath(roundedRect: plateRect, xRadius: size * 0.20, yRadius: size * 0.20)
        let plateGradient = NSGradient(colors: [
            NSColor.white.withAlphaComponent(0.34),
            NSColor.white.withAlphaComponent(0.08)
        ])
        plateGradient?.draw(in: platePath, angle: -90)
        NSColor.white.withAlphaComponent(0.25).setStroke()
        platePath.lineWidth = size * 0.014
        platePath.stroke()

        // 居中绘制 SF Symbol（剪贴板）
        if var symbol = NSImage(systemSymbolName: "rectangle.and.paperclip", accessibilityDescription: nil) {
            let config = NSImage.SymbolConfiguration(pointSize: symSize.height, weight: .semibold)
            if let configured = symbol.withSymbolConfiguration(config) {
                symbol = configured
            }
            symbol.isTemplate = true

            let tinted = NSImage(size: symSize)
            tinted.lockFocus()
            let localRect = NSRect(origin: .zero, size: symSize)
            NSColor.white.withAlphaComponent(0.95).setFill()
            localRect.fill()
            symbol.draw(in: localRect, from: .zero, operation: .destinationIn, fraction: 1.0)
            tinted.unlockFocus()

            let ctx = NSGraphicsContext.current?.cgContext
            ctx?.saveGState()
            let shadow = NSShadow()
            shadow.shadowBlurRadius = size * 0.06
            shadow.shadowColor = NSColor.white.withAlphaComponent(0.45)
            shadow.shadowOffset = .zero
            shadow.set()
            tinted.draw(in: symRect, from: .zero, operation: .sourceOver, fraction: 1.0)
            ctx?.restoreGState()
        }

        NSGraphicsContext.current?.restoreGraphicsState()

        // 外轮廓描边
        NSColor.white.withAlphaComponent(0.28).setStroke()
        path.lineWidth = size * 0.02
        path.stroke()

        img.unlockFocus()
        return img
    }
}
