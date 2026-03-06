import Foundation

final class DirectorySnapshotTracker {
    private var knownPaths: Set<String> = []

    func seed(with files: [URL]) {
        knownPaths = Set(files.map(\.path))
    }

    func newFiles(from files: [URL]) -> [URL] {
        let currentPaths = Set(files.map(\.path))
        let newFiles = files.filter { !knownPaths.contains($0.path) }
        knownPaths = currentPaths
        return newFiles
    }
}
