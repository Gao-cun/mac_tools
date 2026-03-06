import Foundation
import XCTest
@testable import CutCopyApp

final class ScreenshotFileFilterTests: XCTestCase {
    func testAcceptsImageFileExtensions() throws {
        let dir = try makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: dir) }

        let png = dir.appendingPathComponent("a.png")
        let txt = dir.appendingPathComponent("a.txt")
        try Data("x".utf8).write(to: png)
        try Data("x".utf8).write(to: txt)

        let filter = ScreenshotFileFilter()
        XCTAssertTrue(filter.isScreenshotFile(png))
        XCTAssertFalse(filter.isScreenshotFile(txt))
    }

    private func makeTempDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}
