import Foundation
import XCTest
@testable import CutCopyApp

final class CleanupServiceTests: XCTestCase {
    func testMovesOnlyScreenshotFilesToTrashHandler() throws {
        let tempDir = try makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let screenshot = tempDir.appendingPathComponent("s1.png")
        let textFile = tempDir.appendingPathComponent("note.txt")
        try Data("x".utf8).write(to: screenshot)
        try Data("x".utf8).write(to: textFile)

        var trashed: [URL] = []
        let service = CleanupService(trashHandler: { url in
            trashed.append(url)
        })

        let result = service.clearScreenshots(in: tempDir)

        XCTAssertEqual(result.totalCount, 1)
        XCTAssertEqual(result.successCount, 1)
        XCTAssertEqual(result.failureCount, 0)
        XCTAssertEqual(
            trashed.map { $0.standardizedFileURL.path },
            [screenshot.standardizedFileURL.path]
        )
    }

    private func makeTempDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}
