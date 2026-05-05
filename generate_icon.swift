#!/usr/bin/env swift
import Foundation
import AppKit
import CoreText

let size: CGFloat = 1024
let outPath = "/Users/claudiurasteanu/Documents/Drift/Drift/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png"

let fontURL = URL(fileURLWithPath: "/Users/claudiurasteanu/Documents/Drift/Drift/Resources/Fonts/CormorantGaramond-BoldItalic.ttf")
guard let fontData = try? Data(contentsOf: fontURL),
      let provider = CGDataProvider(data: fontData as CFData),
      let cgFont = CGFont(provider) else {
    print("Failed to load font"); exit(1)
}

let fontSize: CGFloat = 400
let ctFont = CTFontCreateWithGraphicsFont(cgFont, fontSize, nil, nil)

let text = "drift."
let attrStr = NSAttributedString(string: text, attributes: [.font: ctFont])
let line = CTLineCreateWithAttributedString(attrStr)

// Measure
var ascent: CGFloat = 0, descent: CGFloat = 0, leading: CGFloat = 0
let lineWidth = CTLineGetTypographicBounds(line, &ascent, &descent, &leading)
let textH = ascent + descent
let xOrigin = (size - CGFloat(lineWidth)) / 2
let yOrigin = (size - textH) / 2 + descent

// Build a CGPath from the glyph outlines
let glyphPath = CGMutablePath()
let runs = CTLineGetGlyphRuns(line) as! [CTRun]
for run in runs {
    let count = CTRunGetGlyphCount(run)
    var glyphs = [CGGlyph](repeating: 0, count: count)
    var positions = [CGPoint](repeating: .zero, count: count)
    CTRunGetGlyphs(run, CFRange(location: 0, length: 0), &glyphs)
    CTRunGetPositions(run, CFRange(location: 0, length: 0), &positions)
    let runFont = unsafeBitCast(
        CFDictionaryGetValue(CTRunGetAttributes(run), Unmanaged.passUnretained(kCTFontAttributeName).toOpaque()),
        to: CTFont.self
    )
    for i in 0..<count {
        if let gp = CTFontCreatePathForGlyph(runFont, glyphs[i], nil) {
            var t = CGAffineTransform(translationX: xOrigin + positions[i].x, y: yOrigin)
            glyphPath.addPath(gp, transform: t)
        }
    }
}

// Draw into NSImage
// Render at 1x (not Retina 2x) to get exactly 1024×1024 pixels
let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: Int(size), pixelsHigh: Int(size),
    bitsPerSample: 8, samplesPerPixel: 4,
    hasAlpha: true, isPlanar: false,
    colorSpaceName: NSColorSpaceName.calibratedRGB,
    bytesPerRow: 0, bitsPerPixel: 0
)!
rep.size = NSSize(width: size, height: size)
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
guard let ctx = NSGraphicsContext.current?.cgContext else { exit(1) }

// Very dark background
let colorSpace = CGColorSpaceCreateDeviceRGB()
ctx.setFillColor(CGColor(colorSpace: colorSpace, components: [0x04/255, 0x02/255, 0x0A/255, 1])!)
ctx.fill(CGRect(x: 0, y: 0, width: size, height: size))

// Subtle radial purple glow
let glowColors = [
    CGColor(colorSpace: colorSpace, components: [0.22, 0.12, 0.55, 0.45])!,
    CGColor(colorSpace: colorSpace, components: [0.016, 0.008, 0.039, 0.0])!
]
let locs: [CGFloat] = [0, 1]
let radialGrad = CGGradient(colorsSpace: colorSpace, colors: glowColors as CFArray, locations: locs)!
ctx.drawRadialGradient(
    radialGrad,
    startCenter: CGPoint(x: size/2, y: size/2), startRadius: 0,
    endCenter: CGPoint(x: size/2, y: size/2), endRadius: size * 0.55,
    options: []
)

// Clip to glyph path and fill with teal→purple gradient
ctx.saveGState()
ctx.addPath(glyphPath)
ctx.clip()

let tealC   = CGColor(colorSpace: colorSpace, components: [0x4D/255, 0xD9/255, 0xC0/255, 1])!
let purpleC = CGColor(colorSpace: colorSpace, components: [0x5B/255, 0x4F/255, 0xE8/255, 1])!
let textGrad = CGGradient(colorsSpace: colorSpace, colors: [tealC, purpleC] as CFArray, locations: locs)!
ctx.drawLinearGradient(
    textGrad,
    start: CGPoint(x: xOrigin, y: size/2),
    end: CGPoint(x: xOrigin + CGFloat(lineWidth), y: size/2),
    options: [.drawsBeforeStartLocation, .drawsAfterEndLocation]
)
ctx.restoreGState()

NSGraphicsContext.restoreGraphicsState()

guard let png = rep.representation(using: NSBitmapImageRep.FileType.png, properties: [:]) else {
    print("PNG encode failed"); exit(1)
}
try! png.write(to: URL(fileURLWithPath: outPath))
print("Done → \(outPath)")
