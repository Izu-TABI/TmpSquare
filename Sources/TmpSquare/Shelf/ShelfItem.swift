import AppKit
import QuickLookThumbnailing
import UniformTypeIdentifiers

/// シェルフに置かれた 1 項目
@MainActor
final class ShelfItem: ObservableObject, Identifiable {
    enum Payload {
        case file(URL)
        case link(URL)
        case text(String)
    }

    let id = UUID()
    let payload: Payload
    let displayName: String
    let detail: String?
    @Published private(set) var thumbnail: NSImage
    /// QuickLook のプレビュー画像が取れたか（取れなければファイルアイコンのまま）
    @Published private(set) var hasPreview = false

    init(file url: URL) {
        payload = .file(url)
        displayName = url.lastPathComponent
        detail = Self.fileDetail(for: url)
        thumbnail = NSWorkspace.shared.icon(forFile: url.path)
        loadPreview(for: url)
    }

    init(link url: URL) {
        payload = .link(url)
        displayName = url.host() ?? url.absoluteString
        detail = url.absoluteString
        let weblocType = UTType("com.apple.web-internet-location") ?? .url
        thumbnail = NSWorkspace.shared.icon(for: weblocType)
    }

    init(text: String) {
        payload = .text(text)
        let firstLine = text.split(whereSeparator: \.isNewline).first.map(String.init) ?? text
        displayName = firstLine.trimmingCharacters(in: .whitespaces)
        detail = Localization.textDetail(characters: text.count)
        thumbnail = NSWorkspace.shared.icon(for: .plainText)
    }

    var fileURL: URL? {
        if case .file(let url) = payload { return url }
        return nil
    }

    /// ドラッグアウトで移動されるなどして、元のファイルがなくなったか
    var isMissing: Bool {
        guard let fileURL else { return false }
        return !FileManager.default.fileExists(atPath: fileURL.path)
    }

    /// ドラッグやコピーでペーストボードに書き出す内容
    var pasteboardWriter: NSPasteboardWriting {
        switch payload {
        case .file(let url), .link(let url): url as NSURL
        case .text(let text): text as NSString
        }
    }

    var shareItem: Any {
        switch payload {
        case .file(let url), .link(let url): url
        case .text(let text): text
        }
    }

    private static func fileDetail(for url: URL) -> String? {
        let values = try? url.resourceValues(forKeys: [.isDirectoryKey, .fileSizeKey, .localizedTypeDescriptionKey])
        if values?.isDirectory != true, let size = values?.fileSize {
            return ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file)
        }
        return values?.localizedTypeDescription
    }

    private func loadPreview(for url: URL) {
        let request = QLThumbnailGenerator.Request(
            fileAt: url,
            size: CGSize(width: 160, height: 160),
            scale: NSScreen.main?.backingScaleFactor ?? 2,
            representationTypes: .thumbnail
        )
        QLThumbnailGenerator.shared.generateBestRepresentation(for: request) { [weak self] representation, _ in
            guard let image = representation?.nsImage else { return }
            Task { @MainActor in
                self?.thumbnail = image
                self?.hasPreview = true
            }
        }
    }
}
