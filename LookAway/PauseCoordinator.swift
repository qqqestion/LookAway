import Foundation

// Central coordinator that OR-combines all detection engines.
// Any detector saying "pause" causes the timer to pause.
// Input activity causes a soft "deferred" state with a timeout.

final class PauseCoordinator: NSObject,
    MeetingDetectorDelegate,
    IdleDetectorDelegate,
    AppPauseDetectorDelegate,
    FocusModeDetectorDelegate,
    InputActivityMonitorDelegate {

    // MARK: - State Machine

    enum TimerState {
        case running
        case paused
        case deferred   // input activity — soft pause with timeout
    }

    // MARK: - Dependencies

    weak var timerEngine: TimerEngine?

    /// Called when a meeting starts while the break overlay is visible.
    /// AppDelegate should close the overlay and reset the timer.
    var onMeetingDuringOverlay: (() -> Void)?

    // MARK: - State

    private(set) var state: TimerState = .running
    private var deferStartDate: Date?

    // MARK: - Detector Flags

    private var isMeetingActive = false
    private var isFocusModeActive = false
    private var isPauseAppActive = false
    private var isUserIdle = false
    private var isUserInputActive = false

    // MARK: - Init

    override init() {
        super.init()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(settingsDidChange),
            name: Settings.didChangeNotification,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Public

    func reevaluate() {
        evaluateState()
    }

    // MARK: - State Evaluation

    private func evaluateState() {
        // Priority 1-3: Hard pause (meeting, focus mode, pause app)
        if isMeetingActive || isFocusModeActive || isPauseAppActive {
            deferStartDate = nil
            transitionTo(.paused)
            return
        }

        // Priority 4: User idle
        if isUserIdle {
            deferStartDate = nil
            if Settings.idleAction == "reset" {
                timerEngine?.reset()
                transitionTo(.running)
            } else {
                transitionTo(.paused)
            }
            return
        }

        // Priority 5: User input activity → defer (soft pause with timeout)
        if isUserInputActive && Settings.inputDeferEnabled {
            if deferStartDate == nil {
                deferStartDate = Date()
            }

            if let start = deferStartDate {
                let elapsed = Date.now.timeIntervalSince(start)
                let maxDefer = TimeInterval(Settings.maxDeferMinutes) * 60.0
                if elapsed >= maxDefer {
                    deferStartDate = nil
                    transitionTo(.running)
                    return
                }
            }

            transitionTo(.deferred)
            return
        }

        // No pause conditions — running
        deferStartDate = nil
        transitionTo(.running)
    }

    private func transitionTo(_ newState: TimerState) {
        state = newState

        switch newState {
        case .running:
            timerEngine?.resume()
        case .paused:
            timerEngine?.pause()
        case .deferred:
            timerEngine?.pause()
        }
    }

    // MARK: - MeetingDetectorDelegate

    func meetingStatusChanged(isActive: Bool) {
        let wasMeeting = isMeetingActive
        isMeetingActive = isActive

        // Meeting-during-overlay: meeting started while overlay is visible
        if isActive && !wasMeeting {
            onMeetingDuringOverlay?()
        }

        evaluateState()
    }

    // MARK: - IdleDetectorDelegate

    func idleStatusChanged(isIdle: Bool) {
        isUserIdle = isIdle
        evaluateState()
    }

    // MARK: - AppPauseDetectorDelegate

    func pauseAppStatusChanged(shouldPause: Bool) {
        isPauseAppActive = shouldPause
        evaluateState()
    }

    // MARK: - FocusModeDetectorDelegate

    func focusModeChanged(isActive: Bool) {
        isFocusModeActive = isActive
        evaluateState()
    }

    // MARK: - InputActivityMonitorDelegate

    func userActivityChanged(isActive: Bool) {
        isUserInputActive = isActive
        evaluateState()
    }

    // MARK: - Settings

    @objc private func settingsDidChange() {
        evaluateState()
    }
}
