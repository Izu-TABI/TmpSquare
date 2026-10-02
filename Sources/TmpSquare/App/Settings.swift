import AppKit
import ServiceManagement

enum ShakeSensitivity: Int, CaseIterable {
    case low, medium, high

    var title: String {
        switch self {
        case .low: L("弱い")
        case .medium: L("標準")
        case .high: L("強い")
        }
    }
}

@MainActor
final class Settings {
    static let shared = Settings()

    private let defaults = UserDefaults.standard

    private enum Key {
        static let shakeToOpen = "ShakeToOpen"
        static let shakeSensitivity = "ShakeSensitivity"
        static let removeAfterDragOut = "RemoveAfterDragOut"
    }

    private init() {
        defaults.register(defaults: [
            Key.shakeToOpen: true,
            Key.shakeSensitivity: ShakeSensitivity.medium.rawValue,
            Key.removeAfterDragOut: true,
        ])
    }

    /// ドラッグ中にカーソルをシェイクしたらシェルフを開く
    var shakeToOpen: Bool {
        get { defaults.bool(forKey: Key.shakeToOpen) }
        set { defaults.set(newValue, forKey: Key.shakeToOpen) }
    }

    var shakeSensitivity: ShakeSensitivity {
        get { ShakeSensitivity(rawValue: defaults.integer(forKey: Key.shakeSensitivity)) ?? .medium }
        set { defaults.set(newValue.rawValue, forKey: Key.shakeSensitivity) }
    }

    /// シェルフからドラッグアウトした項目をシェルフから外す（空になったシェルフは閉じる）
    var removeAfterDragOut: Bool {
        get { defaults.bool(forKey: Key.removeAfterDragOut) }
        set { defaults.set(newValue, forKey: Key.removeAfterDragOut) }
    }
}

@MainActor
enum LoginItem {
    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    static func setEnabled(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            presentError(error)
        }
        // 初めて登録したときなど、システム設定で許可が必要な場合はその画面を開く
        if SMAppService.mainApp.status == .requiresApproval {
            SMAppService.openSystemSettingsLoginItems()
        }
    }
}
