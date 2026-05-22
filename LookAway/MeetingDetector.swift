import AppKit

// NOTE: detects meeting app activity, not meeting in progress

protocol MeetingDetectorDelegate: AnyObject {
    func meetingStatusChanged(isActive: Bool)
}

final class MeetingDetector {

    // MARK: - Known Meeting App Bundle IDs

    private static let meetingBundleIDs: Set<String> = [
        "us.zoom.xos",
        "com.microsoft.teams",
        "com.apple.FaceTime",
        "com.webex.meetingmanager",
        "com.tinyspeck.slackmacgap"
    ]

    // MARK: - Properties

    weak var delegate: MeetingDetectorDelegate?

    private(set) var isMeetingAppActive: Bool = false {
        didSet {
            if oldValue != isMeetingAppActive {
                delegate?.meetingStatusChanged(isActive: isMeetingAppActive)
            }
        }
    }

    private var isObserving = false

    // MARK: - Init

    init() {
        pollRunningApps()
        startObserving()
    }

    deinit {
        stopObserving()
    }

    // MARK: - Public

    func refresh() {
        evaluateStatus()
    }

    // MARK: - Observation

    private func startObserving() {
        guard !isObserving else { return }
        isObserving = true

        let ws = NSWorkspace.shared
        ws.notificationCenter.addObserver(
            self,
            selector: #selector(appDidActivate(_:)),
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil
        )
        ws.notificationCenter.addObserver(
            self,
            selector: #selector(appDidLaunch(_:)),
            name: NSWorkspace.didLaunchApplicationNotification,
            object: nil
        )
        ws.notificationCenter.addObserver(
            self,
            selector: #selector(appDidTerminate(_:)),
            name: NSWorkspace.didTerminateApplicationNotification,
            object: nil
        )
    }

    private func stopObserving() {
        guard isObserving else { return }
        isObserving = false
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }

    // MARK: - Notification Handlers

    @objc private func appDidActivate(_ notification: Notification) {
        evaluateStatus()
    }

    @objc private func appDidLaunch(_ notification: Notification) {
        evaluateStatus()
    }

    @objc private func appDidTerminate(_ notification: Notification) {
        evaluateStatus()
    }

    // MARK: - Detection Logic

    private func pollRunningApps() {
        evaluateStatus()
    }

    private func evaluateStatus() {
        guard Settings.meetingDetectionEnabled else {
            isMeetingAppActive = false
            return
        }

        let frontmost = NSWorkspace.shared.frontmostApplication
        let frontmostBundleID = frontmost?.bundleIdentifier

        let isActive = frontmostBundleID.map { Self.meetingBundleIDs.contains($0) } ?? false
        isMeetingAppActive = isActive
    }
}
