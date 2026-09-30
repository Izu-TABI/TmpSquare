import Foundation

/// ドロップされた画像・ファイルプロミス・ZIP などを保存する一時領域。起動時に掃除する。
enum TempStore {
    static let root: URL = {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        return caches
            .appendingPathComponent(Bundle.main.bundleIdentifier ?? "TmpSquare", isDirectory: true)
            .appendingPathComponent("Items", isDirectory: true)
    }()

    /// 項目ごとに専用のディレクトリを作る（元のファイル名をそのまま使えるように）
    static func makeDirectory() throws -> URL {
        let directory = root.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    static func purge() {
        try? FileManager.default.removeItem(at: root)
    }
}
