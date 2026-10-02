import AppKit

/// ドロップされたペーストボードの中身をシェルフの項目に変換する
@MainActor
enum ItemImporter {
    static var acceptedTypes: [NSPasteboard.PasteboardType] {
        let basic: [NSPasteboard.PasteboardType] = [.fileURL, .URL, .string]
        let images = NSImage.imageTypes.map { NSPasteboard.PasteboardType($0) }
        let promises = NSFilePromiseReceiver.readableDraggedTypes.map { NSPasteboard.PasteboardType($0) }
        return basic + images + promises
    }

    static func canImport(_ pasteboard: NSPasteboard) -> Bool {
        pasteboard.canReadObject(
            forClasses: [NSURL.self, NSString.self, NSImage.self, NSFilePromiseReceiver.self],
            options: nil
        )
    }

    /// 優先順位: ファイル > ファイルプロミス > 画像データ > URL > テキスト
    @discardableResult
    static func importItems(from pasteboard: NSPasteboard, into model: ShelfModel) -> Bool {
        if let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) as? [URL],
           !urls.isEmpty {
            model.add(urls.map { ShelfItem(file: $0) })
            return true
        }

        // 写真アプリや Mail の添付ファイルなど、ドロップ後に書き出されるファイル
        if let receivers = pasteboard.readObjects(forClasses: [NSFilePromiseReceiver.self]) as? [NSFilePromiseReceiver],
           !receivers.isEmpty {
            receivePromises(receivers, into: model)
            return true
        }

        if let images = pasteboard.readObjects(forClasses: [NSImage.self]) as? [NSImage], !images.isEmpty {
            let items = images.compactMap(saveImage).map { ShelfItem(file: $0) }
            model.add(items)
            return !items.isEmpty
        }

        if let urls = pasteboard.readObjects(forClasses: [NSURL.self]) as? [URL], !urls.isEmpty {
            model.add(urls.map { ShelfItem(link: $0) })
            return true
        }

        if let strings = pasteboard.readObjects(forClasses: [NSString.self]) as? [String] {
            let texts = strings.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            model.add(texts.map { ShelfItem(text: $0) })
            return !texts.isEmpty
        }

        return false
    }

    private static let promiseQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.qualityOfService = .userInitiated
        return queue
    }()

    private static func receivePromises(_ receivers: [NSFilePromiseReceiver], into model: ShelfModel) {
        for receiver in receivers {
            guard let directory = try? TempStore.makeDirectory() else { continue }
            receiver.receivePromisedFiles(atDestination: directory, options: [:], operationQueue: promiseQueue) { [weak model] url, error in
                guard error == nil else { return }
                Task { @MainActor in
                    model?.add([ShelfItem(file: url)])
                }
            }
        }
    }

    private static func saveImage(_ image: NSImage) -> URL? {
        guard let tiff = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff),
              let png = bitmap.representation(using: .png, properties: [:]),
              let directory = try? TempStore.makeDirectory()
        else { return nil }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH.mm.ss"
        let url = directory.appendingPathComponent("\(L("画像")) \(formatter.string(from: Date())).png")
        do {
            try png.write(to: url)
            return url
        } catch {
            return nil
        }
    }
}
