import AppKit
import Carbon.HIToolbox

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let shelves = ShelfManager()
    private let shakeMonitor = DragShakeMonitor()
    private let welcome = WelcomeWindowController()
    private var statusMenu: StatusMenuController?
    private var hotKey: HotKey?

    func applicationDidFinishLaunching(_ notification: Notification) {
        TempStore.purge()

        statusMenu = StatusMenuController(
            shelves: shelves,
            onSettingsChanged: { [weak self] in self?.applySettings() },
            onShowGuide: { [weak self] in self?.welcome.show() }
        )
        welcome.onOpenShelf = { [weak self] in
            guard let screen = NSScreen.main else { return }
            self?.shelves.openShelf(at: NSPoint(x: screen.visibleFrame.midX, y: screen.visibleFrame.midY))
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
        if DebugSupport.handleLaunchOptions(shelves: shelves, welcome: welcome) { return }
        #endif
        // メニューバーにしか出ないので、初めての起動では使い方を案内する
        welcome.showIfFirstLaunch()
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
