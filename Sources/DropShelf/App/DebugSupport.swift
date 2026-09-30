#if DEBUG
import AppKit

/// 開発用の起動オプション（画面収録の権限なしで UI を確認するため）
///
///     DropShelf --open-shelf [--expanded] [--dark | --light] [--key] [--shadow] [--drop-later]
///               [--snapshot <out.png>] [--filmstrip <out.png>] <path>...
///
/// 項目入りのシェルフを画面中央に開き、少し待ってからシェルフのウィンドウを PNG に書き出す。
/// - `--snapshot`: 現在の見た目を書き出す
/// - `--filmstrip`: 一覧表示と重ね表示を切り替え、その間のコマを並べて書き出す（アニメーション確認用）
/// - `--drop-later`: 空のシェルフで開き、`--filmstrip` のときに項目を追加する（ドロップ時の動き）
/// - `--key`: シェルフをキーウィンドウにしてから撮る（クリック・ドラッグ中の見た目）
/// - `--shadow`: ウィンドウの影も含めて撮る
@MainActor
enum DebugSupport {
    static func openShelfIfRequested(using shelves: ShelfManager) {
        var arguments = Array(CommandLine.arguments.dropFirst())
        guard arguments.contains("--open-shelf"), let screen = NSScreen.main else { return }

        let snapshotURL = takeValue(of: "--snapshot", from: &arguments).map { URL(fileURLWithPath: $0) }
        let filmstripURL = takeValue(of: "--filmstrip", from: &arguments).map { URL(fileURLWithPath: $0) }
        let includeShadow = arguments.contains("--shadow")
        if arguments.contains("--dark") {
            NSApp.appearance = NSAppearance(named: .darkAqua)
        } else if arguments.contains("--light") {
            NSApp.appearance = NSAppearance(named: .aqua)
        }

        let items = arguments.filter { !$0.hasPrefix("--") }.map { ShelfItem(file: URL(fileURLWithPath: $0)) }
        let dropLater = arguments.contains("--drop-later")
        let shelf = shelves.openShelf(at: NSPoint(x: screen.visibleFrame.midX, y: screen.visibleFrame.midY))
        if !dropLater {
            shelf.model.add(items)
        }
        shelf.model.isExpanded = arguments.contains("--expanded")
        if arguments.contains("--key") {
            shelf.panel.makeKey()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            if let snapshotURL, let image = captureWindow(shelf.panel, includeShadow: includeShadow) {
                writeGrid([image], columns: 1, to: snapshotURL)
            }
            if let filmstripURL {
                recordFilmstrip(of: shelf, includeShadow: includeShadow, to: filmstripURL) {
                    if dropLater {
                        shelf.model.add(items)
                    } else {
                        shelf.model.isExpanded.toggle()
                    }
                }
            }
        }
    }

    private static func takeValue(of option: String, from arguments: inout [String]) -> String? {
        guard let index = arguments.firstIndex(of: option), index + 1 < arguments.count else { return nil }
        let value = arguments[index + 1]
        arguments.removeSubrange(index...index + 1)
        return value
    }

    @MainActor
    private final class FrameBuffer {
        var frames: [CGImage] = []
    }

    /// action（実際のクリックやドロップと同じ変更）を行い、0.45 秒間のコマを 30fps で撮る
    private static func recordFilmstrip(
        of shelf: ShelfController,
        includeShadow: Bool,
        to url: URL,
        action: () -> Void
    ) {
        let buffer = FrameBuffer()
        if let image = captureWindow(shelf.panel, includeShadow: includeShadow) {
            buffer.frames.append(image)
        }
        action()

        let start = ProcessInfo.processInfo.systemUptime
        let timer = Timer(timeInterval: 1.0 / 30.0, repeats: true) { timer in
            MainActor.assumeIsolated {
                if let image = captureWindow(shelf.panel, includeShadow: includeShadow) {
                    buffer.frames.append(image)
                }
                if ProcessInfo.processInfo.systemUptime - start >= 0.45 {
                    timer.invalidate()
                    writeGrid(buffer.frames, columns: 8, to: url)
                }
            }
        }
        RunLoop.main.add(timer, forMode: .common)
    }

    /// 画像を灰色の背景に格子状に並べて PNG に書き出す
    private static func writeGrid(_ images: [CGImage], columns: Int, to url: URL) {
        guard let first = images.first else { return }
        let gap = 12
        let rows = (images.count + columns - 1) / columns
        let usedColumns = min(columns, images.count)
        let width = usedColumns * first.width + (usedColumns + 1) * gap
        let height = rows * first.height + (rows + 1) * gap
        guard let context = CGContext(
            data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return }

        context.setFillColor(CGColor(gray: 0.82, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        for (index, image) in images.enumerated() {
            let x = gap + (index % columns) * (first.width + gap)
            let y = height - (index / columns + 1) * (first.height + gap)
            context.draw(image, in: CGRect(x: x, y: y, width: image.width, height: image.height))
        }
        guard let output = context.makeImage() else { return }
        try? NSBitmapImageRep(cgImage: output).representation(using: .png, properties: [:])?.write(to: url)
    }

    /// 自分のウィンドウを WindowServer から取得する
    /// （CGWindowListCreateImage は SDK 上は使用不可だが実行時には存在するので動的に呼ぶ）
    private static func captureWindow(_ window: NSWindow, includeShadow: Bool) -> CGImage? {
        typealias CreateImage = @convention(c) (CGRect, UInt32, CGWindowID, UInt32) -> Unmanaged<CGImage>?
        guard let symbol = dlsym(UnsafeMutableRawPointer(bitPattern: -2), "CGWindowListCreateImage") else { return nil }
        let createImage = unsafeBitCast(symbol, to: CreateImage.self)
        let includingWindow: UInt32 = 1 << 3
        let boundsIgnoreFraming: UInt32 = 1 << 0
        let bestResolution: UInt32 = 1 << 3
        let options = bestResolution | (includeShadow ? 0 : boundsIgnoreFraming)
        return createImage(.null, includingWindow, CGWindowID(window.windowNumber), options)?.takeRetainedValue()
    }
}
#endif
