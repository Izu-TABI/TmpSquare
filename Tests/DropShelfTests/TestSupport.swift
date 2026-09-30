import AppKit

/// テストごとに独立した一時ディレクトリ
func makeTemporaryDirectory() throws -> URL {
    let directory = FileManager.default.temporaryDirectory
        .appendingPathComponent("DropShelfTests", isDirectory: true)
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    return directory
}

func makeFile(named name: String, in directory: URL, contents: String = "test") throws -> URL {
    let url = directory.appendingPathComponent(name)
    try contents.write(to: url, atomically: true, encoding: .utf8)
    return url
}

/// システムのクリップボードを汚さないよう、テスト専用の名前付きペーストボードを使う
func makePasteboard() -> NSPasteboard {
    let pasteboard = NSPasteboard(name: NSPasteboard.Name("DropShelfTests.\(UUID().uuidString)"))
    pasteboard.clearContents()
    return pasteboard
}
