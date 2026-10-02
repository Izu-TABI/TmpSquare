import AppKit

/// メニューバーのアイコンとメニュー
@MainActor
final class StatusMenuController: NSObject, NSMenuDelegate {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let shelves: ShelfManager
    private let onSettingsChanged: () -> Void
    private let onShowGuide: () -> Void

    init(shelves: ShelfManager, onSettingsChanged: @escaping () -> Void, onShowGuide: @escaping () -> Void) {
        self.shelves = shelves
        self.onSettingsChanged = onSettingsChanged
        self.onShowGuide = onShowGuide
        super.init()

        statusItem.button?.image = StatusIcon.make()

        let menu = NSMenu()
        menu.autoenablesItems = false
        menu.delegate = self
        statusItem.menu = menu
    }

    // 開くたびに現在の設定を反映して作り直す
    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        let settings = Settings.shared

        let newShelf = ClosureMenuItem(L("新しいシェルフ"), systemImage: "plus.rectangle.on.rectangle") { [shelves] in
            shelves.openShelf(at: NSEvent.mouseLocation)
        }
        newShelf.keyEquivalent = " "
        newShelf.keyEquivalentModifierMask = [.option, .shift]
        menu.addItem(newShelf)

        let closeAll = ClosureMenuItem(L("すべてのシェルフを閉じる"), systemImage: "xmark.rectangle") { [shelves] in
            shelves.closeAll()
        }
        closeAll.isEnabled = shelves.hasOpenShelves
        menu.addItem(closeAll)

        menu.addItem(.separator())

        let shake = ClosureMenuItem(L("ドラッグ中のシェイクで開く")) { [weak self] in
            settings.shakeToOpen.toggle()
            self?.onSettingsChanged()
        }
        shake.state = settings.shakeToOpen ? .on : .off
        menu.addItem(shake)

        let sensitivity = NSMenuItem(title: L("シェイクの感度"), action: nil, keyEquivalent: "")
        sensitivity.submenu = makeSensitivityMenu()
        sensitivity.isEnabled = settings.shakeToOpen
        menu.addItem(sensitivity)

        let removeAfterDrag = ClosureMenuItem(L("ドラッグアウトした項目をシェルフから外す")) {
            settings.removeAfterDragOut.toggle()
        }
        removeAfterDrag.state = settings.removeAfterDragOut ? .on : .off
        menu.addItem(removeAfterDrag)

        menu.addItem(.separator())

        let login = ClosureMenuItem(L("ログイン時に起動")) {
            LoginItem.setEnabled(!LoginItem.isEnabled)
        }
        login.state = LoginItem.isEnabled ? .on : .off
        menu.addItem(login)

        menu.addItem(.separator())

        menu.addItem(ClosureMenuItem(L("使い方"), systemImage: "questionmark.circle") { [weak self] in
            self?.onShowGuide()
        })
        menu.addItem(ClosureMenuItem(L("TmpSquare について")) {
            NSApp.activate()
            NSApp.orderFrontStandardAboutPanel(nil)
        })
        let quit = NSMenuItem(title: L("TmpSquare を終了"), action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        quit.target = NSApp
        menu.addItem(quit)
    }

    private func makeSensitivityMenu() -> NSMenu {
        let menu = NSMenu()
        let current = Settings.shared.shakeSensitivity
        for level in ShakeSensitivity.allCases {
            let item = ClosureMenuItem(level.title) {
                Settings.shared.shakeSensitivity = level
            }
            item.state = level == current ? .on : .off
            menu.addItem(item)
        }
        return menu
    }
}
