import AppKit

/// 常に手前に浮かび、クリックしても他のアプリからフォーカスを奪わないパネル
final class ShelfPanel: NSPanel {
    var onCancel: (() -> Void)?

    init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        isFloatingPanel = true
        level = .floating
        // すべてのデスクトップ・フルスクリーンアプリの上にも表示する
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        backgroundColor = .clear
        isOpaque = false
        hasShadow = true
        hidesOnDeactivate = false
        isReleasedWhenClosed = false
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    // esc で閉じる
    override func cancelOperation(_ sender: Any?) {
        onCancel?()
    }
}
