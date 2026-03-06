import Foundation

final class ProcessedScreenshotStore {
    private let lock = NSLock()
    private var seen: [String: Date] = [:]

    func markIfUnseen(path: String, modifiedAt: Date) -> Bool {
        let signature = "\(path)#\(Int(modifiedAt.timeIntervalSince1970 * 1000))"

        lock.lock()
        defer { lock.unlock() }

        if seen[signature] != nil {
            return false
        }

        seen[signature] = Date()
        pruneIfNeeded()
        return true
    }

    private func pruneIfNeeded() {
        guard seen.count > 1_000 else { return }
        let threshold = Date().addingTimeInterval(-24 * 60 * 60)
        seen = seen.filter { $0.value > threshold }
    }
}
