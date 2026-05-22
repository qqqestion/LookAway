import Foundation
import Intents

protocol FocusModeDetectorDelegate: AnyObject {
    func focusModeChanged(isActive: Bool)
}

final class FocusModeDetector: NSObject {

    weak var delegate: FocusModeDetectorDelegate?

    var isFocusModeActive: Bool {
        guard Settings.focusModeEnabled else { return false }
        return currentFocusState
    }

    private var currentFocusState = false
    private var isAuthorized = false
    private var pollTimer: Timer?

    override init() {
        super.init()
        requestAuthorization()
    }

    deinit {
        pollTimer?.invalidate()
    }

    // MARK: - Authorization

    private func requestAuthorization() {
        guard #available(macOS 12.0, *) else { return }
        INFocusStatusCenter.default.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isAuthorized = (status == .authorized)
                if self.isAuthorized {
                    self.startPolling()
                }
                self.refreshState()
            }
        }
    }

    // MARK: - Polling

    private func startPolling() {
        guard pollTimer == nil else { return }
        pollTimer = Timer.scheduledTimer(
            timeInterval: 5.0,
            target: self,
            selector: #selector(pollTick),
            userInfo: nil,
            repeats: true
        )
    }

    @objc private func pollTick() {
        refreshState()
    }

    // MARK: - State

    private func refreshState() {
        guard isAuthorized, #available(macOS 12.0, *) else {
            if currentFocusState != false {
                currentFocusState = false
                delegate?.focusModeChanged(isActive: false)
            }
            return
        }

        let newState = INFocusStatusCenter.default.focusStatus.isFocused ?? false

        guard newState != currentFocusState else { return }
        currentFocusState = newState
        delegate?.focusModeChanged(isActive: isFocusModeActive)
    }
}
