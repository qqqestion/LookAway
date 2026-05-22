import Foundation

enum Settings {
    // MARK: - Notification
    static let didChangeNotification = Notification.Name("settingsDidChange")

    // MARK: - Keys
    private enum Keys {
        static let breakIntervalMinutes = "breakIntervalMinutes"
        static let breakDurationSeconds = "breakDurationSeconds"
        static let warningAdvanceSeconds = "warningAdvanceSeconds"
        static let idleTimeoutMinutes = "idleTimeoutMinutes"
        static let idleAction = "idleAction"
        static let focusModeEnabled = "focusModeEnabled"
        static let meetingDetectionEnabled = "meetingDetectionEnabled"
        static let inputDeferEnabled = "inputDeferEnabled"
        static let maxDeferMinutes = "maxDeferMinutes"
        static let longWorkThresholdMinutes = "longWorkThresholdMinutes"
        static let pausedApps = "pausedApps"
    }

    // MARK: - Register Defaults
    static func registerDefaults() {
        UserDefaults.standard.register(defaults: [
            Keys.breakIntervalMinutes: 20,
            Keys.breakDurationSeconds: 20,
            Keys.warningAdvanceSeconds: 10,
            Keys.idleTimeoutMinutes: 5,
            Keys.idleAction: "pause",
            Keys.focusModeEnabled: true,
            Keys.meetingDetectionEnabled: true,
            Keys.inputDeferEnabled: true,
            Keys.maxDeferMinutes: 2,
            Keys.longWorkThresholdMinutes: 120,
            Keys.pausedApps: [String]()
        ])
    }

    // MARK: - Timer Settings
    static var breakIntervalMinutes: Int {
        get { UserDefaults.standard.integer(forKey: Keys.breakIntervalMinutes) }
        set { UserDefaults.standard.set(newValue, forKey: Keys.breakIntervalMinutes); postChange() }
    }

    static var breakDurationSeconds: Int {
        get { UserDefaults.standard.integer(forKey: Keys.breakDurationSeconds) }
        set { UserDefaults.standard.set(newValue, forKey: Keys.breakDurationSeconds); postChange() }
    }

    static var warningAdvanceSeconds: Int {
        get { UserDefaults.standard.integer(forKey: Keys.warningAdvanceSeconds) }
        set { UserDefaults.standard.set(newValue, forKey: Keys.warningAdvanceSeconds); postChange() }
    }

    // MARK: - Idle Settings
    static var idleTimeoutMinutes: Int {
        get { UserDefaults.standard.integer(forKey: Keys.idleTimeoutMinutes) }
        set { UserDefaults.standard.set(newValue, forKey: Keys.idleTimeoutMinutes); postChange() }
    }

    static var idleAction: String {
        get { UserDefaults.standard.string(forKey: Keys.idleAction) ?? "pause" }
        set { UserDefaults.standard.set(newValue, forKey: Keys.idleAction); postChange() }
    }

    // MARK: - Detection Toggles
    static var focusModeEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: Keys.focusModeEnabled) }
        set { UserDefaults.standard.set(newValue, forKey: Keys.focusModeEnabled); postChange() }
    }

    static var meetingDetectionEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: Keys.meetingDetectionEnabled) }
        set { UserDefaults.standard.set(newValue, forKey: Keys.meetingDetectionEnabled); postChange() }
    }

    static var inputDeferEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: Keys.inputDeferEnabled) }
        set { UserDefaults.standard.set(newValue, forKey: Keys.inputDeferEnabled); postChange() }
    }

    static var maxDeferMinutes: Int {
        get { UserDefaults.standard.integer(forKey: Keys.maxDeferMinutes) }
        set { UserDefaults.standard.set(newValue, forKey: Keys.maxDeferMinutes); postChange() }
    }

    // MARK: - Long Work
    static var longWorkThresholdMinutes: Int {
        get { UserDefaults.standard.integer(forKey: Keys.longWorkThresholdMinutes) }
        set { UserDefaults.standard.set(newValue, forKey: Keys.longWorkThresholdMinutes); postChange() }
    }

    // MARK: - App Pause List
    static var pausedApps: [String] {
        get { UserDefaults.standard.stringArray(forKey: Keys.pausedApps) ?? [] }
        set { UserDefaults.standard.set(newValue, forKey: Keys.pausedApps); postChange() }
    }

    // MARK: - Private
    private static func postChange() {
        NotificationCenter.default.post(name: didChangeNotification, object: nil)
    }
}
