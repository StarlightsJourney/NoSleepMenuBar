import AppKit
import Foundation

let sizes: [(name: String, px: Int)] = [
    ("icon_16x16", 16),
    ("icon_16x16@2x", 32),
    ("icon_32x32", 32),
    ("icon_32x32@2x", 64),
    ("icon_128x128", 128),
    ("icon_128x128@2x", 256),
    ("icon_256x256", 256),
    ("icon_256x256@2x", 512),
    ("icon_512x512", 512),
    ("icon_512x512@2x", 1024),
]

let iconSetURL = URL(fileURLWithPath: "AppIcon.iconset")
try? FileManager.default.removeItem(at: iconSetURL)
try FileManager.default.createDirectory(at: iconSetURL, withIntermediateDirectories: true)

for item in sizes {
    let px = CGFloat(item.px)
    let size = NSSize(width: px, height: px)

    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: item.px,
        pixelsHigh: item.px,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else {
        fputs("Failed to create bitmap for \(item.name)\n", stderr)
        exit(1)
    }
    bitmap.size = size

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
    defer { NSGraphicsContext.restoreGraphicsState() }

    // Rounded yellow background.
    let rect = NSRect(origin: .zero, size: size)
    let radius = px * 0.22
    let background = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
    NSColor.systemYellow.setFill()
    background.fill()

    // White coffee-cup symbol.
    if let symbol = NSImage(systemSymbolName: "cup.and.saucer.fill", accessibilityDescription: "NoSleep") {
        let pointSize = px * 0.55
        let config = NSImage.SymbolConfiguration(pointSize: pointSize, weight: .medium)
            .applying(NSImage.SymbolConfiguration(paletteColors: [.white]))
        guard let colored = symbol.withSymbolConfiguration(config) else { continue }
        colored.size = NSSize(width: px * 0.6, height: px * 0.6)
        let x = (size.width - colored.size.width) / 2
        let y = (size.height - colored.size.height) / 2
        colored.draw(
            at: NSPoint(x: x, y: y),
            from: NSRect(origin: .zero, size: colored.size),
            operation: .sourceOver,
            fraction: 1.0
        )
    }

    guard let png = bitmap.representation(using: .png, properties: [:]) else {
        fputs("Failed to encode PNG for \(item.name)\n", stderr)
        exit(1)
    }

    let url = iconSetURL.appendingPathComponent("\(item.name).png")
    try png.write(to: url)
}

let task = Process()
task.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
task.arguments = ["-c", "icns", iconSetURL.path, "-o", "AppIcon.icns"]
try task.run()
task.waitUntilExit()

if task.terminationStatus != 0 {
    fputs("iconutil failed\n", stderr)
    exit(Int32(task.terminationStatus))
}

print("Generated AppIcon.icns")
