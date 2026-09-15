// Renders the Buckets app icon (a tree growing out of a bucket) into the asset catalog.
// Colors here are icon artwork, not app UI (the UI uses system semantic colors only).
// Usage: swift Scripts/make-icon.swift
import AppKit

let root = URL(fileURLWithPath: CommandLine.arguments[0]).deletingLastPathComponent().deletingLastPathComponent()
let outDir = root.appending(path: "Sources/Resources/Assets.xcassets/AppIcon.appiconset")

func draw(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()
    guard let ctx = NSGraphicsContext.current?.cgContext else { fatalError("no context") }
    let s = size / 1024
    ctx.scaleBy(x: s, y: s)

    // macOS icon grid: 824-pt rounded square centered on a 1024 canvas.
    let square = CGRect(x: 100, y: 100, width: 824, height: 824)
    let bg = CGPath(roundedRect: square, cornerWidth: 186, cornerHeight: 186, transform: nil)
    ctx.saveGState()
    ctx.addPath(bg); ctx.clip()
    let colors = [NSColor(red: 0.13, green: 0.42, blue: 0.24, alpha: 1).cgColor,
                  NSColor(red: 0.20, green: 0.58, blue: 0.34, alpha: 1).cgColor] as CFArray
    let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1])!
    ctx.drawLinearGradient(gradient, start: CGPoint(x: 512, y: 100), end: CGPoint(x: 512, y: 924), options: [])
    ctx.restoreGState()

    let cream = NSColor(red: 0.98, green: 0.96, blue: 0.90, alpha: 1).cgColor
    let creamShade = NSColor(red: 0.85, green: 0.80, blue: 0.68, alpha: 1).cgColor
    let leaf = NSColor(red: 0.66, green: 0.88, blue: 0.62, alpha: 1).cgColor
    let leafDark = NSColor(red: 0.45, green: 0.75, blue: 0.45, alpha: 1).cgColor
    let bark = NSColor(red: 0.42, green: 0.28, blue: 0.16, alpha: 1).cgColor

    // Soft shadow under everything.
    ctx.setShadow(offset: CGSize(width: 0, height: -12), blur: 28, color: NSColor.black.withAlphaComponent(0.28).cgColor)

    // Bucket body: trapezoid, wider at the top.
    let bucket = CGMutablePath()
    bucket.move(to: CGPoint(x: 300, y: 470))
    bucket.addLine(to: CGPoint(x: 724, y: 470))
    bucket.addLine(to: CGPoint(x: 668, y: 190))
    bucket.addQuadCurve(to: CGPoint(x: 356, y: 190), control: CGPoint(x: 512, y: 150))
    bucket.closeSubpath()
    ctx.setFillColor(cream); ctx.addPath(bucket); ctx.fillPath()

    // Rim band.
    ctx.setShadow(offset: .zero, blur: 0, color: nil)
    ctx.setFillColor(creamShade)
    ctx.fill(CGRect(x: 292, y: 452, width: 440, height: 40))
    ctx.setFillColor(cream)
    let rim = CGPath(roundedRect: CGRect(x: 280, y: 470, width: 464, height: 56), cornerWidth: 28, cornerHeight: 28, transform: nil)
    ctx.addPath(rim); ctx.fillPath()

    // Handle: an arc from rim to rim.
    ctx.setStrokeColor(cream); ctx.setLineWidth(26); ctx.setLineCap(.round)
    ctx.addArc(center: CGPoint(x: 512, y: 498), radius: 232, startAngle: .pi * 0.08, endAngle: .pi * 0.92, clockwise: false)
    ctx.strokePath()

    // Trunk.
    ctx.setShadow(offset: CGSize(width: 0, height: -8), blur: 18, color: NSColor.black.withAlphaComponent(0.22).cgColor)
    ctx.setFillColor(bark)
    let trunk = CGPath(roundedRect: CGRect(x: 484, y: 470, width: 56, height: 250), cornerWidth: 20, cornerHeight: 20, transform: nil)
    ctx.addPath(trunk); ctx.fillPath()

    // Canopy: three overlapping circles.
    ctx.setFillColor(leafDark)
    for (cx, cy, r) in [(400.0, 700.0, 118.0), (624.0, 700.0, 118.0), (512.0, 790.0, 150.0)] {
        ctx.fillEllipse(in: CGRect(x: cx - r, y: cy - r, width: 2 * r, height: 2 * r))
    }
    ctx.setShadow(offset: .zero, blur: 0, color: nil)
    ctx.setFillColor(leaf)
    for (cx, cy, r) in [(418.0, 716.0, 88.0), (606.0, 716.0, 88.0), (512.0, 806.0, 118.0)] {
        ctx.fillEllipse(in: CGRect(x: cx - r, y: cy - r, width: 2 * r, height: 2 * r))
    }
    image.unlockFocus()
    return image
}

func write(_ image: NSImage, px: Int, name: String) throws {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: px, bitsPerSample: 8, samplesPerPixel: 4,
                               hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    rep.size = NSSize(width: px, height: px)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    image.draw(in: NSRect(x: 0, y: 0, width: px, height: px), from: .zero, operation: .copy, fraction: 1)
    NSGraphicsContext.restoreGraphicsState()
    let png = rep.representation(using: .png, properties: [:])!
    try png.write(to: outDir.appending(path: name))
}

try FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)
let master = draw(size: 1024)
let entries: [(Int, String, String, String)] = [
    (16, "16x16", "1x", "icon_16.png"), (32, "16x16", "2x", "icon_32.png"),
    (32, "32x32", "1x", "icon_32.png"), (64, "32x32", "2x", "icon_64.png"),
    (128, "128x128", "1x", "icon_128.png"), (256, "128x128", "2x", "icon_256.png"),
    (256, "256x256", "1x", "icon_256.png"), (512, "256x256", "2x", "icon_512.png"),
    (512, "512x512", "1x", "icon_512.png"), (1024, "512x512", "2x", "icon_1024.png"),
]
for px in Set(entries.map(\.0)) { try write(master, px: px, name: "icon_\(px).png") }
let images = entries.map { ["size": $0.1, "idiom": "mac", "scale": $0.2, "filename": $0.3] }
let contents: [String: Any] = ["images": images, "info": ["version": 1, "author": "xcode"]]
let json = try JSONSerialization.data(withJSONObject: contents, options: [.prettyPrinted, .sortedKeys])
try json.write(to: outDir.appending(path: "Contents.json"))
print("wrote \(outDir.path)")
