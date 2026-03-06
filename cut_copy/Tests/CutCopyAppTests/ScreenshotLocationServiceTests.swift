import Foundation
import XCTest
@testable import CutCopyApp

final class ScreenshotLocationServiceTests: XCTestCase {
    func testEnsureDefaultDirectoryCreatesPicturesCutCopyShots() throws {
        let fakeHome = try makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: fakeHome) }

        let service = ScreenshotLocationService(
            commandRunner: CommandRunnerSpy(),
            homeDirectoryProvider: { fakeHome }
        )

        let directory = try service.ensureDefaultDirectoryExists()

        XCTAssertEqual(directory.path, fakeHome.appendingPathComponent("Pictures/CutCopyShots").path)
        XCTAssertTrue(FileManager.default.fileExists(atPath: directory.path))
    }

    func testConfigureSystemLocationRunsDefaultsAndKillall() throws {
        let runner = CommandRunnerSpy()
        let service = ScreenshotLocationService(commandRunner: runner)
        let directory = try makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }

        try service.configureSystemLocation(to: directory)

        XCTAssertEqual(runner.calls.count, 2)
        XCTAssertEqual(runner.calls[0].launchPath, "/usr/bin/defaults")
        XCTAssertEqual(runner.calls[0].arguments, ["write", "com.apple.screencapture", "location", directory.path])
        XCTAssertEqual(runner.calls[1].launchPath, "/usr/bin/killall")
        XCTAssertEqual(runner.calls[1].arguments, ["SystemUIServer"])
    }

    private func makeTempDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}

private final class CommandRunnerSpy: CommandRunning {
    struct Call {
        let launchPath: String
        let arguments: [String]
    }

    var calls: [Call] = []

    @discardableResult
    func run(_ launchPath: String, arguments: [String]) throws -> String {
        calls.append(Call(launchPath: launchPath, arguments: arguments))
        return ""
    }
}
