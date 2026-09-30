import AppKit

/// 1 つのシェルフのウィンドウを管理する
@MainActor
final class ShelfController {
    let model = ShelfModel()
    let panel: ShelfPanel
    var onClose: ((ShelfController) -> Void)?

    private var isClosing = false

    init(frame: NSRect) {
        panel = ShelfPanel(contentRect: frame)
        panel.contentView = ShelfContainerView(model: model, size: frame.size)
        panel.onCancel = { [weak self] in self?.close() }
        model.onRequestClose = { [weak self] in self?.close() }
    }

    func show() {
        panel.alphaValue = 0
        panel.orderFrontRegardless()
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.18
            panel.animator().alphaValue = 1
        }
    }

    func close() {
        guard !isClosing else { return }
        isClosing = true
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.15
            panel.animator().alphaValue = 0
        }, completionHandler: { [weak self] in
            MainActor.assumeIsolated {
                guard let self else { return }
                self.panel.orderOut(nil)
                self.onClose?(self)
            }
        })
    }

    /// シェイクで開いた直後、手が止まりきらずにカーソルが左右にはみ出しそうになったら、
    /// シェルフを横にずらしてカーソルの下に保つ（ドラッグ中の短い間だけ）
    func followCursorWhileSettling(for duration: TimeInterval = 0.5) {
        let deadline = ProcessInfo.processInfo.systemUptime + duration
        let timer = Timer(timeInterval: 1.0 / 60.0, repeats: true) { [weak self] timer in
            MainActor.assumeIsolated {
                guard let self, !self.isClosing,
                      NSEvent.pressedMouseButtons & 1 != 0,
                      ProcessInfo.processInfo.systemUptime < deadline
                else {
                    timer.invalidate()
                    return
                }
                let frame = Self.frame(self.panel.frame, keepingInside: NSEvent.mouseLocation)
                if frame.origin != self.panel.frame.origin {
                    self.panel.setFrameOrigin(frame.origin)
                }
            }
        }
        // ドラッグ中のイベントトラッキングループでも動くよう common モードに登録
        RunLoop.main.add(timer, forMode: .common)
    }

    /// カーソルを中心にしたフレーム（画面からはみ出さないように調整）
    static func frame(centeredAt point: NSPoint) -> NSRect {
        let size = ShelfMetrics.size
        let frame = NSRect(
            x: point.x - size.width / 2,
            y: point.y - size.height / 2,
            width: size.width,
            height: size.height
        )
        return clampedToScreen(frame, containing: point)
    }

    /// カーソルが左右の端から margin 以上内側に来るよう、フレームを横にずらす
    static func frame(_ frame: NSRect, keepingInside cursor: NSPoint, margin: CGFloat = 32) -> NSRect {
        var frame = frame
        if cursor.x < frame.minX + margin {
            frame.origin.x = cursor.x - margin
        } else if cursor.x > frame.maxX - margin {
            frame.origin.x = cursor.x + margin - frame.width
        }
        return clampedToScreen(frame, containing: cursor)
    }

    private static func clampedToScreen(_ frame: NSRect, containing point: NSPoint) -> NSRect {
        var frame = frame
        let screen = NSScreen.screens.first { $0.frame.contains(point) } ?? NSScreen.main
        if let visible = screen?.visibleFrame {
            let margin: CGFloat = 8
            frame.origin.x = min(max(frame.minX, visible.minX + margin), visible.maxX - frame.width - margin)
            frame.origin.y = min(max(frame.minY, visible.minY + margin), visible.maxY - frame.height - margin)
        }
        return frame
    }
}
