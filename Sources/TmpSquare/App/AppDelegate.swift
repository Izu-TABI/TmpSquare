import AppKit
import Carbon.HIToolbox

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let shelves = ShelfManager()
    private let shakeMonitor = DragShakeMonitor()
    private var statusMenu: StatusMenuController?
    private var hotKey: HotKey?

    func applicationDidFinishLaunching(_ notification: Notification) {
        TempStore.purge()

        statusMenu = StatusMenuController(shelves: shelves) { [weak self] in
            self?.applySettings()
        }

        shakeMonitor.onShake = { [weak self] location in
            self?.shelves.openShelf(at: location).followCursorWhileSettling()
        }

        // ⌥⇧Space でカーソル位置に新しいシェルフを開く
        hotKey = HotKey(keyCode: UInt32(kVK_Space), modifiers: UInt32(optionKey | shiftKey)) { [weak self] in
            self?.shelves.openShelf(at: NSEvent.mouseLocation)
        }

        applySettings()

        #if DEBUG
        DebugSupport.openShelfIfRequested(using: shelves)
        #endif
    }

    /// 起動中に Finder などからもう一度アプリを開いたら、シェルフを 1 つ開く
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        shelves.openShelf(at: NSEvent.mouseLocation)
        return false
    }

    private func applySettings() {
        if Settings.shared.shakeToOpen {
            shakeMonitor.start()
        } else {
            shakeMonitor.stop()
        }
    }
}
