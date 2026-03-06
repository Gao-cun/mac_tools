import XCTest
@testable import CutCopyApp

final class DirectorySnapshotTrackerTests: XCTestCase {
    func testReturnsOnlyNewFiles() {
        let tracker = DirectorySnapshotTracker()
        let file1 = URL(fileURLWithPath: "/tmp/a.png")
        let file2 = URL(fileURLWithPath: "/tmp/b.png")
        let file3 = URL(fileURLWithPath: "/tmp/c.png")

        tracker.seed(with: [file1, file2])
        let first = tracker.newFiles(from: [file1, file2, file3])
        let second = tracker.newFiles(from: [file1, file2, file3])

        XCTAssertEqual(first, [file3])
        XCTAssertTrue(second.isEmpty)
    }
}
