import AppKit
import SwiftUI

/// シェルフのルートビュー。背景（ガラス／すりガラス）と SwiftUI の中身を持ち、ドロップを受け付ける
final class ShelfContainerView: NSView {
    private let model: ShelfModel

    init(model: ShelfModel, size: NSSize) {
        self.model = model
        super.init(frame: NSRect(origin: .zero, size: size))

        let hostingView = NSHostingView(rootView: ShelfView(model: model))
        hostingView.sizingOptions = []
        hostingView.frame = bounds
        hostingView.autoresizingMask = [.width, .height]

        let background = Self.makeBackground(containing: hostingView, frame: bounds)
        background.autoresizingMask = [.width, .height]
        addSubview(background)

        // ウィンドウの影は中身の形から作られる。ガラスは角の外側にも描画するので、
        // 角丸で切り抜かないと影が長方形になり、角に黒い枠が見えてしまう
        wantsLayer = true
        layer?.cornerRadius = ShelfMetrics.cornerRadius
        layer?.cornerCurve = .continuous
        layer?.masksToBounds = true

        registerForDraggedTypes(ItemImporter.acceptedTypes)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private static func makeBackground(containing content: NSView, frame: NSRect) -> NSView {
        if #available(macOS 26.0, *) {
            let glass = NSGlassEffectView(frame: frame)
            glass.cornerRadius = ShelfMetrics.cornerRadius
            glass.contentView = content
            return glass
        }

        let effect = NSVisualEffectView(frame: frame)
        effect.material = .popover
        effect.blendingMode = .behindWindow
        effect.state = .active
        effect.maskImage = roundedMask(radius: ShelfMetrics.cornerRadius)
        effect.addSubview(content)
        return effect
    }

    private static func roundedMask(radius: CGFloat) -> NSImage {
        let edge = radius * 2 + 1
        let image = NSImage(size: NSSize(width: edge, height: edge), flipped: false) { rect in
            NSColor.black.setFill()
            NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius).fill()
            return true
        }
        image.capInsets = NSEdgeInsets(top: radius, left: radius, bottom: radius, right: radius)
        image.resizingMode = .stretch
        return image
    }

    // MARK: - NSDraggingDestination

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        updateDropTarget(for: sender)
    }

    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        updateDropTarget(for: sender)
    }

    override func draggingExited(_ sender: NSDraggingInfo?) {
        model.isDropTargeted = false
    }

    override func draggingEnded(_ sender: NSDraggingInfo) {
        model.isDropTargeted = false
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        model.isDropTargeted = false
        guard !isDraggedFromThisShelf(sender) else { return false }
        return ItemImporter.importItems(from: sender.draggingPasteboard, into: model)
    }

    private func updateDropTarget(for sender: NSDraggingInfo) -> NSDragOperation {
        guard !isDraggedFromThisShelf(sender), ItemImporter.canImport(sender.draggingPasteboard) else {
            model.isDropTargeted = false
            return []
        }
        model.isDropTargeted = true

        // シェルフは参照を持つだけなので、ドラッグ元のファイルが移動・削除されない操作を返す
        let mask = sender.draggingSourceOperationMask
        if mask.contains(.copy) { return .copy }
        if mask.contains(.generic) { return .generic }
        if mask.contains(.link) { return .link }
        return []
    }

    private func isDraggedFromThisShelf(_ sender: NSDraggingInfo) -> Bool {
        (sender.draggingSource as? DragSourceView)?.model === model
    }
}
