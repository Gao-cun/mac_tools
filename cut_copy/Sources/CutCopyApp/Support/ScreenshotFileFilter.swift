import Foundation

struct ScreenshotFileFilter {
    private let allowedExtensions: Set<String> = ["png", "jpg", "jpeg", "heic", "tiff"]

    func isScreenshotFile(_ url: URL) -> Bool {
        guard !url.lastPathComponent.hasPrefix(".") else {
            return false
        }
        guard allowedExtensions.contains(url.pathExtension.lowercased()) else {
            return false
        }
        let values = try? url.resourceValues(forKeys: [.isRegularFileKey])
        return values?.isRegularFile ?? false
    }
}
