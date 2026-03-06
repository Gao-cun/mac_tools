import Foundation

struct CleanupResult {
    let totalCount: Int
    let successCount: Int
    let failureCount: Int
}

final class CleanupService {
    typealias TrashHandler = (URL) throws -> Void

    private let fileManager: FileManager
    private let filter: ScreenshotFileFilter
    private let trashHandler: TrashHandler

    init(
        fileManager: FileManager = .default,
        filter: ScreenshotFileFilter = ScreenshotFileFilter(),
        trashHandler: TrashHandler? = nil
    ) {
        self.fileManager = fileManager
        self.filter = filter
        if let trashHandler {
            self.trashHandler = trashHandler
        } else {
            self.trashHandler = { url in
                _ = try fileManager.trashItem(at: url, resultingItemURL: nil)
            }
        }
    }

    func clearScreenshots(in directory: URL) -> CleanupResult {
        guard let files = try? fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            return CleanupResult(totalCount: 0, successCount: 0, failureCount: 0)
        }

        let screenshotFiles = files.filter { filter.isScreenshotFile($0) }
        var success = 0
        var failure = 0

        for file in screenshotFiles {
            do {
                try trashHandler(file)
                success += 1
            } catch {
                failure += 1
            }
        }

        return CleanupResult(
            totalCount: screenshotFiles.count,
            successCount: success,
            failureCount: failure
        )
    }
}
