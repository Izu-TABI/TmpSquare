import AppKit

/// クロージャで動作を指定できる NSMenuItem
final class ClosureMenuItem: NSMenuItem {
    private let handler: () -> Void

    init(_ title: String, systemImage: String? = nil, handler: @escaping () -> Void) {
        self.handler = handler
        super.init(title: title, action: #selector(performHandler), keyEquivalent: "")
        target = self
        if let systemImage {
            image = NSImage(systemSymbolName: systemImage, accessibilityDescription: nil)
        }
    }

    @available(*, unavailable)
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func performHandler() {
        handler()
    }
}

@MainActor
func presentError(_ error: Error) {
    NSApp.activate()
    NSAlert(error: error).runModal()
}
