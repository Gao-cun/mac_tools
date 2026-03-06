import AppKit
import XCTest
@testable import CutCopyApp

final class ClipboardServiceTests: XCTestCase {
    func testCopyImageSuccessAndDedup() throws {
        let tempImageFile = try createTempImage()
        defer { try? FileManager.default.removeItem(at: tempImageFile.deletingLastPathComponent()) }

        var writeCount = 0
        let service = ClipboardService(
            processedStore: ProcessedScreenshotStore(),
            imageLoader: { _ in NSImage(size: NSSize(width: 10, height: 10)) },
            pasteboardWriter: { _ in
                writeCount += 1
                return true
            }
        )

        let first = try service.copyImage(at: tempImageFile)
        let second = try service.copyImage(at: tempImageFile)

        XCTAssertTrue(first)
        XCTAssertFalse(second)
        XCTAssertEqual(writeCount, 1)
    }

    func testCopyImageThrowsWhenImageLoadFails() throws {
        let tempImageFile = try createTempImage()
        defer { try? FileManager.default.removeItem(at: tempImageFile.deletingLastPathComponent()) }

        let service = ClipboardService(
            processedStore: ProcessedScreenshotStore(),
            imageLoader: { _ in nil },
            pasteboardWriter: { _ in true }
        )

        XCTAssertThrowsError(try service.copyImage(at: tempImageFile))
    }

    func testCopyImageThrowsWhenPasteboardWriteFails() throws {
        let tempImageFile = try createTempImage()
        defer { try? FileManager.default.removeItem(at: tempImageFile.deletingLastPathComponent()) }

        let service = ClipboardService(
            processedStore: ProcessedScreenshotStore(),
            imageLoader: { _ in NSImage(size: NSSize(width: 10, height: 10)) },
            pasteboardWriter: { _ in false }
        )

        XCTAssertThrowsError(try service.copyImage(at: tempImageFile))
    }

    private func createTempImage() throws -> URL {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let fileURL = dir.appendingPathComponent("sample.png")
        try Data([0x89, 0x50, 0x4E, 0x47]).write(to: fileURL)
        return fileURL
    }
}
