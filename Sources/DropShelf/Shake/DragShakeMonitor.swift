import AppKit

/// 他のアプリでファイルなどをドラッグ中に、カーソルがシェイクされたことを検出する
///
/// マウスボタンが押されている間だけカーソル位置をポーリングし、
/// ドラッグ用ペーストボードが更新されていれば（= 何かをドラッグ中なら）シェイク判定を行う。
/// マウスクリックの監視とカーソル位置の取得だけなので、アクセシビリティ権限は不要。
@MainActor
final class DragShakeMonitor {
    var onShake: ((NSPoint) -> Void)?

    private let dragPasteboard = NSPasteboard(name: .drag)
    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var timer: Timer?
    private var changeCountAtMouseDown = 0
    private var detector = ShakeDetector(configuration: .init(.medium))
    private var hasFired = false

    func start() {
        guard globalMonitor == nil else { return }
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDown) { [weak self] _ in
            MainActor.assumeIsolated { self?.mouseDown() }
        }
        // 自分のシェルフからドラッグを始めたときもシェイクで新しいシェルフを開けるようにする
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .leftMouseDown) { [weak self] event in
            MainActor.assumeIsolated { self?.mouseDown() }
            return event
        }
    }

    func stop() {
        if let globalMonitor { NSEvent.removeMonitor(globalMonitor) }
        if let localMonitor { NSEvent.removeMonitor(localMonitor) }
        globalMonitor = nil
        localMonitor = nil
        stopTracking()
    }

    private func mouseDown() {
        changeCountAtMouseDown = dragPasteboard.changeCount
        detector = ShakeDetector(configuration: .init(Settings.shared.shakeSensitivity))
        hasFired = false

        guard timer == nil else { return }
        let timer = Timer(timeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.tick() }
        }
        // ドラッグ中のイベントトラッキングループでも発火するよう common モードに登録
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    private func tick() {
        guard NSEvent.pressedMouseButtons & 1 != 0 else {
            stopTracking()
            return
        }
        guard !hasFired, dragPasteboard.changeCount != changeCountAtMouseDown else { return }

        let location = NSEvent.mouseLocation
        if let centerX = detector.feed(x: location.x, at: ProcessInfo.processInfo.systemUptime) {
            hasFired = true
            onShake?(NSPoint(x: centerX, y: location.y))
        }
    }

    private func stopTracking() {
        timer?.invalidate()
        timer = nil
    }
}
