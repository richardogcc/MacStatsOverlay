// Generates the app icon: a dark glassy gauge on a rounded-rect background.
// Usage: swift scripts/make_icon.swift <output.png> <size>
import AppKit

let arguments = CommandLine.arguments
guard arguments.count == 3, let size = Int(arguments[2]) else {
    FileHandle.standardError.write("usage: make_icon.swift <output.png> <size>\n".data(using: .utf8)!)
    exit(1)
}

let dimension = CGFloat(size)
let image = NSImage(size: NSSize(width: dimension, height: dimension))
image.lockFocus()

guard let context = NSGraphicsContext.current?.cgContext else { exit(1) }

// macOS icons leave ~10% transparent margin around the rounded rect.
let margin = dimension * 0.09
let rect = CGRect(x: margin, y: margin, width: dimension - margin * 2, height: dimension - margin * 2)
let cornerRadius = rect.width * 0.225
let background = NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius)

// Background: deep blue -> violet diagonal gradient
let gradient = NSGradient(colors: [
    NSColor(calibratedRed: 0.09, green: 0.11, blue: 0.25, alpha: 1),
    NSColor(calibratedRed: 0.22, green: 0.12, blue: 0.42, alpha: 1),
    NSColor(calibratedRed: 0.45, green: 0.15, blue: 0.55, alpha: 1),
])!
gradient.draw(in: background, angle: -60)

// Subtle top glass highlight
background.addClip()
let highlight = NSGradient(colors: [
    NSColor.white.withAlphaComponent(0.22),
    NSColor.white.withAlphaComponent(0.0),
])!
highlight.draw(in: NSRect(x: rect.minX, y: rect.midY, width: rect.width, height: rect.height / 2), angle: -90)

let center = CGPoint(x: rect.midX, y: rect.midY - rect.height * 0.04)
let gaugeRadius = rect.width * 0.30

// Gauge track: 270° arc
context.setLineCap(.round)
context.setStrokeColor(NSColor.white.withAlphaComponent(0.25).cgColor)
context.setLineWidth(rect.width * 0.055)
context.addArc(center: center, radius: gaugeRadius,
               startAngle: -.pi * 0.25, endAngle: .pi * 1.25, clockwise: false)
context.strokePath()

// Gauge fill: bright arc covering ~70%
context.setStrokeColor(NSColor(calibratedRed: 0.35, green: 0.85, blue: 1.0, alpha: 1).cgColor)
context.addArc(center: center, radius: gaugeRadius,
               startAngle: .pi * 1.25, endAngle: .pi * 0.20, clockwise: true)
context.strokePath()

// Needle
let needleAngle: CGFloat = .pi * 0.20
let needleEnd = CGPoint(x: center.x + cos(needleAngle) * gaugeRadius * 0.72,
                        y: center.y + sin(needleAngle) * gaugeRadius * 0.72)
context.setStrokeColor(NSColor.white.cgColor)
context.setLineWidth(rect.width * 0.035)
context.move(to: center)
context.addLine(to: needleEnd)
context.strokePath()

// Hub
context.setFillColor(NSColor.white.cgColor)
let hubRadius = rect.width * 0.045
context.fillEllipse(in: CGRect(x: center.x - hubRadius, y: center.y - hubRadius,
                               width: hubRadius * 2, height: hubRadius * 2))

// Mini bar chart under the gauge
let barWidth = rect.width * 0.055
let barGap = rect.width * 0.035
let heights: [CGFloat] = [0.4, 0.75, 0.55, 1.0]
let chartWidth = CGFloat(heights.count) * barWidth + CGFloat(heights.count - 1) * barGap
var barX = rect.midX - chartWidth / 2
let barBaseY = rect.minY + rect.height * 0.14
context.setFillColor(NSColor.white.withAlphaComponent(0.9).cgColor)
for height in heights {
    let barRect = CGRect(x: barX, y: barBaseY,
                         width: barWidth, height: rect.height * 0.13 * height)
    NSBezierPath(roundedRect: barRect, xRadius: barWidth / 3, yRadius: barWidth / 3).fill()
    barX += barWidth + barGap
}

image.unlockFocus()

guard let tiff = image.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiff),
      let png = bitmap.representation(using: .png, properties: [:]) else { exit(1) }
try! png.write(to: URL(fileURLWithPath: arguments[1]))
