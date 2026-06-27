#!/usr/bin/swift
//
// GenerateAppIcon.swift
//
// Generates the macOS app icon (all 10 sizes + Contents.json) for PDF2MD.
// Uses only built-in Apple frameworks — no installs required.
//
// Usage (run from the repo root on a Mac):
//
//   swift PDF2MD/Tools/GenerateAppIcon.swift
//       → draws the built-in PDF→MD icon
//
//   swift PDF2MD/Tools/GenerateAppIcon.swift /path/to/my-1024.png
//       → slices your own 1024×1024 PNG into all sizes instead
//
// After running, rebuild in Xcode (Clean Build Folder ⇧⌘K if the old icon
// is cached).
//
import AppKit

// MARK: - Output location

let assetPath = "PDF2MD/PDF2MD/Assets.xcassets/AppIcon.appiconset"
let fm = FileManager.default
guard fm.fileExists(atPath: "PDF2MD/PDF2MD/Assets.xcassets") else {
    FileHandle.standardError.write(Data("Error: run this from the repo root (the folder that contains the top-level PDF2MD directory).\n".utf8))
    exit(1)
}
try? fm.createDirectory(atPath: assetPath, withIntermediateDirectories: true)

let customInput: NSImage? = {
    guard CommandLine.arguments.count > 1 else { return nil }
    let path = CommandLine.arguments[1]
    guard let img = NSImage(contentsOfFile: path) else {
        FileHandle.standardError.write(Data("Error: couldn't read image at \(path)\n".utf8))
        exit(1)
    }
    return img
}()

// MARK: - Drawing

func drawGeneratedIcon(side s: CGFloat) {
    // Rounded-rect "squircle" plate with a subtle margin and shadow.
    let inset = s * 0.10
    let plate = NSRect(x: inset, y: inset, width: s - inset * 2, height: s - inset * 2)
    let radius = plate.width * 0.2237
    let platePath = NSBezierPath(roundedRect: plate, xRadius: radius, yRadius: radius)

    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.22)
    shadow.shadowBlurRadius = s * 0.03
    shadow.shadowOffset = NSSize(width: 0, height: -s * 0.012)
    shadow.set()

    let gradient = NSGradient(colors: [
        NSColor(calibratedRed: 0.29, green: 0.47, blue: 0.96, alpha: 1),
        NSColor(calibratedRed: 0.46, green: 0.30, blue: 0.86, alpha: 1),
    ])!
    gradient.draw(in: platePath, angle: -90)

    // Clear the shadow for inner content.
    let noShadow = NSShadow()
    noShadow.shadowColor = .clear
    noShadow.set()

    // White page with a folded top-right corner.
    let pw = s * 0.42
    let ph = s * 0.52
    let px = (s - pw) / 2
    let py = (s - ph) / 2
    let fold = pw * 0.30

    let page = NSBezierPath()
    page.move(to: NSPoint(x: px, y: py))
    page.line(to: NSPoint(x: px, y: py + ph))
    page.line(to: NSPoint(x: px + pw - fold, y: py + ph))
    page.line(to: NSPoint(x: px + pw, y: py + ph - fold))
    page.line(to: NSPoint(x: px + pw, y: py))
    page.close()
    NSColor.white.setFill()
    page.fill()

    // The folded corner (slightly shaded).
    let foldPath = NSBezierPath()
    foldPath.move(to: NSPoint(x: px + pw - fold, y: py + ph))
    foldPath.line(to: NSPoint(x: px + pw - fold, y: py + ph - fold))
    foldPath.line(to: NSPoint(x: px + pw, y: py + ph - fold))
    foldPath.close()
    NSColor(calibratedWhite: 0.80, alpha: 1).setFill()
    foldPath.fill()

    // "MD" label on the page.
    let label = "MD"
    let fontSize = s * 0.20
    let font = NSFont.systemFont(ofSize: fontSize, weight: .heavy)
    let attrs: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: NSColor(calibratedRed: 0.30, green: 0.24, blue: 0.62, alpha: 1),
    ]
    let str = NSAttributedString(string: label, attributes: attrs)
    let textSize = str.size()
    let textRect = NSRect(x: (s - textSize.width) / 2,
                          y: py + ph * 0.30,
                          width: textSize.width,
                          height: textSize.height)
    str.draw(in: textRect)
}

func makeIconRep(pixels: Int) -> NSBitmapImageRep {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil,
                              pixelsWide: pixels, pixelsHigh: pixels,
                              bitsPerSample: 8, samplesPerPixel: 4,
                              hasAlpha: true, isPlanar: false,
                              colorSpaceName: .deviceRGB,
                              bytesPerRow: 0, bitsPerPixel: 0)!
    rep.size = NSSize(width: pixels, height: pixels)

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let bounds = NSRect(x: 0, y: 0, width: pixels, height: pixels)
    NSColor.clear.set()
    bounds.fill()

    if let input = customInput {
        input.draw(in: bounds, from: .zero, operation: .copy, fraction: 1.0)
    } else {
        drawGeneratedIcon(side: CGFloat(pixels))
    }

    NSGraphicsContext.current?.flushGraphics()
    NSGraphicsContext.restoreGraphicsState()
    return rep
}

// MARK: - Emit PNGs + Contents.json

struct Slot { let size: Int; let scale: Int; var pixels: Int { size * scale }
    var filename: String { "icon_\(size)x\(size)\(scale == 2 ? "@2x" : "").png" } }

let slots: [Slot] = [16, 32, 128, 256, 512].flatMap { [Slot(size: $0, scale: 1), Slot(size: $0, scale: 2)] }

for slot in slots {
    let rep = makeIconRep(pixels: slot.pixels)
    guard let data = rep.representation(using: .png, properties: [:]) else { continue }
    let url = URL(fileURLWithPath: "\(assetPath)/\(slot.filename)")
    try data.write(to: url)
    print("wrote \(slot.filename) (\(slot.pixels)px)")
}

let images = slots.map { #"    { "idiom" : "mac", "size" : "\#($0.size)x\#($0.size)", "scale" : "\#($0.scale)x", "filename" : "\#($0.filename)" }"# }
let contents = """
{
  "images" : [
\(images.joined(separator: ",\n"))
  ],
  "info" : { "author" : "xcode", "version" : 1 }
}

"""
try contents.write(toFile: "\(assetPath)/Contents.json", atomically: true, encoding: .utf8)
print("wrote Contents.json")
print("Done. Rebuild in Xcode (⇧⌘K to clean if the icon looks stale).")
