import Foundation
import UserNotifications

// MARK: - Delegate Protocol

protocol NotificationManagerDelegate: AnyObject {
    func onSkipBreak()
    func onNotificationShown()
}

// MARK: - NotificationManager

final class NotificationManager: NSObject {

    static let shared = NotificationManager()

    weak var delegate: NotificationManagerDelegate?

    private let warningIdentifier = "lookaway-warning"
    private let categoryIdentifier = "BREAK_WARNING"
    private let skipActionIdentifier = "SKIP_ACTION"

    // MARK: - Setup

    private override init() {
        super.init()
    }

    func setup() {
        let center = UNUserNotificationCenter.current()

        center.requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("Notification authorization error: \(error)")
            }
        }

        let skipAction = UNNotificationAction(
            identifier: self.skipActionIdentifier,
            title: "Skip Break",
            options: []
        )

        let category = UNNotificationCategory(
            identifier: self.categoryIdentifier,
            actions: [skipAction],
            intentIdentifiers: [],
            options: []
        )

        center.setNotificationCategories([category])
        center.delegate = self
    }

    // MARK: - Scheduling

    func scheduleWarning(secondsBefore: TimeInterval) {
        let content = UNMutableNotificationContent()
        content.title = "Look Away"
        content.body = "Break in \(Int(secondsBefore)) seconds"
        content.categoryIdentifier = categoryIdentifier
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: secondsBefore,
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: warningIdentifier,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule warning notification: \(error)")
            }
        }
    }

    func cancelPendingNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationManager: UNUserNotificationCenterDelegate {

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
        delegate?.onNotificationShown()
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        if response.actionIdentifier == skipActionIdentifier {
            delegate?.onSkipBreak()
        }
        completionHandler()
    }
}
