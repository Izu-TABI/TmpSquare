import AppKit
import Testing
@testable import DropShelf

@MainActor
struct ItemImporterTests {
    @Test func importsFileURLsWithoutDuplicates() throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let first = try makeFile(named: "企画書.txt", in: directory)
        let second = try makeFile(named: "memo.txt", in: directory)

        let pasteboard = makePasteboard()
        pasteboard.writeObjects([first as NSURL, second as NSURL])
        let model = ShelfModel()

        #expect(ItemImporter.importItems(from: pasteboard, into: model))
        #expect(model.items.map(\.fileURL) == [first, second])
        #expect(model.items.first?.displayName == "企画書.txt")

        // 同じファイルをもう一度ドロップしても増えない
        ItemImporter.importItems(from: pasteboard, into: model)
        #expect(model.items.count == 2)
    }

    @Test func importsWebLink() throws {
        let pasteboard = makePasteboard()
        pasteboard.writeObjects([URL(string: "https://www.apple.com/jp/")! as NSURL])
        let model = ShelfModel()

        #expect(ItemImporter.importItems(from: pasteboard, into: model))
        let item = try #require(model.items.first)
        guard case .link(let url) = item.payload else {
            Issue.record("リンクとして取り込まれていない: \(item.payload)")
            return
        }
        #expect(url.absoluteString == "https://www.apple.com/jp/")
        #expect(item.displayName == "www.apple.com")
    }

    @Test func importsTextAndIgnoresBlankText() throws {
        let pasteboard = makePasteboard()
        let model = ShelfModel()

        pasteboard.writeObjects(["  \n" as NSString])
        #expect(!ItemImporter.importItems(from: pasteboard, into: model))
        #expect(model.items.isEmpty)

        pasteboard.clearContents()
        pasteboard.writeObjects(["こんにちは\n2 行目" as NSString])
        #expect(ItemImporter.importItems(from: pasteboard, into: model))
        let item = try #require(model.items.first)
        guard case .text(let text) = item.payload else {
            Issue.record("テキストとして取り込まれていない: \(item.payload)")
            return
        }
        #expect(text == "こんにちは\n2 行目")
        #expect(item.displayName == "こんにちは")
    }

    @Test func savesImageDataAsPNGFile() throws {
        let image = NSImage(size: NSSize(width: 8, height: 8), flipped: false) { rect in
            NSColor.systemRed.setFill()
            rect.fill()
            return true
        }
        let pasteboard = makePasteboard()
        pasteboard.writeObjects([image])
        let model = ShelfModel()

        #expect(ItemImporter.importItems(from: pasteboard, into: model))
        let url = try #require(model.items.first?.fileURL)
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        #expect(url.pathExtension == "png")
        #expect(NSImage(contentsOf: url) != nil)
    }

    @Test func emptyPasteboardCannotBeImported() {
        #expect(!ItemImporter.canImport(makePasteboard()))
    }
}
