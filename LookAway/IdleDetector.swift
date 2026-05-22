import Foundation
import CoreGraphics

protocol IdleDetectorDelegate: AnyObject {
    func idleStatusChanged(isIdle: Bool)
}

final class IdleDetector {

    // MARK: - Properties

    private(set) var isIdle: Bool = false
    weak var delegate: IdleDetectorDelegate?

    // MARK: - Query

    var idleSeconds: TimeInterval {
        let anyEventType = CGEventType(rawValue: UInt32.max) ?? .null
        let anyEventIdle = CGEventSource.secondsSinceLastEventType(
            .combinedSessionState,
            eventType: anyEventType
        )
        let mouseIdle = CGEventSource.secondsSinceLastEventType(
            .combinedSessionState,
            eventType: .mouseMoved
        )
        return max(anyEventIdle, mouseIdle)
    }

    // MARK: - Update

    func update() {
        let threshold = TimeInterval(Settings.idleTimeoutMinutes) * 60.0
        let nowIdle = idleSeconds > threshold

        guard nowIdle != isIdle else { return }
        isIdle = nowIdle
        delegate?.idleStatusChanged(isIdle: isIdle)
    }
}
