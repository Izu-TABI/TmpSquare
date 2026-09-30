import AppKit

/// メニューバーのアイコン。アプリアイコンと同じ「点線の四角に置かれた書類」の絵
///
/// SF Symbols はロゴとしての使用が禁止されているので、図形をここで描く。
/// テンプレート画像にして、メニューバーの明暗に合わせて色が変わるようにする。
enum StatusIcon {
    static func make() -> NSImage {
        let image = NSImage(size: NSSize(width: 18, height: 18), flipped: false) { _ in
            drawDashedSquare()
            drawCard()
            return true
        }
        image.isTemplate = true
        image.accessibilityDescription = "TmpSquare"
        return image
    }

    private static func drawDashedSquare() {
        let rect = NSRect(x: 1.75, y: 1.75, width: 14.5, height: 14.5)
        let radius: CGFloat = 4

        // 上辺の中央から一周させ、一周を 4 の倍数で割って模様を上下左右で対称にする
        let path = NSBezierPath()
        path.move(to: NSPoint(x: rect.midX, y: rect.maxY))
        path.appendArc(from: NSPoint(x: rect.maxX, y: rect.maxY), to: NSPoint(x: rect.maxX, y: rect.minY), radius: radius)
        path.appendArc(from: NSPoint(x: rect.maxX, y: rect.minY), to: NSPoint(x: rect.minX, y: rect.minY), radius: radius)
        path.appendArc(from: NSPoint(x: rect.minX, y: rect.minY), to: NSPoint(x: rect.minX, y: rect.maxY), radius: radius)
        path.appendArc(from: NSPoint(x: rect.minX, y: rect.maxY), to: NSPoint(x: rect.midX, y: rect.maxY), radius: radius)
        path.close()

        let perimeter = 4 * (rect.width - 2 * radius) + 2 * .pi * radius
        let unit = perimeter / 12
        var dash: [CGFloat] = [unit * 0.6, unit * 0.4]
        path.setLineDash(&dash, count: 2, phase: dash[0] / 2)
        path.lineWidth = 1.5
        NSColor.black.setStroke()
        path.stroke()
    }

    private static func drawCard() {
        let center = NSPoint(x: 9, y: 9)
        NSGraphicsContext.saveGraphicsState()
        let transform = NSAffineTransform()
        transform.translateX(by: center.x, yBy: center.y)
        transform.rotate(byDegrees: -6)
        transform.translateX(by: -center.x, yBy: -center.y)
        transform.concat()

        let card = NSRect(x: center.x - 3.5, y: center.y - 4.5, width: 7, height: 9)
        NSColor.black.setFill()
        NSBezierPath(roundedRect: card, xRadius: 1.3, yRadius: 1.3).fill()

        // 右上の折り返しを抜いて書類らしくする
        NSGraphicsContext.current?.compositingOperation = .destinationOut
        let fold = NSBezierPath()
        fold.move(to: NSPoint(x: card.maxX - 2.6, y: card.maxY + 0.1))
        fold.line(to: NSPoint(x: card.maxX + 0.1, y: card.maxY + 0.1))
        fold.line(to: NSPoint(x: card.maxX + 0.1, y: card.maxY - 2.6))
        fold.close()
        fold.fill()
        NSGraphicsContext.restoreGraphicsState()
    }
}
