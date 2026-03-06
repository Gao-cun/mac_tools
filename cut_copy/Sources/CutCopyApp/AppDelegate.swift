import AppKit
import Foundation

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let settings = AppSettings()
    private let locationService = ScreenshotLocationService()
    private let watcher = ScreenshotWatcher()
    private let clipboardService = ClipboardService()
    private let cleanupService = CleanupService()
    private let launchAtLoginService = LaunchAtLoginService()

    private var statusItem: NSStatusItem?
    private var autoCopyMenuItem: NSMenuItem?
    private var launchAtLoginMenuItem: NSMenuItem?
    private var screenshotDirectory: URL?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        configureScreenshotLocation()
        configureLaunchAtLogin()
        configureStatusMenu()
        refreshWatcherState()
    }

    func applicationWillTerminate(_ notification: Notification) {
        watcher.stopWatching()
    }

    @objc
    private func toggleAutoCopy(_ sender: NSMenuItem) {
        settings.autoCopyEnabled.toggle()
        updateMenuState()
        refreshWatcherState()
    }

    @objc
    private func toggleLaunchAtLogin(_ sender: NSMenuItem) {
        let targetEnabled = !settings.launchAtLoginEnabled
        let result = launchAtLoginService.setEnabled(targetEnabled)
        switch result {
        case .success:
            settings.launchAtLoginEnabled = targetEnabled
            updateMenuState()
        case .failure(let error):
            showAlert(
                title: "无法更新开机启动",
                message: error.localizedDescription
            )
        }
    }

    @objc
    private func openScreenshotFolder(_ sender: NSMenuItem) {
        guard let directory = screenshotDirectory else { return }
        NSWorkspace.shared.open(directory)
    }

    @objc
    private func refreshScreenshotFolder(_ sender: NSMenuItem) {
        screenshotDirectory = locationService.currentConfiguredDirectory() ?? locationService.defaultDirectory()
        refreshWatcherState()
    }

    @objc
    private func clearScreenshots(_ sender: NSMenuItem) {
        guard let directory = screenshotDirectory else { return }

        let confirm = NSAlert()
        confirm.messageText = "一键清除截图"
        confirm.informativeText = "将把 \(directory.lastPathComponent) 中的截图移到废纸篓，可在废纸篓恢复。"
        confirm.alertStyle = .warning
        confirm.addButton(withTitle: "清除")
        confirm.addButton(withTitle: "取消")

        guard confirm.runModal() == .alertFirstButtonReturn else {
            return
        }

        let result = cleanupService.clearScreenshots(in: directory)
        let message = "已处理 \(result.totalCount) 个文件，成功 \(result.successCount) 个，失败 \(result.failureCount) 个。"
        showAlert(title: "清理完成", message: message)
    }

    @objc
    private func quitApp(_ sender: NSMenuItem) {
        NSApplication.shared.terminate(nil)
    }

    private func configureScreenshotLocation() {
        do {
            if !settings.didConfigureLocation {
                let defaultDirectory = try locationService.ensureDefaultDirectoryExists()
                try locationService.configureSystemLocation(to: defaultDirectory)
                settings.didConfigureLocation = true
            } else {
                _ = try locationService.ensureDefaultDirectoryExists()
            }

            screenshotDirectory = locationService.currentConfiguredDirectory() ?? locationService.defaultDirectory()
        } catch {
            screenshotDirectory = locationService.currentConfiguredDirectory() ?? locationService.defaultDirectory()
            showAlert(
                title: "截图目录设置失败",
                message: error.localizedDescription
            )
        }
    }

    private func configureLaunchAtLogin() {
        let result = launchAtLoginService.setEnabled(settings.launchAtLoginEnabled)
        if case .failure(let error) = result {
            showAlert(
                title: "开机启动初始化失败",
                message: error.localizedDescription
            )
        }
    }

    private func configureStatusMenu() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.title = "CutCopy"
        item.button?.toolTip = "截图自动复制工具"

        let menu = NSMenu()

        let autoCopy = NSMenuItem(
            title: "自动复制",
            action: #selector(toggleAutoCopy(_:)),
            keyEquivalent: ""
        )
        autoCopy.target = self
        menu.addItem(autoCopy)
        self.autoCopyMenuItem = autoCopy

        menu.addItem(.separator())

        let clearItem = NSMenuItem(
            title: "一键清除截图",
            action: #selector(clearScreenshots(_:)),
            keyEquivalent: ""
        )
        clearItem.target = self
        menu.addItem(clearItem)

        let openFolder = NSMenuItem(
            title: "打开截图文件夹",
            action: #selector(openScreenshotFolder(_:)),
            keyEquivalent: ""
        )
        openFolder.target = self
        menu.addItem(openFolder)

        let refreshFolder = NSMenuItem(
            title: "刷新截图目录",
            action: #selector(refreshScreenshotFolder(_:)),
            keyEquivalent: ""
        )
        refreshFolder.target = self
        menu.addItem(refreshFolder)

        menu.addItem(.separator())

        let launchItem = NSMenuItem(
            title: "开机启动",
            action: #selector(toggleLaunchAtLogin(_:)),
            keyEquivalent: ""
        )
        launchItem.target = self
        menu.addItem(launchItem)
        self.launchAtLoginMenuItem = launchItem

        menu.addItem(.separator())

        let quitItem = NSMenuItem(
            title: "退出",
            action: #selector(quitApp(_:)),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)

        item.menu = menu
        statusItem = item
        updateMenuState()
    }

    private func updateMenuState() {
        autoCopyMenuItem?.state = settings.autoCopyEnabled ? .on : .off
        launchAtLoginMenuItem?.state = settings.launchAtLoginEnabled ? .on : .off
    }

    private func refreshWatcherState() {
        guard settings.autoCopyEnabled else {
            watcher.stopWatching()
            return
        }

        guard let directory = screenshotDirectory else { return }
        watcher.startWatching(directory: directory) { [weak self] fileURL in
            Task { @MainActor [weak self] in
                self?.handleNewScreenshot(fileURL)
            }
        }
    }

    private func handleNewScreenshot(_ fileURL: URL) {
        do {
            _ = try clipboardService.copyImage(at: fileURL)
        } catch {
            showAlert(
                title: "复制到剪贴板失败",
                message: error.localizedDescription
            )
        }
    }

    private func showAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .informational
        alert.runModal()
    }
}
