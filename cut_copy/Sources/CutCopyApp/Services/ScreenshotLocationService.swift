import Foundation

protocol CommandRunning {
    @discardableResult
    func run(_ launchPath: String, arguments: [String]) throws -> String
}

struct ProcessRunner: CommandRunning {
    @discardableResult
    func run(_ launchPath: String, arguments: [String]) throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: launchPath)
        process.arguments = arguments

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        try process.run()
        process.waitUntilExit()

        let output = String(data: outputPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        let errorOutput = String(data: errorPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""

        guard process.terminationStatus == 0 else {
            throw NSError(
                domain: "cutcopy.command",
                code: Int(process.terminationStatus),
                userInfo: [NSLocalizedDescriptionKey: errorOutput.isEmpty ? "命令执行失败: \(launchPath)" : errorOutput]
            )
        }
        return output
    }
}

final class ScreenshotLocationService {
    private let fileManager: FileManager
    private let commandRunner: CommandRunning
    private let homeDirectoryProvider: () -> URL

    init(
        fileManager: FileManager = .default,
        commandRunner: CommandRunning = ProcessRunner(),
        homeDirectoryProvider: @escaping () -> URL = { FileManager.default.homeDirectoryForCurrentUser }
    ) {
        self.fileManager = fileManager
        self.commandRunner = commandRunner
        self.homeDirectoryProvider = homeDirectoryProvider
    }

    func defaultDirectory() -> URL {
        let home = homeDirectoryProvider()
        return home.appendingPathComponent("Pictures/CutCopyShots", isDirectory: true)
    }

    @discardableResult
    func ensureDefaultDirectoryExists() throws -> URL {
        let directory = defaultDirectory()
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    func currentConfiguredDirectory() -> URL? {
        if let location = UserDefaults(suiteName: "com.apple.screencapture")?.string(forKey: "location"),
           !location.isEmpty {
            return URL(fileURLWithPath: location, isDirectory: true)
        }
        return nil
    }

    func configureSystemLocation(to directory: URL) throws {
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        try commandRunner.run(
            "/usr/bin/defaults",
            arguments: ["write", "com.apple.screencapture", "location", directory.path]
        )

        do {
            try commandRunner.run("/usr/bin/killall", arguments: ["SystemUIServer"])
        } catch {
            // If SystemUIServer restart fails, defaults are still persisted and will take effect later.
        }
    }
}
