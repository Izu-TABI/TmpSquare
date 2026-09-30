import AppKit

/// 項目に対する操作
@MainActor
enum ItemActions {
    static func open(_ items: [ShelfItem]) {
        for item in items {
            switch item.payload {
            case .file(let url), .link(let url): NSWorkspace.shared.open(url)
            case .text: break
            }
        }
    }

    static func reveal(_ items: [ShelfItem]) {
        let urls = items.compactMap(\.fileURL)
        guard !urls.isEmpty else { return }
        NSWorkspace.shared.activateFileViewerSelecting(urls)
    }

    /// Finder でペーストできる形でコピーする
    static func copy(_ items: [ShelfItem]) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects(items.map(\.pasteboardWriter))
    }

    static func copyPaths(_ items: [ShelfItem]) {
        let lines = items.compactMap { item -> String? in
            switch item.payload {
            case .file(let url): url.path
            case .link(let url): url.absoluteString
            case .text: nil
            }
        }
        guard !lines.isEmpty else { return }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(lines.joined(separator: "\n"), forType: .string)
    }

    /// ファイルを ZIP にまとめ、シェルフ上の元の項目を ZIP に置き換える
    static func compress(_ items: [ShelfItem], in model: ShelfModel) {
        let fileItems = items.filter { $0.fileURL != nil }
        let urls = fileItems.compactMap(\.fileURL)
        guard !urls.isEmpty else { return }

        model.isWorking = true
        Task {
            defer { model.isWorking = false }
            do {
                let archive = try await Archiver.zip(urls)
                model.remove(fileItems)
                model.add([ShelfItem(file: archive)])
            } catch {
                presentError(error)
            }
        }
    }
}
