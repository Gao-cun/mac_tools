import XCTest
@testable import CutCopyApp

final class ProcessedScreenshotStoreTests: XCTestCase {
    func testRejectsDuplicatePathAndTimestamp() {
        let store = ProcessedScreenshotStore()
        let now = Date()

        let first = store.markIfUnseen(path: "/tmp/s1.png", modifiedAt: now)
        let second = store.markIfUnseen(path: "/tmp/s1.png", modifiedAt: now)

        XCTAssertTrue(first)
        XCTAssertFalse(second)
    }

    func testAcceptsSamePathWithDifferentTimestamp() {
        let store = ProcessedScreenshotStore()
        let now = Date()
        let later = now.addingTimeInterval(1)

        XCTAssertTrue(store.markIfUnseen(path: "/tmp/s1.png", modifiedAt: now))
        XCTAssertTrue(store.markIfUnseen(path: "/tmp/s1.png", modifiedAt: later))
    }
}
