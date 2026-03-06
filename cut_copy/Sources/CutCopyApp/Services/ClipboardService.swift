import AppKit
import Foundation

enum ClipboardServiceError: LocalizedError {
    case imageLoadFailed(URL)
    case writeFailed

    var errorDescription: String? {
        switch self {
        case .imageLoadFailed(let url):
            return "无法读取截图文件：\(url.lastPathComponent)"
        case .writeFailed:
            return "写入系统剪贴板失败。"
        }
    }
}

final class ClipboardService {
    typealias ImageLoader = (URL) -> NSImage?
    typealias PasteboardWriter = (NSImage) -> Bool

    private let pasteboard: NSPasteboard
    private let processedStore: ProcessedScreenshotStore
    private let imageLoader: ImageLoader
    private let pasteboardWriter: PasteboardWriter

    init(
        pasteboard: NSPasteboard = .general,
        processedStore: ProcessedScreenshotStore = ProcessedScreenshotStore(),
        imageLoader: @escaping ImageLoader = { NSImage(contentsOf: $0) },
        pasteboardWriter: PasteboardWriter? = nil
    ) {
        self.pasteboard = pasteboard
        self.processedStore = processedStore
        self.imageLoader = imageLoader
        if let pasteboardWriter {
            self.pasteboardWriter = pasteboardWriter
        } else {
            self.pasteboardWriter = { image in
                pasteboard.writeObjects([image])
            }
        }
    }

    @discardableResult
    func copyImage(at fileURL: URL) throws -> Bool {
        let modifiedAt = modificationDate(of: fileURL)
        guard processedStore.markIfUnseen(path: fileURL.path, modifiedAt: modifiedAt) else {
            return false
        }

        guard let image = imageLoader(fileURL) else {
            throw ClipboardServiceError.imageLoadFailed(fileURL)
        }

        pasteboard.clearContents()
        guard pasteboardWriter(image) else {
            throw ClipboardServiceError.writeFailed
        }
        return true
    }

    private func modificationDate(of url: URL) -> Date {
        guard let values = try? url.resourceValues(forKeys: [.contentModificationDateKey]),
              let date = values.contentModificationDate else {
            return Date()
        }
        return date
    }
}
