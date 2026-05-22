import AppKit

protocol AppPauseDetectorDelegate: AnyObject {
    func pauseAppStatusChanged(shouldPause: Bool)
}

final class AppPauseDetector {

    // MARK: - Base Presets

    private static let basePauseBundleIDs: Set<String> = [
        "com.valvesoftware.steam",
        "org.videolan.vlc",
        "com.apple.iWork.Keynote",
        "com.microsoft.Powerpoint",
        "com.apple.QuickTimePlayer",
        "com.apple.tv",
        "com.spotify.client"
    ]

    // MARK: - Properties

    weak var delegate: AppPauseDetectorDelegate?

    private(set) var isPauseAppActive: Bool = false
    private var pauseBundleIDs: Set<String> = []

    private var isObserving = false

    // MARK: - Init

    init() {
        rebuildBundleIDs()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(settingsDidChange),
            name: Settings.didChangeNotification,
            object: nil
        )

        checkFrontmostApp()
        startObserving()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Bundle ID Management

    private func rebuildBundleIDs() {
        pauseBundleIDs = Self.basePauseBundleIDs.union(Settings.pausedApps)
    }

    // MARK: - Observation

    private func startObserving() {
        guard !isObserving else { return }
        isObserving = true

        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(frontmostAppChanged),
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil
        )
    }

    // MARK: - Detection

    private func checkFrontmostApp() {
        let bundleID = NSWorkspace.shared.frontmostApplication?.bundleIdentifier
        updatePauseState(bundleID: bundleID)
    }

    private func updatePauseState(bundleID: String?) {
        let shouldPause: Bool
        if let bundleID = bundleID {
            shouldPause = pauseBundleIDs.contains(bundleID)
        } else {
            shouldPause = false
        }

        if shouldPause != isPauseAppActive {
            isPauseAppActive = shouldPause
            delegate?.pauseAppStatusChanged(shouldPause: shouldPause)
        }
    }

    // MARK: - Notification Handlers

    @objc private func frontmostAppChanged(_ notification: Notification) {
        let bundleID = (notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication)?.bundleIdentifier
        updatePauseState(bundleID: bundleID)
    }

    @objc private func settingsDidChange(_ notification: Notification) {
        rebuildBundleIDs()
        checkFrontmostApp()
    }
}
