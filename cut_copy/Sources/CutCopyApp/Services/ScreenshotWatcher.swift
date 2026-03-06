import Dispatch
import Darwin
import Foundation

final class ScreenshotWatcher: @unchecked Sendable {
    typealias Handler = (URL) -> Void

    private let queue = DispatchQueue(label: "cutcopy.screenshot.watcher")
    private let filter: ScreenshotFileFilter
    private let snapshotTracker = DirectorySnapshotTracker()

    private var source: DispatchSourceFileSystemObject?
    private var directoryFileDescriptor: CInt = -1
    private var watchedDirectory: URL?
    private var handler: Handler?

    init(filter: ScreenshotFileFilter = ScreenshotFileFilter()) {
        self.filter = filter
    }

    deinit {
        stopWatching()
    }

    func startWatching(directory: URL, handler: @escaping Handler) {
        self.handler = handler
        queue.async {
            self.stopWatchingLocked(clearHandler: false)
            self.watchedDirectory = directory
            self.seedSnapshot(for: directory)
            self.openSource(for: directory)
        }
    }

    func stopWatching() {
        queue.async {
            self.stopWatchingLocked()
        }
    }

    private func stopWatchingLocked(clearHandler: Bool = true) {
        if let source {
            source.cancel()
            self.source = nil
        } else if directoryFileDescriptor >= 0 {
            close(directoryFileDescriptor)
        }
        directoryFileDescriptor = -1
        watchedDirectory = nil
        if clearHandler {
            handler = nil
        }
    }

    private func seedSnapshot(for directory: URL) {
        let files = listScreenshotFiles(in: directory)
        snapshotTracker.seed(with: files)
    }

    private func openSource(for directory: URL) {
        let fd = open(directory.path, O_EVTONLY)
        guard fd >= 0 else {
            return
        }
        directoryFileDescriptor = fd

        let newSource = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: [.write, .rename, .delete, .extend],
            queue: queue
        )

        newSource.setEventHandler { [weak self] in
            self?.scanDirectoryForNewFiles()
        }

        newSource.setCancelHandler { [fd] in
            if fd >= 0 {
                close(fd)
            }
        }

        source = newSource
        newSource.resume()
    }

    private func scanDirectoryForNewFiles() {
        guard let watchedDirectory else { return }
        let files = listScreenshotFiles(in: watchedDirectory)
        let newFiles = snapshotTracker.newFiles(from: files)
        for file in newFiles {
            checkStabilityAndHandle(file)
        }
    }

    private func checkStabilityAndHandle(_ fileURL: URL) {
        let firstSize = fileSize(of: fileURL)
        queue.asyncAfter(deadline: .now() + .milliseconds(220)) { [weak self] in
            guard let self else { return }
            let secondSize = self.fileSize(of: fileURL)
            guard firstSize > 0, firstSize == secondSize else {
                return
            }
            self.handler?(fileURL)
        }
    }

    private func fileSize(of url: URL) -> Int64 {
        guard let values = try? url.resourceValues(forKeys: [.fileSizeKey]),
              let size = values.fileSize else {
            return 0
        }
        return Int64(size)
    }

    private func listScreenshotFiles(in directory: URL) -> [URL] {
        guard let urls = try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.contentModificationDateKey, .isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        return urls
            .filter { filter.isScreenshotFile($0) }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
    }
}
