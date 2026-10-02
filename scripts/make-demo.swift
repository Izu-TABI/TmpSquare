// README の動作イメージを作る（scripts/make-demo.sh から呼ばれる）
//
//   swift scripts/make-demo.swift samples <dir>
//       デモ用のサンプルファイル（写真・PDF・テキスト・フォルダ）を作る
//   swift scripts/make-demo.swift compose <frames> <samples> <out> [<suffix>]
//       アプリで実際にコマ撮りしたシェルフ（<frames>）に、カーソルやドラッグ中のファイルを描き足して
//       <out>/demo<suffix>.gif と <out>/screenshots<suffix>.png を作る（英語版は suffix に -en）
//   swift scripts/make-demo.swift social <frames> <samples> <icon.png> <out.png>
//       SNS などでリンクを共有したときに出る画像（1280×640）を作る
import AppKit
import ImageIO
import UniformTypeIdentifiers

let arguments = CommandLine.arguments

func color(_ hex: UInt32, alpha: CGFloat = 1) -> NSColor {
    NSColor(
        srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
        green: CGFloat((hex >> 8) & 0xFF) / 255,
        blue: CGFloat(hex & 0xFF) / 255,
        alpha: alpha
    )
}

func writePNG(_ rep: NSBitmapImageRep, to url: URL) throws {
    try rep.representation(using: .png, properties: [:])!.write(to: url)
}

/// 左上を原点とする座標系で描くビットマップ
func drawBitmap(width: Int, height: Int, _ draw: () -> Void) -> NSBitmapImageRep {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: width, pixelsHigh: height,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
    )!
    NSGraphicsContext.saveGraphicsState()
    let context = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.current = NSGraphicsContext(cgContext: context.cgContext, flipped: true)
    context.cgContext.translateBy(x: 0, y: CGFloat(height))
    context.cgContext.scaleBy(x: 1, y: -1)
    draw()
    NSGraphicsContext.restoreGraphicsState()
    return rep
}

// MARK: - サンプルファイル

func makeSamples(in directory: URL) throws {
    let fileManager = FileManager.default
    try fileManager.createDirectory(at: directory.appendingPathComponent("Assets"), withIntermediateDirectories: true)
    try "Meeting notes\n\n- Share the Q3 report\n- Pick photos for the deck\n- Send files to the team\n"
        .write(to: directory.appendingPathComponent("Notes.txt"), atomically: true, encoding: .utf8)

    // 風景写真の代わりのイラスト
    let photo = drawBitmap(width: 1200, height: 800) {
        let full = NSRect(x: 0, y: 0, width: 1200, height: 800)
        NSGradient(starting: color(0x8EC5FF), ending: color(0xFFD6A5))!.draw(in: full, angle: 90)
        color(0xFFF3C4).setFill()
        NSBezierPath(ovalIn: NSRect(x: 780, y: 150, width: 170, height: 170)).fill()
        for (index, hill) in [(0x7CC6A4, 470.0), (0x3E9C8A, 560.0), (0x26706B, 650.0)].enumerated() {
            let path = NSBezierPath()
            path.move(to: NSPoint(x: 0, y: 800))
            path.line(to: NSPoint(x: 0, y: hill.1))
            path.curve(
                to: NSPoint(x: 1200, y: hill.1 - 40),
                controlPoint1: NSPoint(x: 350 + Double(index) * 120, y: hill.1 - 220),
                controlPoint2: NSPoint(x: 800 - Double(index) * 90, y: hill.1 + 120)
            )
            path.line(to: NSPoint(x: 1200, y: 800))
            path.close()
            color(UInt32(hill.0)).setFill()
            path.fill()
        }
    }
    try writePNG(photo, to: directory.appendingPathComponent("Photo.png"))

    // 棒グラフの入った 1 ページの PDF
    var mediaBox = CGRect(x: 0, y: 0, width: 612, height: 792)
    let pdf = CGContext(directory.appendingPathComponent("Report.pdf") as CFURL, mediaBox: &mediaBox, nil)!
    pdf.beginPDFPage(nil)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(cgContext: pdf, flipped: false)
    ("Q3 Report" as NSString).draw(at: NSPoint(x: 64, y: 680), withAttributes: [
        .font: NSFont.systemFont(ofSize: 44, weight: .bold), .foregroundColor: color(0x1D2B4F),
    ])
    for (index, value) in [0.45, 0.62, 0.38, 0.8, 0.7].enumerated() {
        color(index == 3 ? 0x2E62EE : 0x38D3C4).setFill()
        NSBezierPath(roundedRect: NSRect(x: 80 + CGFloat(index) * 96, y: 330, width: 64, height: 300 * value), xRadius: 8, yRadius: 8).fill()
    }
    color(0xC5CEDD).setFill()
    for line in 0..<5 {
        NSBezierPath(roundedRect: NSRect(x: 64, y: 250 - CGFloat(line) * 36, width: line == 4 ? 300 : 484, height: 14), xRadius: 7, yRadius: 7).fill()
    }
    NSGraphicsContext.restoreGraphicsState()
    pdf.endPDFPage()
    pdf.closePDF()
}

// MARK: - 合成

/// アプリで撮ったシェルフのコマ（場面ごと）
struct Scenes {
    private var frames: [String: [NSImage]] = [:]

    init(directory: URL) throws {
        let files = try FileManager.default.contentsOfDirectory(atPath: directory.path).filter { $0.hasSuffix(".png") }.sorted()
        for file in files {
            let scene = String(file.split(separator: "-")[0])
            let image = NSImage(contentsOf: directory.appendingPathComponent(file))!
            frames[scene, default: []].append(image)
        }
    }

    /// 場面が始まってから elapsed 秒後のコマ（30fps で撮っている）
    func frame(_ scene: String, at elapsed: Double = .infinity) -> NSImage {
        let list = frames[scene]!
        let index = elapsed.isFinite ? Int(max(0, elapsed) * 30) : list.count - 1
        return list[min(index, list.count - 1)]
    }
}

func easeInOut(_ t: Double) -> Double {
    let t = min(max(t, 0), 1)
    return t * t * (3 - 2 * t)
}

func lerp(_ a: NSPoint, _ b: NSPoint, _ t: Double) -> NSPoint {
    NSPoint(x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t)
}

/// 時刻 t の位置を、(時刻, 位置) の区間を順にたどって求める
func path(_ keyframes: [(Double, NSPoint)], at t: Double) -> NSPoint {
    guard let first = keyframes.first else { return .zero }
    if t <= first.0 { return first.1 }
    for (from, to) in zip(keyframes, keyframes.dropFirst()) where t <= to.0 {
        return lerp(from.1, to.1, easeInOut((t - from.0) / (to.0 - from.0)))
    }
    return keyframes.last!.1
}

func drawCursor(at tip: NSPoint, pressed: Bool) {
    let scale: CGFloat = pressed ? 0.88 : 1
    let points: [NSPoint] = [(0, 0), (0, 19), (4.6, 14.8), (7.7, 22), (10.5, 20.8), (7.5, 13.8), (13.6, 13.8)]
        .map { NSPoint(x: tip.x + $0.0 * scale, y: tip.y + $0.1 * scale) }
    let arrow = NSBezierPath()
    arrow.move(to: points[0])
    points.dropFirst().forEach { arrow.line(to: $0) }
    arrow.close()
    arrow.lineJoinStyle = .round
    arrow.lineWidth = 2.6
    NSColor.white.setStroke()
    arrow.stroke()
    NSColor.black.setFill()
    arrow.fill()
}

/// ドラッグ中のファイル（重なったサムネイルと件数のバッジ）
func drawDraggedItems(_ thumbnails: [NSImage], at cursor: NSPoint) {
    let origin = NSPoint(x: cursor.x + 6, y: cursor.y + 12)
    for (index, image) in thumbnails.prefix(3).enumerated().reversed() {
        let offset = CGFloat(index) * 5
        image.draw(
            in: NSRect(x: origin.x + offset, y: origin.y + offset, width: 46, height: 46),
            from: .zero, operation: .sourceOver, fraction: 0.85, respectFlipped: true, hints: nil
        )
    }
    let badge = NSRect(x: origin.x + 36, y: origin.y - 6, width: 18, height: 18)
    color(0xFF3B30).setFill()
    NSBezierPath(ovalIn: badge).fill()
    let count = "\(thumbnails.count)" as NSString
    let attributes: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 11, weight: .bold), .foregroundColor: NSColor.white]
    let size = count.size(withAttributes: attributes)
    count.draw(at: NSPoint(x: badge.midX - size.width / 2, y: badge.midY - size.height / 2), withAttributes: attributes)
}

func drawShelf(_ image: NSImage, center: NSPoint, alpha: CGFloat) {
    guard alpha > 0 else { return }
    let rect = NSRect(x: center.x - image.size.width / 2, y: center.y - image.size.height / 2, width: image.size.width, height: image.size.height)
    NSGraphicsContext.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.35 * alpha)
    shadow.shadowBlurRadius = 22
    shadow.shadowOffset = NSSize(width: 0, height: -8)
    shadow.set()
    image.draw(in: rect, from: .zero, operation: .sourceOver, fraction: alpha, respectFlipped: true, hints: nil)
    NSGraphicsContext.restoreGraphicsState()
}

func drawFolder(_ icon: NSImage, center: NSPoint, highlighted: Bool) {
    if highlighted {
        color(0x1D2B4F, alpha: 0.14).setFill()
        NSBezierPath(roundedRect: NSRect(x: center.x - 42, y: center.y - 42, width: 84, height: 84), xRadius: 14, yRadius: 14).fill()
    }
    icon.draw(in: NSRect(x: center.x - 32, y: center.y - 32, width: 64, height: 64), from: .zero, operation: .sourceOver, fraction: 1, respectFlipped: true, hints: nil)
}

let background = color(0xDDE7F3)

/// ドラッグ中に表示するサムネイル（写真は画像そのもの、ほかはファイルのアイコン）
func dragThumbnails(samples: URL) -> [NSImage] {
    ["Photo.png", "Report.pdf", "Notes.txt", "Assets"].map { name in
        let url = samples.appendingPathComponent(name)
        return NSImage(contentsOf: url).flatMap { name.hasSuffix(".png") ? $0 : nil } ?? NSWorkspace.shared.icon(forFile: url.path)
    }
}

/// SNS などでリンクを共有したときに出る画像（GitHub の推奨は 1280×640）
func makeSocialPreview(frames framesDirectory: URL, samples: URL, icon iconURL: URL, output: URL) throws {
    let scenes = try Scenes(directory: framesDirectory)
    let icon = NSImage(contentsOf: iconURL)!
    let rep = drawBitmap(width: 1280, height: 640) {
        let full = NSRect(x: 0, y: 0, width: 1280, height: 640)
        NSGradient(starting: color(0x2FC4C0), ending: color(0x2C55E0))!.draw(in: full, angle: -35)

        icon.draw(in: NSRect(x: 72, y: 84, width: 168, height: 168), from: .zero, operation: .sourceOver, fraction: 1, respectFlipped: true, hints: nil)

        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.18)
        shadow.shadowBlurRadius = 8
        shadow.shadowOffset = NSSize(width: 0, height: -2)
        func text(_ string: String, size: CGFloat, weight: NSFont.Weight, alpha: CGFloat, y: CGFloat) {
            (string as NSString).draw(at: NSPoint(x: 86, y: y), withAttributes: [
                .font: NSFont.systemFont(ofSize: size, weight: weight),
                .foregroundColor: NSColor.white.withAlphaComponent(alpha),
                .shadow: shadow,
            ])
        }
        text("TmpSquare", size: 92, weight: .heavy, alpha: 1, y: 270)
        text("振れば出てくる、ファイルの一時置き場。", size: 32, weight: .bold, alpha: 1, y: 398)
        text("Shake to open a temporary spot for your files.", size: 22, weight: .semibold, alpha: 0.95, y: 452)
        text("macOS ・ 無料 ・ オープンソース  /  Free & open source", size: 19, weight: .medium, alpha: 0.8, y: 526)

        // 実際のシェルフ（一覧表示を奥、重ね表示を手前）と、ドラッグしてくるファイル
        let scale: CGFloat = 1.3
        func shelf(_ image: NSImage, center: NSPoint) {
            let size = NSSize(width: image.size.width * scale, height: image.size.height * scale)
            NSGraphicsContext.saveGraphicsState()
            let shelfShadow = NSShadow()
            shelfShadow.shadowColor = NSColor.black.withAlphaComponent(0.35)
            shelfShadow.shadowBlurRadius = 30
            shelfShadow.shadowOffset = NSSize(width: 0, height: -12)
            shelfShadow.set()
            image.draw(
                in: NSRect(x: center.x - size.width / 2, y: center.y - size.height / 2, width: size.width, height: size.height),
                from: .zero, operation: .sourceOver, fraction: 1, respectFlipped: true, hints: nil
            )
            NSGraphicsContext.restoreGraphicsState()
        }
        shelf(scenes.frame("expand"), center: NSPoint(x: 1070, y: 268))
        shelf(scenes.frame("drop"), center: NSPoint(x: 850, y: 372))

        let cursor = NSPoint(x: 1010, y: 470)
        drawDraggedItems(dragThumbnails(samples: samples), at: cursor)
        drawCursor(at: cursor, pressed: true)
    }
    try writePNG(rep, to: output)
    print("✓ \(output.path)")
}

func compose(frames framesDirectory: URL, samples: URL, output: URL, suffix: String) throws {
    let scenes = try Scenes(directory: framesDirectory)
    try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)

    let folderIcon = NSWorkspace.shared.icon(for: .folder)
    let thumbnails = dragThumbnails(samples: samples)

    // 配置（左上原点）
    let width = 640, height = 380
    let shelfCenter = NSPoint(x: 320, y: 190)
    let sourceFolder = NSPoint(x: 80, y: 104)
    let destinationFolder = NSPoint(x: 560, y: 278)
    let stackPoint = NSPoint(x: 318, y: 160)
    let toggleButton = NSPoint(x: 430 - 49, y: 62 + 19)

    // 時刻ごとの場面（秒）
    let cursorPath: [(Double, NSPoint)] = [
        (0.0, NSPoint(x: 70, y: 98)), (0.35, NSPoint(x: 80, y: 104)),
        (1.15, NSPoint(x: 320, y: 186)),
        // 1.15〜1.8 はシェイク（下で計算）
        (1.8, NSPoint(x: 320, y: 186)), (2.05, NSPoint(x: 326, y: 196)),
        (3.1, NSPoint(x: 326, y: 196)), (3.55, stackPoint),
        (4.35, stackPoint), (4.95, toggleButton),
        (5.95, toggleButton), (6.4, stackPoint),
        (6.55, stackPoint), (7.45, NSPoint(x: 556, y: 272)),
        (8.8, NSPoint(x: 556, y: 272)),
    ]
    let duration = 8.8
    let fps = 20.0

    func render(at t: Double) -> NSBitmapImageRep {
        drawBitmap(width: width, height: height) {
            background.setFill()
            NSRect(x: 0, y: 0, width: width, height: height).fill()

            var cursor = path(cursorPath, at: t)
            if t > 1.15 && t < 1.8 {
                // 左右に振る（振った範囲の中心にシェルフが出る）
                let phase = (t - 1.15) / 0.26 * 2 * .pi
                cursor.x = 320 + 78 * sin(phase)
                cursor.y = 186 + 5 * sin(phase * 2)
            }
            let isDraggingIn = t >= 0.35 && t < 2.6
            let isDraggingOut = t >= 6.55 && t < 7.45
            let pressed = isDraggingIn || isDraggingOut || (t >= 3.65 && t < 3.75) || (t >= 5.05 && t < 5.15)

            drawFolder(folderIcon, center: sourceFolder, highlighted: t < 0.45)
            drawFolder(folderIcon, center: destinationFolder, highlighted: t >= 7.1 && t < 7.7)

            // シェルフ: 振っている途中で現れ、ドロップ・一覧表示・重ね表示を経て、取り出すと閉じる
            let shelf: NSImage?
            var alpha: CGFloat = 1
            switch t {
            case ..<1.55: shelf = nil
            case ..<2.05:
                shelf = scenes.frame("empty")
                alpha = CGFloat(min(1, (t - 1.55) / 0.18))
            case ..<2.6: shelf = scenes.frame("target", at: t - 2.05)
            case ..<3.75: shelf = scenes.frame("drop", at: t - 2.6)
            case ..<5.15: shelf = scenes.frame("expand", at: t - 3.75)
            case ..<7.45: shelf = scenes.frame("collapse", at: t - 5.15)
            default:
                shelf = scenes.frame("collapse")
                alpha = CGFloat(max(0, 1 - (t - 7.45) / 0.18))
            }
            if let shelf {
                drawShelf(shelf, center: shelfCenter, alpha: alpha)
            }

            if isDraggingIn || isDraggingOut {
                drawDraggedItems(thumbnails, at: cursor)
            }
            drawCursor(at: cursor, pressed: pressed)
        }
    }

    // 同じ絵が続くコマはまとめて、表示時間を延ばす
    var frames: [(image: CGImage, data: Data, delay: Double)] = []
    for index in 0..<Int(duration * fps) {
        let rep = render(at: Double(index) / fps)
        let data = rep.representation(using: .png, properties: [:])!
        if let last = frames.last, last.data == data {
            frames[frames.count - 1].delay += 1 / fps
        } else {
            frames.append((rep.cgImage!, data, 1 / fps))
        }
    }

    let gifURL = output.appendingPathComponent("demo\(suffix).gif")
    let destination = CGImageDestinationCreateWithURL(gifURL as CFURL, UTType.gif.identifier as CFString, frames.count, nil)!
    CGImageDestinationSetProperties(destination, [
        kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFLoopCount: 0],
    ] as CFDictionary)
    for frame in frames {
        CGImageDestinationAddImage(destination, frame.image, [
            kCGImagePropertyGIFDictionary: [
                kCGImagePropertyGIFDelayTime: frame.delay,
                kCGImagePropertyGIFUnclampedDelayTime: frame.delay,
            ],
        ] as CFDictionary)
    }
    guard CGImageDestinationFinalize(destination) else { throw CocoaError(.fileWriteUnknown) }
    print("✓ \(gifURL.path)（\(frames.count) コマ）")

    // 空・重ね表示・一覧表示を並べたスクリーンショット
    let states = [scenes.frame("empty"), scenes.frame("drop"), scenes.frame("expand")]
    let gap: CGFloat = 40
    let shelfSize = states[0].size
    let screenshots = drawBitmap(
        width: Int(CGFloat(states.count) * shelfSize.width + CGFloat(states.count + 1) * gap),
        height: Int(shelfSize.height + gap * 2)
    ) {
        background.setFill()
        NSRect(x: 0, y: 0, width: 10_000, height: 10_000).fill()
        for (index, image) in states.enumerated() {
            let center = NSPoint(
                x: gap + shelfSize.width / 2 + CGFloat(index) * (shelfSize.width + gap),
                y: gap + shelfSize.height / 2
            )
            drawShelf(image, center: center, alpha: 1)
        }
    }
    let screenshotsURL = output.appendingPathComponent("screenshots\(suffix).png")
    try writePNG(screenshots, to: screenshotsURL)
    print("✓ \(screenshotsURL.path)")
}

switch arguments.dropFirst().first {
case "samples" where arguments.count == 3:
    try makeSamples(in: URL(fileURLWithPath: arguments[2]))
case "compose" where arguments.count == 5 || arguments.count == 6:
    try compose(
        frames: URL(fileURLWithPath: arguments[2]),
        samples: URL(fileURLWithPath: arguments[3]),
        output: URL(fileURLWithPath: arguments[4]),
        suffix: arguments.count == 6 ? arguments[5] : ""
    )
case "social" where arguments.count == 6:
    try makeSocialPreview(
        frames: URL(fileURLWithPath: arguments[2]),
        samples: URL(fileURLWithPath: arguments[3]),
        icon: URL(fileURLWithPath: arguments[4]),
        output: URL(fileURLWithPath: arguments[5])
    )
default:
    print("使い方: swift scripts/make-demo.swift samples <dir> | compose <frames> <samples> <out> [<suffix>] | social <frames> <samples> <icon> <out>")
    exit(1)
}
