// AppIcon.icns を生成する
// 使い方: swift scripts/make-icon.swift [出力先 .icns] [--preview <out.png>]
//
// 「一時置き場の点線の四角に、書類のカードが置かれる」絵。
// SF Symbols はアプリアイコンに使えない（Apple の利用規約）ので、図形はすべてここで描く。
import AppKit

var arguments = Array(CommandLine.arguments.dropFirst())
var previewPath: String?
if let index = arguments.firstIndex(of: "--preview"), index + 1 < arguments.count {
    previewPath = arguments[index + 1]
    arguments.removeSubrange(index...index + 1)
}
let output = arguments.first ?? "Resources/AppIcon.icns"

func color(_ hex: UInt32, alpha: CGFloat = 1) -> NSColor {
    NSColor(
        srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
        green: CGFloat((hex >> 8) & 0xFF) / 255,
        blue: CGFloat(hex & 0xFF) / 255,
        alpha: alpha
    )
}

/// 上辺の中央から時計回りに一周する角丸四角（点線の模様を上下左右で対称にするため）
func roundedSquarePath(_ rect: NSRect, radius r: CGFloat) -> NSBezierPath {
    let path = NSBezierPath()
    path.move(to: NSPoint(x: rect.midX, y: rect.maxY))
    path.line(to: NSPoint(x: rect.maxX - r, y: rect.maxY))
    path.appendArc(withCenter: NSPoint(x: rect.maxX - r, y: rect.maxY - r), radius: r, startAngle: 90, endAngle: 0, clockwise: true)
    path.line(to: NSPoint(x: rect.maxX, y: rect.minY + r))
    path.appendArc(withCenter: NSPoint(x: rect.maxX - r, y: rect.minY + r), radius: r, startAngle: 0, endAngle: -90, clockwise: true)
    path.line(to: NSPoint(x: rect.minX + r, y: rect.minY))
    path.appendArc(withCenter: NSPoint(x: rect.minX + r, y: rect.minY + r), radius: r, startAngle: -90, endAngle: -180, clockwise: true)
    path.line(to: NSPoint(x: rect.minX, y: rect.maxY - r))
    path.appendArc(withCenter: NSPoint(x: rect.minX + r, y: rect.maxY - r), radius: r, startAngle: 180, endAngle: 90, clockwise: true)
    path.close()
    return path
}

/// center を中心に angle 度回転させて描く
func withRotation(_ angle: CGFloat, around center: NSPoint, _ draw: () -> Void) {
    NSGraphicsContext.saveGraphicsState()
    let transform = NSAffineTransform()
    transform.translateX(by: center.x, yBy: center.y)
    transform.rotate(byDegrees: angle)
    transform.translateX(by: -center.x, yBy: -center.y)
    transform.concat()
    draw()
    NSGraphicsContext.restoreGraphicsState()
}

/// 書類のカード（右上が折れていて、本文の線が入っている）
func drawCard(center: NSPoint, angle: CGFloat, alpha: CGFloat, detailed: Bool) {
    let size = NSSize(width: 290, height: 350)
    let rect = NSRect(x: center.x - size.width / 2, y: center.y - size.height / 2, width: size.width, height: size.height)
    let fold: CGFloat = 78
    withRotation(angle, around: center) {
        // 右上の角を折った形
        let body = NSBezierPath()
        let r: CGFloat = 34
        body.move(to: NSPoint(x: rect.minX + r, y: rect.maxY))
        body.line(to: NSPoint(x: rect.maxX - fold, y: rect.maxY))
        body.line(to: NSPoint(x: rect.maxX, y: rect.maxY - fold))
        body.line(to: NSPoint(x: rect.maxX, y: rect.minY + r))
        body.appendArc(withCenter: NSPoint(x: rect.maxX - r, y: rect.minY + r), radius: r, startAngle: 0, endAngle: -90, clockwise: true)
        body.line(to: NSPoint(x: rect.minX + r, y: rect.minY))
        body.appendArc(withCenter: NSPoint(x: rect.minX + r, y: rect.minY + r), radius: r, startAngle: -90, endAngle: -180, clockwise: true)
        body.line(to: NSPoint(x: rect.minX, y: rect.maxY - r))
        body.appendArc(withCenter: NSPoint(x: rect.minX + r, y: rect.maxY - r), radius: r, startAngle: 180, endAngle: 90, clockwise: true)
        body.close()

        NSGraphicsContext.saveGraphicsState()
        let shadow = NSShadow()
        shadow.shadowColor = color(0x0B2A6B, alpha: detailed ? 0.35 : 0.2)
        shadow.shadowBlurRadius = 36
        shadow.shadowOffset = NSSize(width: 0, height: -14)
        shadow.set()
        color(0xFFFFFF, alpha: alpha).setFill()
        body.fill()
        NSGraphicsContext.restoreGraphicsState()

        guard detailed else { return }

        // 折り返し部分
        let flap = NSBezierPath()
        flap.move(to: NSPoint(x: rect.maxX - fold, y: rect.maxY))
        flap.line(to: NSPoint(x: rect.maxX - fold, y: rect.maxY - fold + 16))
        flap.appendArc(
            withCenter: NSPoint(x: rect.maxX - fold + 16, y: rect.maxY - fold + 16),
            radius: 16, startAngle: 180, endAngle: 270
        )
        flap.line(to: NSPoint(x: rect.maxX, y: rect.maxY - fold))
        flap.close()
        color(0xC9DDF7).setFill()
        flap.fill()

        // 本文の線
        let lineColor = color(0x3A7BEA, alpha: 0.35)
        lineColor.setFill()
        let left = rect.minX + 52
        for (index, width) in [186.0, 186.0, 120.0].enumerated() {
            let y = rect.minY + 200 - CGFloat(index) * 52
            NSBezierPath(roundedRect: NSRect(x: left, y: y, width: width, height: 24), xRadius: 12, yRadius: 12).fill()
        }
    }
}

func drawIcon() {
    // macOS のアイコングリッド（824pt の角丸四角）
    let bodyRect = NSRect(x: 100, y: 100, width: 824, height: 824)
    let body = NSBezierPath(roundedRect: bodyRect, xRadius: 185, yRadius: 185)

    NSGraphicsContext.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.28)
    shadow.shadowBlurRadius = 24
    shadow.shadowOffset = NSSize(width: 0, height: -12)
    shadow.set()
    NSColor.black.setFill()
    body.fill()
    NSGraphicsContext.restoreGraphicsState()

    NSGradient(starting: color(0x38D3C4), ending: color(0x2E62EE))!.draw(in: body, angle: -90)
    // 上側を少し明るくして立体感を出す
    NSGradient(starting: color(0xFFFFFF, alpha: 0.18), ending: color(0xFFFFFF, alpha: 0))!
        .draw(in: body, angle: -90)

    // 一時置き場の点線の四角。上下左右で模様がそろうよう、一周を 4 の倍数で割る
    let squareRect = NSRect(x: 512 - 270, y: 452 - 270, width: 540, height: 540)
    let squareRadius: CGFloat = 104
    let square = roundedSquarePath(squareRect, radius: squareRadius)
    let perimeter = 4 * (squareRect.width - 2 * squareRadius) + 2 * .pi * squareRadius
    let unit = perimeter / 20
    var dash: [CGFloat] = [unit * 0.58, unit * 0.42]
    square.setLineDash(&dash, count: 2, phase: dash[0] / 2)
    square.lineWidth = 30
    square.lineCapStyle = .round
    color(0xFFFFFF, alpha: 0.92).setStroke()
    square.stroke()

    // 置かれた書類（奥のカードと手前のカード）
    drawCard(center: NSPoint(x: 448, y: 480), angle: 9, alpha: 0.55, detailed: false)
    drawCard(center: NSPoint(x: 560, y: 448), angle: -5, alpha: 1, detailed: true)
}

func render(pixels: Int) -> Data {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
    )!
    // 1024pt の座標系で描いて各サイズに縮小する
    rep.size = NSSize(width: 1024, height: 1024)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    drawIcon()
    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}

if let previewPath {
    try render(pixels: 1024).write(to: URL(fileURLWithPath: previewPath))
    print("✓ \(previewPath)")
    exit(0)
}

let iconset = FileManager.default.temporaryDirectory.appendingPathComponent("AppIcon.iconset")
try? FileManager.default.removeItem(at: iconset)
try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)

for points in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let name = scale == 1 ? "icon_\(points)x\(points).png" : "icon_\(points)x\(points)@2x.png"
        try render(pixels: points * scale).write(to: iconset.appendingPathComponent(name))
    }
}

let iconutil = Process()
iconutil.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
iconutil.arguments = ["-c", "icns", iconset.path, "-o", output]
try iconutil.run()
iconutil.waitUntilExit()
print(iconutil.terminationStatus == 0 ? "✓ \(output)" : "iconutil failed")
