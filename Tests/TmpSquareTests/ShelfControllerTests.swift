import AppKit
import Testing
@testable import TmpSquare

@MainActor
struct ShelfControllerTests {
    /// 画面の中央付近のシェルフ（画面端での位置調整が効かない場所で試す）
    private func frameNearScreenCenter() -> NSRect {
        let center = NSScreen.main.map { NSPoint(x: $0.visibleFrame.midX, y: $0.visibleFrame.midY) }
            ?? NSPoint(x: 800, y: 500)
        return ShelfController.frame(centeredAt: center)
    }

    @Test func frameStaysWhileCursorIsWellInside() {
        let frame = frameNearScreenCenter()
        let cursor = NSPoint(x: frame.midX + 40, y: frame.midY)
        #expect(ShelfController.frame(frame, keepingInside: cursor) == frame)
    }

    @Test func frameSlidesLeftWhenCursorLeavesTheLeftEdge() {
        let frame = frameNearScreenCenter()
        let cursor = NSPoint(x: frame.minX - 50, y: frame.midY)
        let moved = ShelfController.frame(frame, keepingInside: cursor, margin: 32)
        #expect(moved.minX == cursor.x - 32)
        // 縦位置は変えない
        #expect(moved.minY == frame.minY)
    }

    @Test func frameSlidesRightWhenCursorNearsTheRightEdge() {
        let frame = frameNearScreenCenter()
        let cursor = NSPoint(x: frame.maxX - 10, y: frame.midY)
        let moved = ShelfController.frame(frame, keepingInside: cursor, margin: 32)
        #expect(moved.maxX == cursor.x + 32)
    }
}
