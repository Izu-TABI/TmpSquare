import Foundation

/// Finder の「圧縮」と同じ形式で ZIP を作る
enum Archiver {
    enum Failure: LocalizedError {
        case dittoFailed(Int32)

        var errorDescription: String? {
            switch self {
            case .dittoFailed(let status): Localization.zipFailed(status: status)
            }
        }
    }

    static func zip(_ urls: [URL]) async throws -> URL {
        try await Task.detached(priority: .userInitiated) {
            try makeZip(urls)
        }.value
    }

    private static func makeZip(_ urls: [URL]) throws -> URL {
        let fileManager = FileManager.default
        let directory = try TempStore.makeDirectory()

        if urls.count == 1, let url = urls.first {
            let zipURL = directory.appendingPathComponent(url.lastPathComponent + ".zip")
            try ditto(["-c", "-k", "--sequesterRsrc", "--keepParent", url.path, zipURL.path])
            return zipURL
        }

        // 複数項目は一度まとめてから圧縮する（APFS ではクローンなのでコピーは速い）
        let staging = directory.appendingPathComponent("staging", isDirectory: true)
        try fileManager.createDirectory(at: staging, withIntermediateDirectories: true)
        for url in urls {
            try fileManager.copyItem(at: url, to: uniqueURL(for: url.lastPathComponent, in: staging))
        }
        let zipURL = directory.appendingPathComponent(L("アーカイブ") + ".zip")
        try ditto(["-c", "-k", "--sequesterRsrc", staging.path, zipURL.path])
        try? fileManager.removeItem(at: staging)
        return zipURL
    }

    private static func uniqueURL(for name: String, in directory: URL) -> URL {
        let candidate = directory.appendingPathComponent(name)
        guard FileManager.default.fileExists(atPath: candidate.path) else { return candidate }

        let base = (name as NSString).deletingPathExtension
        let ext = (name as NSString).pathExtension
        var number = 2
        while true {
            let numbered = ext.isEmpty ? "\(base) \(number)" : "\(base) \(number).\(ext)"
            let url = directory.appendingPathComponent(numbered)
            if !FileManager.default.fileExists(atPath: url.path) { return url }
            number += 1
        }
    }

    private static func ditto(_ arguments: [String]) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
        process.arguments = arguments
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            throw Failure.dittoFailed(process.terminationStatus)
        }
    }
}
