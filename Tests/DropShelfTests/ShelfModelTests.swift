import AppKit
import Testing
@testable import DropShelf

@MainActor
struct ShelfModelTests {
    @Test func newItemsAreAddedToTheFront() {
        let model = ShelfModel()
        let old = ShelfItem(text: "old")
        let new = ShelfItem(text: "new")
        model.add([old])
        model.add([new])
        #expect(model.items.map(\.id) == [new.id, old.id])
    }

    @Test func draggedOutItemsAreRemovedAndEmptyShelfCloses() {
        let model = ShelfModel()
        var closeRequested = false
        model.onRequestClose = { closeRequested = true }
        let first = ShelfItem(text: "first")
        let second = ShelfItem(text: "second")
        model.add([first, second])

        model.dragEnded(items: [first], operation: .copy, removeDraggedItems: true)
        #expect(model.items.map(\.id) == [second.id])
        #expect(!closeRequested)

        model.dragEnded(items: [second], operation: .move, removeDraggedItems: true)
        #expect(model.items.isEmpty)
        #expect(closeRequested)
    }

    @Test func cancelledDragKeepsItems() {
        let model = ShelfModel()
        let item = ShelfItem(text: "item")
        model.add([item])

        model.dragEnded(items: [item], operation: [], removeDraggedItems: true)
        #expect(model.items.count == 1)
    }

    @Test func movedFilesAreRemovedEvenWhenSettingIsOff() throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let moved = ShelfItem(file: try makeFile(named: "moved.txt", in: directory))
        let kept = ShelfItem(file: try makeFile(named: "kept.txt", in: directory))
        let model = ShelfModel()
        model.add([moved, kept])

        // Finder へのドロップで移動されたことを再現する
        try FileManager.default.removeItem(at: try #require(moved.fileURL))
        model.dragEnded(items: [moved, kept], operation: .move, removeDraggedItems: false)

        #expect(model.items.map(\.id) == [kept.id])
    }
}
