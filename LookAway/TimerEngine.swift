import Foundation

protocol TimerEngineDelegate: AnyObject {
    func timerDidTick(secondsLeft: Int)
    func timerShouldWarn()
    func timerBreakDue()
    func timerBreakEnd()
}

final class TimerEngine {
    weak var delegate: TimerEngineDelegate?

    private var timer: Timer?
    private var breakStartDate: Date = Date()
    private var overlayShownAt: Date?
    private var isPaused = false
    private var pausedRemainingSeconds: Int?

    // MARK: - Computed (Date-based, no tick-counting)

    var secondsUntilBreak: Int {
        if isPaused { return pausedRemainingSeconds ?? 0 }
        let targetDate = breakStartDate.addingTimeInterval(
            TimeInterval(Settings.breakIntervalMinutes * 60)
        )
        return max(0, Int(targetDate.timeIntervalSinceNow))
    }

    var secondsUntilClose: Int {
        guard let shownAt = overlayShownAt else { return 0 }
        let targetDate = shownAt.addingTimeInterval(
            TimeInterval(Settings.breakDurationSeconds)
        )
        return max(0, Int(targetDate.timeIntervalSinceNow))
    }

    var shouldWarn: Bool {
        return secondsUntilBreak > 0 && secondsUntilBreak <= Settings.warningAdvanceSeconds
    }

    var isOnBreak: Bool {
        return overlayShownAt != nil
    }

    // MARK: - Lifecycle

    func start() {
        breakStartDate = Date()
        overlayShownAt = nil
        isPaused = false
        pausedRemainingSeconds = nil
        scheduleTimer()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(settingsChanged),
            name: Settings.didChangeNotification,
            object: nil
        )
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        NotificationCenter.default.removeObserver(
            self,
            name: Settings.didChangeNotification,
            object: nil
        )
    }

    func reset() {
        breakStartDate = Date()
        overlayShownAt = nil
        isPaused = false
        pausedRemainingSeconds = nil
        delegate?.timerDidTick(secondsLeft: secondsUntilBreak)
    }

    // MARK: - Pause / Resume

    func pause() {
        guard !isPaused else { return }
        isPaused = true
        pausedRemainingSeconds = secondsUntilBreak
        delegate?.timerDidTick(secondsLeft: pausedRemainingSeconds ?? 0)
    }

    func resume() {
        guard isPaused else { return }
        isPaused = false
        // Adjust breakStartDate so that remaining time equals pausedRemainingSeconds
        let interval = TimeInterval(Settings.breakIntervalMinutes * 60 - (pausedRemainingSeconds ?? 0))
        breakStartDate = Date().addingTimeInterval(-interval)
        pausedRemainingSeconds = nil
        delegate?.timerDidTick(secondsLeft: secondsUntilBreak)
    }

    // MARK: - Break state

    func markBreakStarted() {
        overlayShownAt = Date()
    }

    func markBreakEnded() {
        overlayShownAt = nil
        breakStartDate = Date()
        isPaused = false
        pausedRemainingSeconds = nil
    }

    // MARK: - Private

    private func scheduleTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(
            timeInterval: 1.0,
            target: self,
            selector: #selector(timerTick),
            userInfo: nil,
            repeats: true
        )
    }

    @objc private func timerTick() {
        if isOnBreak {
            let remaining = secondsUntilClose
            if remaining <= 0 {
                delegate?.timerBreakEnd()
            }
        } else if isPaused {
            if let remaining = pausedRemainingSeconds {
                pausedRemainingSeconds = remaining - 1
                delegate?.timerDidTick(secondsLeft: max(0, remaining - 1))
            }
        } else {
            let remaining = secondsUntilBreak
            delegate?.timerDidTick(secondsLeft: remaining)

            if remaining <= 0 {
                delegate?.timerBreakDue()
            } else if shouldWarn {
                delegate?.timerShouldWarn()
            }
        }
    }

    @objc private func settingsChanged() {
        delegate?.timerDidTick(secondsLeft: secondsUntilBreak)
    }

    deinit {
        stop()
    }
}
