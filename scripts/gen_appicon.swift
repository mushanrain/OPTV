#!/usr/bin/swift
import Foundation
import AppKit

func makeIcon(size: CGFloat = 1024) -> NSImage {
    let img = NSImage(size: NSSize(width: size, height: size))
    img.lockFocus()
    let rect = NSRect(x: 0, y: 0, width: size, height: size)
    let path = NSBezierPath(roundedRect: rect, xRadius: size * 0.18, yRadius: size * 0.18)
let gradient = NSGradient(colors: [NSColor.systemTeal, NSColor.systemBlue])
    gradient?.draw(in: path, angle: 90)
if let symbol = NSImage(systemSymbolName: "doc.on.clipboard.fill", accessibilityDescription: nil) {
    let envScale = ProcessInfo.processInfo.environment["ICON_SCALE"].flatMap { Double($0) } ?? 0.5
    let scale: CGFloat = CGFloat(envScale)
    let symSize = NSSize(width: size * scale, height: size * scale)
    let symOrigin = NSPoint(x: (size - symSize.width)/2, y: (size - symSize.height)/2)
    let rect = NSRect(origin: symOrigin, size: symSize)
    NSColor.white.withAlphaComponent(0.92).set()
    symbol.draw(in: rect)
}
    img.unlockFocus()
    return img
}

func pngData(from image: NSImage, size: CGFloat) -> Data? {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(size), pixelsHigh: Int(size), bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)
    rep?.size = NSSize(width: size, height: size)
    NSGraphicsContext.saveGraphicsState()
    if let rep = rep {
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
        image.draw(in: NSRect(x: 0, y: 0, width: size, height: size), from: .zero, operation: .sourceOver, fraction: 1)
        NSGraphicsContext.restoreGraphicsState()
        return rep.representation(using: .png, properties: [:])
    }
    return nil
}

let env = ProcessInfo.processInfo.environment
let assetsPath = env["ASSETS_PATH"] ?? "OptV/Assets.xcassets/AppIcon.appiconset"
let appiconURL = URL(fileURLWithPath: assetsPath)
try? FileManager.default.createDirectory(at: appiconURL, withIntermediateDirectories: true)

let base = makeIcon(size: 1024)

// 标准 macOS AppIcon 尺寸集（1024 = 512@2x 已包含）
let entries: [(size: Int, scale: Int)] = [
    (16,1),(16,2),
    (32,1),(32,2),
    (128,1),(128,2),
    (256,1),(256,2),
    (512,1),(512,2)
]

var imagesJson: [[String:Any]] = []
for e in entries {
    let px = e.size * e.scale
    let filename = "icon_\(e.size)x\(e.size)@\(e.scale)x.png"
    if let data = pngData(from: base, size: CGFloat(px)) {
        try? data.write(to: appiconURL.appendingPathComponent(filename))
        imagesJson.append([
            "idiom":"mac",
            "size":"\(e.size)x\(e.size)",
            "scale":"\(e.scale)x",
            "filename": filename
        ])
    }
}

let contents: [String:Any] = [
    "images": imagesJson,
    "info": ["version": 1, "author": "xcode"]
]
let jsonData = try JSONSerialization.data(withJSONObject: contents, options: [.prettyPrinted])
try jsonData.write(to: appiconURL.appendingPathComponent("Contents.json"))
print("✅ Generated AppIcon at \(appiconURL.path)")
