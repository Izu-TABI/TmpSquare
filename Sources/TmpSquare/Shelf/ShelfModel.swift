import AppKit

/// 1 つのシェルフの状態
@MainActor
final class ShelfModel: ObservableObject {
    /// 先頭ほど新しい（スタック表示では先頭が一番上）
    @Published private(set) var items: [ShelfItem] = []
    @Published var isDropTargeted = false
    @Published var isExpanded = false
    @Published var isWorking = false

    var onRequestClose: (() -> Void)?

    func add(_ newItems: [ShelfItem]) {
        var seen = Set(items.compactMap { $0.fileURL?.standardizedFileURL })
        let unique = newItems.filter { item in
            guard let url = item.fileURL?.standardizedFileURL else { return true }
            return seen.insert(url).inserted
        }
        guard !unique.isEmpty else { return }
        items.insert(contentsOf: unique, at: 0)
    }

    func remove(_ removed: [ShelfItem]) {
        let ids = Set(removed.map(\.id))
        items.removeAll { ids.contains($0.id) }
        if items.isEmpty { isExpanded = false }
    }

    func requestClose() {
        onRequestClose?()
    }

    /// シェルフからのドラッグが終わったときに呼ばれる
    /// - Parameter removeDraggedItems: 省略時は設定の「ドラッグアウトした項目をシェルフから外す」に従う
    func dragEnded(items dragged: [ShelfItem], operation: NSDragOperation, removeDraggedItems: Bool? = nil) {
        guard !operation.isEmpty else { return }
        let removeAll = removeDraggedItems ?? Settings.shared.removeAfterDragOut
        // 設定がオフでも、移動されて存在しなくなったファイルは外す
        let toRemove = dragged.filter { removeAll || $0.isMissing }
        guard !toRemove.isEmpty else { return }
        remove(toRemove)
        if items.isEmpty { requestClose() }
    }
}
