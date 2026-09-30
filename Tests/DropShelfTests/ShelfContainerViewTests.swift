import AppKit
import Testing
@testable import DropShelf

@MainActor
struct ShelfContainerViewTests {
    private func makeShelf(expanded: Bool = false, items: [ShelfItem] = []) -> (ShelfContainerView, ShelfModel, NSWindow) {
        _ = NSApplication.shared
        let model = ShelfModel()
        model.add(items)
        model.isExpanded = expanded
        let container = ShelfContainerView(model: model, size: ShelfMetrics.size)
        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: ShelfMetrics.size),
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        window.isReleasedWhenClosed = false
        window.contentView = container
        container.layoutSubtreeIfNeeded()
        window.displayIfNeeded()
        return (container, model, window)
    }

    private func descendants(of view: NSView) -> [NSView] {
        view.subviews.flatMap { [$0] + descendants(of: $0) }
    }

    @Test(arguments: [false, true])
    func subviewsDoNotShadowTheDropTarget(expanded: Bool) {
        let (container, _, window) = makeShelf(expanded: expanded, items: [ShelfItem(text: "a"), ShelfItem(text: "b")])
        defer { window.close() }

        #expect(!container.registeredDraggedTypes.isEmpty)
        // SwiftUI 内のドラッグ用ビューまで実際に生成された状態で検査する
        let subviews = descendants(of: container)
        #expect(subviews.contains { $0 is DragSourceView })
        // 子ビューがドラッグ型を登録していると、その上ではシェルフにドロップできなくなる
        let shadowing = subviews.filter { !$0.registeredDraggedTypes.isEmpty }
        #expect(shadowing.isEmpty, "\(shadowing.map { type(of: $0) })")
    }

    @Test func acceptsFilesFromOtherApps() throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let file = try makeFile(named: "report.pdf", in: directory)
        let pasteboard = makePasteboard()
        pasteboard.writeObjects([file as NSURL])

        let (container, model, window) = makeShelf()
        defer { window.close() }
        let drag = FakeDraggingInfo(pasteboard: pasteboard, mask: [.copy, .move, .generic])

        #expect(container.draggingEntered(drag) == .copy)
        #expect(model.isDropTargeted)
        #expect(container.performDragOperation(drag))
        #expect(!model.isDropTargeted)
        #expect(model.items.map(\.fileURL) == [file])
    }

    @Test func neverAsksTheSourceToMoveFiles() {
        let pasteboard = makePasteboard()
        pasteboard.writeObjects(["text" as NSString])
        let (container, _, window) = makeShelf()
        defer { window.close() }

        // .move を返すとドラッグ元がファイルを削除してしまうので、移動しか許さないドラッグは受け付けない
        #expect(container.draggingEntered(FakeDraggingInfo(pasteboard: pasteboard, mask: .move)) == [])
        #expect(container.draggingEntered(FakeDraggingInfo(pasteboard: pasteboard, mask: [.move, .generic])) == .generic)
    }

    @Test func rejectsDragsFromTheSameShelf() {
        let item = ShelfItem(text: "item")
        let (container, model, window) = makeShelf(items: [item])
        defer { window.close() }
        let pasteboard = makePasteboard()
        pasteboard.writeObjects([item.pasteboardWriter])

        let ownSource = DragSourceView()
        ownSource.model = model
        let ownDrag = FakeDraggingInfo(pasteboard: pasteboard, mask: [.copy, .generic], source: ownSource)
        #expect(container.draggingEntered(ownDrag) == [])
        #expect(!container.performDragOperation(ownDrag))
        #expect(model.items.count == 1)

        // 別のシェルフからのドラッグは受け付ける
        let otherModel = ShelfModel()
        let otherSource = DragSourceView()
        otherSource.model = otherModel
        let otherDrag = FakeDraggingInfo(pasteboard: pasteboard, mask: [.copy, .generic], source: otherSource)
        #expect(container.draggingEntered(otherDrag) == .copy)
    }
}

/// テスト用の NSDraggingInfo
private final class FakeDraggingInfo: NSObject, NSDraggingInfo {
    let draggingPasteboard: NSPasteboard
    let draggingSourceOperationMask: NSDragOperation
    let draggingSource: Any?

    init(pasteboard: NSPasteboard, mask: NSDragOperation, source: Any? = nil) {
        draggingPasteboard = pasteboard
        draggingSourceOperationMask = mask
        draggingSource = source
    }

    var draggingDestinationWindow: NSWindow? { nil }
    var draggingLocation: NSPoint { .zero }
    var draggedImageLocation: NSPoint { .zero }
    var draggedImage: NSImage? { nil }
    var draggingSequenceNumber: Int { 1 }
    var draggingFormation: NSDraggingFormation = .default
    var animatesToDestination = false
    var numberOfValidItemsForDrop = 1
    var springLoadingHighlight: NSSpringLoadingHighlight { .none }

    func slideDraggedImage(to screenPoint: NSPoint) {}
    func resetSpringLoading() {}
    func enumerateDraggingItems(
        options enumOpts: NSDraggingItemEnumerationOptions = [],
        for view: NSView?,
        classes classArray: [AnyClass],
        searchOptions: [NSPasteboard.ReadingOptionKey: Any] = [:],
        using block: (NSDraggingItem, Int, UnsafeMutablePointer<ObjCBool>) -> Void
    ) {}
}
