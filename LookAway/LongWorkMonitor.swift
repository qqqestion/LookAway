import Foundation
import UserNotifications

final class LongWorkMonitor: NSObject {

    // MARK: - Properties

    private var workStartDate: Date = Date()
    private var hasNotified = false
    private var checkTimer: Timer?

    private static let notificationIdentifier = "lookaway-long-work"
    private static let checkInterval: TimeInterval = 60.0

    // MARK: - Public

    func startMonitoring() {
        workStartDate = Date()
        hasNotified = false
        scheduleCheckTimer()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(settingsChanged),
            name: Settings.didChangeNotification,
            object: nil
        )
    }

    func stopMonitoring() {
        checkTimer?.invalidate()
        checkTimer = nil
        NotificationCenter.default.removeObserver(
            self,
            name: Settings.didChangeNotification,
            object: nil
        )
    }

    func resetWorkSession() {
        workStartDate = Date()
        hasNotified = false
    }

    func checkThreshold() {
        guard !hasNotified else { return }

        let elapsedMinutes = Int(Date().timeIntervalSince(workStartDate) / 60)
        let threshold = Settings.longWorkThresholdMinutes

        if elapsedMinutes >= threshold {
            sendLongWorkNotification(minutesWorked: elapsedMinutes)
            hasNotified = true
        }
    }

    // MARK: - Private

    private func scheduleCheckTimer() {
        checkTimer?.invalidate()
        checkTimer = Timer.scheduledTimer(
            timeInterval: Self.checkInterval,
            target: self,
            selector: #selector(timerCheckTick),
            userInfo: nil,
            repeats: true
        )
    }

    @objc private func timerCheckTick() {
        checkThreshold()
    }

    @objc private func settingsChanged() {
        hasNotified = false
        checkThreshold()
    }

    private func sendLongWorkNotification(minutesWorked minutes: Int) {
        let hours = minutes / 60
        let mins = minutes % 60

        let timeDescription: String
        if hours > 0 && mins > 0 {
            timeDescription = "\(hours) hour\(hours == 1 ? "" : "s") \(mins) minute\(mins == 1 ? "" : "s")"
        } else if hours > 0 {
            timeDescription = "\(hours) hour\(hours == 1 ? "" : "s")"
        } else {
            timeDescription = "\(mins) minute\(mins == 1 ? "" : "s")"
        }

        let content = UNMutableNotificationContent()
        content.title = "Long Work Session"
        content.body = "You've been working for \(timeDescription). Consider taking a break."
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: Self.notificationIdentifier,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }

    deinit {
        stopMonitoring()
    }
}
