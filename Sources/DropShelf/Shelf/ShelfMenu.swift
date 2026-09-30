import AppKit

/// 右クリックと「…」ボタンで出すアクションメニュー
@MainActor
enum ShelfMenu {
    static func make(for items: [ShelfItem], in model: ShelfModel) -> NSMenu {
        let menu = NSMenu()
        let hasFiles = items.contains { $0.fileURL != nil }
        let hasOpenable = items.contains {
            if case .text = $0.payload { return false }
            return true
        }
        let countSuffix = items.count > 1 ? "（\(items.count) 項目）" : ""

        if hasOpenable {
            menu.addItem(ClosureMenuItem("開く", systemImage: "arrow.up.forward.app") {
                ItemActions.open(items)
            })
        }
        if hasFiles {
            menu.addItem(ClosureMenuItem("Finder で表示", systemImage: "folder") {
                ItemActions.reveal(items)
            })
        }
        menu.addItem(NSSharingServicePicker(items: items.map(\.shareItem)).standardShareMenuItem)

        menu.addItem(.separator())

        menu.addItem(ClosureMenuItem("コピー", systemImage: "doc.on.doc") {
            ItemActions.copy(items)
        })
        if hasOpenable {
            menu.addItem(ClosureMenuItem("パスをコピー", systemImage: "link") {
                ItemActions.copyPaths(items)
            })
        }

        if hasFiles {
            menu.addItem(.separator())
            menu.addItem(ClosureMenuItem("ZIP に圧縮" + countSuffix, systemImage: "doc.zipper") {
                ItemActions.compress(items, in: model)
            })
        }

        menu.addItem(.separator())
        menu.addItem(ClosureMenuItem("シェルフから外す" + countSuffix, systemImage: "minus.circle") {
            model.remove(items)
        })

        return menu
    }
}
