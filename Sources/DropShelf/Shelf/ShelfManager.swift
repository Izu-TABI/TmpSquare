import AppKit

/// 開いているシェルフの一覧を管理する
@MainActor
final class ShelfManager {
    private var controllers: [ShelfController] = []

    var hasOpenShelves: Bool { !controllers.isEmpty }

    @discardableResult
    func openShelf(at point: NSPoint) -> ShelfController {
        var frame = ShelfController.frame(centeredAt: point)
        // 既存のシェルフとぴったり重ならないよう少しずらす
        var attempts = 0
        while attempts < 8, controllers.contains(where: { $0.panel.frame.origin == frame.origin }) {
            frame = frame.offsetBy(dx: 24, dy: -24)
            attempts += 1
        }

        let controller = ShelfController(frame: frame)
        controller.onClose = { [weak self] closed in
            self?.controllers.removeAll { $0 === closed }
        }
        controllers.append(controller)
        controller.show()
        return controller
    }

    func closeAll() {
        for controller in controllers {
            controller.close()
        }
    }
}
