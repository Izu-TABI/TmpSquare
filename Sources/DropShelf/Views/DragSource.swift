import AppKit
import SwiftUI

/// SwiftUI の上に重ねる透明なビュー。ドラッグアウト・クリック・ホバー・右クリックを AppKit で処理する
///
/// SwiftUI の onDrag は 1 項目しか扱えないため、複数ファイルをまとめてドラッグできるよう AppKit を使う。
struct DragSource: NSViewRepresentable {
    let model: ShelfModel
    let items: () -> [ShelfItem]
    var onClick: (() -> Void)? = nil
    var onDoubleClick: (() -> Void)? = nil
    var onHover: ((Bool) -> Void)? = nil

    func makeNSView(context: Context) -> DragSourceView {
        DragSourceView()
    }

    func updateNSView(_ view: DragSourceView, context: Context) {
        view.model = model
        view.itemsProvider = items
        view.onClick = onClick
        view.onDoubleClick = onDoubleClick
        view.onHover = onHover
    }
}

final class DragSourceView: NSView, NSDraggingSource {
    weak var model: ShelfModel?
    var itemsProvider: () -> [ShelfItem] = { [] }
    var onClick: (() -> Void)?
    var onDoubleClick: (() -> Void)?
    var onHover: ((Bool) -> Void)?

    private var mouseDownEvent: NSEvent?
    private var draggedItems: [ShelfItem] = []

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
    override var mouseDownCanMoveWindow: Bool { false }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        trackingAreas.forEach(removeTrackingArea)
        addTrackingArea(NSTrackingArea(
            rect: .zero,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self
        ))
    }

    override func mouseEntered(with event: NSEvent) { onHover?(true) }
    override func mouseExited(with event: NSEvent) { onHover?(false) }

    override func mouseDown(with event: NSEvent) {
        mouseDownEvent = event
    }

    override func mouseDragged(with event: NSEvent) {
        guard let start = mouseDownEvent else { return }
        let distance = hypot(
            event.locationInWindow.x - start.locationInWindow.x,
            event.locationInWindow.y - start.locationInWindow.y
        )
        guard distance >= 4 else { return }
        mouseDownEvent = nil
        beginDrag(anchoredAt: start, event: event)
    }

    override func mouseUp(with event: NSEvent) {
        guard mouseDownEvent != nil else { return }
        mouseDownEvent = nil
        if event.clickCount == 2 {
            onDoubleClick?()
        } else if event.clickCount == 1 {
            onClick?()
        }
    }

    override func menu(for event: NSEvent) -> NSMenu? {
        guard let model else { return nil }
        let items = itemsProvider()
        return items.isEmpty ? nil : ShelfMenu.make(for: items, in: model)
    }

    private func beginDrag(anchoredAt mouseDown: NSEvent, event: NSEvent) {
        let items = itemsProvider()
        guard !items.isEmpty else { return }

        let anchor = convert(mouseDown.locationInWindow, from: nil)
        let draggingItems = items.enumerated().map { index, item in
            let draggingItem = NSDraggingItem(pasteboardWriter: item.pasteboardWriter)
            let size = Self.fittedSize(for: item.thumbnail.size)
            // 複数項目は少しずつずらして重ねる
            let offset = CGFloat(min(index, 3)) * 6
            draggingItem.setDraggingFrame(
                NSRect(
                    x: anchor.x - size.width / 2 + offset,
                    y: anchor.y - size.height / 2 - offset,
                    width: size.width,
                    height: size.height
                ),
                contents: item.thumbnail
            )
            return draggingItem
        }

        draggedItems = items
        let session = beginDraggingSession(with: draggingItems, event: event, source: self)
        session.animatesToStartingPositionsOnCancelOrFail = true
    }

    private static func fittedSize(for size: NSSize, maxSide: CGFloat = 72) -> NSSize {
        guard size.width > 0, size.height > 0 else { return NSSize(width: maxSide, height: maxSide) }
        let scale = maxSide / max(size.width, size.height)
        return NSSize(width: size.width * scale, height: size.height * scale)
    }

    // MARK: - NSDraggingSource

    func draggingSession(_ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation {
        // Finder と同じく、同じボリュームなら移動・⌥ でコピーになる
        context == .outsideApplication ? [.copy, .move, .link, .generic] : [.copy, .generic]
    }

    func draggingSession(_ session: NSDraggingSession, endedAt screenPoint: NSPoint, operation: NSDragOperation) {
        model?.dragEnded(items: draggedItems, operation: operation)
        draggedItems = []
    }
}
