import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    // MARK: - Components

    let timerEngine = TimerEngine()
    let overlayManager = OverlayManager()
    let pauseCoordinator = PauseCoordinator()
    let meetingDetector = MeetingDetector()
    let idleDetector = IdleDetector()
    let appPauseDetector = AppPauseDetector()
    let focusModeDetector = FocusModeDetector()
    let inputMonitor = InputActivityMonitor()
    let longWorkMonitor = LongWorkMonitor()

    // MARK: - UI State

    let statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private var skipResumeWorkItem: DispatchWorkItem?
    private var isManuallySkipped = false
    private var warningFiredForCurrentCycle = false
    private var currentBreakScheduledTime: Date?

    // MARK: - Application Lifecycle

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        Settings.registerDefaults()
        NotificationManager.shared.setup()
        DockIcon.standard.setVisibility(false)

        meetingDetector.delegate = pauseCoordinator
        idleDetector.delegate = pauseCoordinator
        appPauseDetector.delegate = pauseCoordinator
        focusModeDetector.delegate = pauseCoordinator
        inputMonitor.delegate = pauseCoordinator

        pauseCoordinator.timerEngine = timerEngine
        pauseCoordinator.onMeetingDuringOverlay = { [weak self] in
            self?.handleMeetingDuringOverlay()
        }

        timerEngine.delegate = self
        overlayManager.delegate = self
        NotificationManager.shared.delegate = self

        timerEngine.start()
        inputMonitor.start()
        longWorkMonitor.startMonitoring()

        buildStatusBarMenu()
        updateStatusText(timerEngine.secondsUntilBreak)
    }

    // MARK: - Status Bar Menu

    private func buildStatusBarMenu() {
        let menu = NSMenu()

        let resetItem = NSMenuItem(
            title: "Reset Active Timer",
            action: #selector(resetTimer),
            keyEquivalent: ""
        )
        resetItem.target = self
        menu.addItem(resetItem)

        let skipItem = NSMenuItem(
            title: "Skip For",
            action: nil,
            keyEquivalent: ""
        )
        let skipSubmenu = NSMenu()
        for minutes in [10, 30, 60, 120] {
            let title = minutes >= 60 ? "\(minutes / 60) hour(s)" : "\(minutes) min(s)"
            let item = NSMenuItem(
                title: title,
                action: #selector(skipForDuration),
                keyEquivalent: ""
            )
            item.representedObject = minutes
            item.target = self
            skipSubmenu.addItem(item)
        }
        skipItem.submenu = skipSubmenu
        menu.addItem(skipItem)

        menu.addItem(.separator())

        let prefsItem = NSMenuItem(
            title: "Preferences\u{2026}",
            action: #selector(showPreferences),
            keyEquivalent: ","
        )
        prefsItem.target = self
        menu.addItem(prefsItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(
            title: "Quit",
            action: #selector(quitApp),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)

        statusBarItem.menu = menu
    }

    // MARK: - Menu Actions

    @objc private func resetTimer() {
        isManuallySkipped = false
        warningFiredForCurrentCycle = false
        skipResumeWorkItem?.cancel()
        skipResumeWorkItem = nil
        timerEngine.reset()
    }

    @objc private func skipForDuration(_ sender: NSMenuItem) {
        guard let minutes = sender.representedObject as? Int else { return }

        isManuallySkipped = true
        warningFiredForCurrentCycle = false
        skipResumeWorkItem?.cancel()
        timerEngine.pause()

        let item = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            self.isManuallySkipped = false
            self.timerEngine.resume()
            self.pauseCoordinator.reevaluate()
        }
        skipResumeWorkItem = item
        DispatchQueue.main.asyncAfter(
            deadline: .now() + TimeInterval(minutes * 60),
            execute: item
        )
    }

    @objc private func showPreferences(_ sender: Any?) {
        PreferencesWindowController.shared.showPreferences(sender)
    }

    @objc private func quitApp(_ sender: Any?) {
        NSApp.terminate(sender)
    }

    // MARK: - Helpers

    private func updateStatusText(_ secondsLeft: Int) {
        guard let button = statusBarItem.button else { return }
        let minutes = (secondsLeft + 59) / 60
        button.title = "👁️ \(minutes) min"
    }

    private func handleMeetingDuringOverlay() {
        overlayManager.closeOverlay()
        timerEngine.markBreakEnded()
        longWorkMonitor.resetWorkSession()
        warningFiredForCurrentCycle = false
    }

    private func handleSkip() {
        overlayManager.closeOverlay()
        BreakHistory.shared.recordBreak(
            scheduledTime: currentBreakScheduledTime ?? Date(),
            wasSkipped: true
        )
        timerEngine.markBreakEnded()
        longWorkMonitor.resetWorkSession()
        warningFiredForCurrentCycle = false
    }
}

// MARK: - TimerEngineDelegate

extension AppDelegate: TimerEngineDelegate {

    func timerDidTick(secondsLeft: Int) {
        if isManuallySkipped || pauseCoordinator.state != .running {
            statusBarItem.button?.title = "👁️ Paused"
        } else {
            updateStatusText(secondsLeft)
        }

        idleDetector.update()
        inputMonitor.refreshState()
    }

    func timerShouldWarn() {
        guard !warningFiredForCurrentCycle else { return }
        warningFiredForCurrentCycle = true
        NotificationManager.shared.scheduleWarning(
            secondsBefore: TimeInterval(Settings.warningAdvanceSeconds)
        )
    }

    func timerBreakDue() {
        currentBreakScheduledTime = Date()
        overlayManager.showOverlay()
        timerEngine.markBreakStarted()
    }

    func timerBreakEnd() {
        BreakHistory.shared.recordBreak(
            scheduledTime: currentBreakScheduledTime ?? Date(),
            wasSkipped: false
        )
        overlayManager.closeOverlay()
        timerEngine.markBreakEnded()
        longWorkMonitor.resetWorkSession()
        warningFiredForCurrentCycle = false
    }
}

// MARK: - OverlayManagerDelegate

extension AppDelegate: OverlayManagerDelegate {

    func onSkipRequested() {
        handleSkip()
    }
}

// MARK: - NotificationManagerDelegate

extension AppDelegate: NotificationManagerDelegate {

    func onSkipBreak() {
        handleSkip()
    }

    func onNotificationShown() {}
}
