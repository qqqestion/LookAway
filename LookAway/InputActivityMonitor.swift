import AppKit

protocol InputActivityMonitorDelegate: AnyObject {
    func userActivityChanged(isActive: Bool)
}

final class InputActivityMonitor {

    // MARK: - Properties

    private(set) var lastActivityTime: Date = .distantPast
    weak var delegate: InputActivityMonitorDelegate?

    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var isCurrentlyActive: Bool = false

    private let eventMask: NSEvent.EventTypeMask = [.keyDown, .leftMouseDragged]

    /// True when user typed or dragged recently (within Settings.maxDeferMinutes).
    /// Always false when Settings.inputDeferEnabled is off.
    var isUserActive: Bool {
        guard Settings.inputDeferEnabled else { return false }
        let elapsed = Date.now.timeIntervalSince(lastActivityTime)
        return elapsed < TimeInterval(Settings.maxDeferMinutes) * 60.0
    }

    // MARK: - Lifecycle

    func start() {
        guard Settings.inputDeferEnabled else { return }
        stop()

        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: eventMask) { [weak self] _ in
            self?.handleEvent()
        }

        localMonitor = NSEvent.addLocalMonitorForEvents(matching: eventMask) { [weak self] event in
            self?.handleEvent()
            return event
        }
    }

    func stop() {
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
            globalMonitor = nil
        }
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
            localMonitor = nil
        }
        isCurrentlyActive = false
        lastActivityTime = .distantPast
    }

    // MARK: - Private

    private func handleEvent() {
        lastActivityTime = Date.now

        guard !isCurrentlyActive else { return }
        isCurrentlyActive = true
        delegate?.userActivityChanged(isActive: true)
    }

    /// Call periodically (e.g. from timer tick) to detect when activity expires.
    func refreshState() {
        guard isCurrentlyActive, !isUserActive else { return }
        isCurrentlyActive = false
        delegate?.userActivityChanged(isActive: false)
    }
}
