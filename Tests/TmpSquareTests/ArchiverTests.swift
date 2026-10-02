import Foundation
import Testing
@testable import TmpSquare

struct ArchiverTests {
    @Test func multipleItemsAreZippedAtTheArchiveRoot() async throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let other = directory.appendingPathComponent("other", isDirectory: true)
        try FileManager.default.createDirectory(at: other, withIntermediateDirectories: true)

        let files = [
            try makeFile(named: "a.txt", in: directory),
            try makeFile(named: "same.txt", in: directory),
            try makeFile(named: "same.txt", in: other),
        ]
        let zip = try await Archiver.zip(files)
        defer { try? FileManager.default.removeItem(at: zip.deletingLastPathComponent()) }

        #expect(zip.lastPathComponent == L("アーカイブ") + ".zip")
        // 同名ファイルは Finder と同じく「名前 2」にして両方残す
        #expect(try extract(zip) == ["a.txt", "same 2.txt", "same.txt"])
    }

    @Test func singleItemKeepsItsName() async throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let folder = directory.appendingPathComponent("資料", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        _ = try makeFile(named: "memo.txt", in: folder)

        let zip = try await Archiver.zip([folder])
        defer { try? FileManager.default.removeItem(at: zip.deletingLastPathComponent()) }

        #expect(zip.lastPathComponent == "資料.zip")
        #expect(try extract(zip) == ["資料"])
    }

    /// ZIP を展開して、最上位の項目名を返す
    private func extract(_ zip: URL) throws -> [String] {
        let destination = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: destination) }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
        process.arguments = ["-x", "-k", zip.path, destination.path]
        try process.run()
        process.waitUntilExit()
        return try FileManager.default.contentsOfDirectory(atPath: destination.path)
            .filter { !$0.hasPrefix(".") }
            .sorted()
    }
}
