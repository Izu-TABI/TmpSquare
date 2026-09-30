import AppKit

@main
@MainActor
enum TmpSquareApp {
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        // メニューバー常駐アプリとして動かす（Info.plist の LSUIElement と同じ効果）
        app.setActivationPolicy(.accessory)
        withExtendedLifetime(delegate) { app.run() }
    }
}
