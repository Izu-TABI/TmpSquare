import AppKit
import SwiftUI

/// この領域をドラッグするとシェルフのウィンドウ自体を移動できる
struct WindowDragHandle: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        HandleView()
    }

    func updateNSView(_ nsView: NSView, context: Context) {}

    private final class HandleView: NSView {
        override var mouseDownCanMoveWindow: Bool { true }
        override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

        override func mouseDown(with event: NSEvent) {
            window?.performDrag(with: event)
        }
    }
}
